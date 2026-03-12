#!/bin/bash
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "$ROOT"

required_files=(
  "backend/app/services/recommendation_service.py"
  "backend/app/schemas/recommendation.py"
  "frontend/src/pages/RecommendationsPage.tsx"
  "frontend/src/components/dining/RecommendationCard.tsx"
  "frontend/src/types.ts"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "missing required file: $file"
    echo "run this from the project root, or pass the project root as the first argument"
    exit 1
  fi
done

timestamp="$(date +%Y%m%d_%H%M%S)"
backup_dir="phase45_backups_${timestamp}"
mkdir -p "$backup_dir/backend/app/services" \
         "$backup_dir/backend/app/schemas" \
         "$backup_dir/frontend/src/pages" \
         "$backup_dir/frontend/src/components/dining" \
         "$backup_dir/frontend/src"

cp backend/app/services/recommendation_service.py "$backup_dir/backend/app/services/"
cp backend/app/schemas/recommendation.py "$backup_dir/backend/app/schemas/"
cp frontend/src/pages/RecommendationsPage.tsx "$backup_dir/frontend/src/pages/"
cp frontend/src/components/dining/RecommendationCard.tsx "$backup_dir/frontend/src/components/dining/"
cp frontend/src/types.ts "$backup_dir/frontend/src/"

cat > backend/app/schemas/recommendation.py <<'PY'
from typing import Optional

from pydantic import BaseModel, Field


class BuildYourNightRequest(BaseModel):
    outing_type: str = Field(min_length=1, max_length=100)
    mood: Optional[str] = None
    budget: Optional[str] = None
    pace: Optional[str] = None
    social_context: Optional[str] = None
    preferred_cuisines: list[str] = Field(default_factory=list)
    drinks_focus: bool = False
    atmosphere: list[str] = Field(default_factory=list)


class DescribeYourNightRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=1000)


class SurpriseMeRequest(BaseModel):
    include_drinks: bool = False


class ScoreBreakdownItem(BaseModel):
    label: str
    points: float


class RecommendationRequestSummary(BaseModel):
    outing_type: Optional[str] = None
    budget: Optional[str] = None
    pace: Optional[str] = None
    social_context: Optional[str] = None
    preferred_cuisines: list[str] = Field(default_factory=list)
    drinks_focus: bool = False
    atmosphere: list[str] = Field(default_factory=list)


class RecommendationItem(BaseModel):
    restaurant_id: int
    restaurant_name: str
    score: float
    rank: int = 0
    fit_label: str = "explore"
    reasons: list[str]
    explanation: Optional[str] = None
    confidence_level: str = "exploratory"
    matched_signals: list[str] = Field(default_factory=list)
    penalized_signals: list[str] = Field(default_factory=list)
    score_breakdown: list[ScoreBreakdownItem] = Field(default_factory=list)
    suggested_dishes: list[str] = Field(default_factory=list)
    suggested_drinks: list[str] = Field(default_factory=list)


class RecommendationResponse(BaseModel):
    mode: str
    engine_version: str = "phase45"
    generated_at: str
    request_summary: RecommendationRequestSummary
    results: list[RecommendationItem]
PY

cat > backend/app/services/recommendation_service.py <<'PY'
from datetime import datetime, timezone
from typing import Optional

from app.models.restaurant import MenuItem, Restaurant
from app.models.user import User
from app.repositories.experience_repository import ExperienceRepository
from app.repositories.restaurant_repository import RestaurantRepository
from app.schemas.recommendation import (
    BuildYourNightRequest,
    DescribeYourNightRequest,
    RecommendationItem,
    RecommendationRequestSummary,
    RecommendationResponse,
    ScoreBreakdownItem,
    SurpriseMeRequest,
)


class RecommendationService:
    ENGINE_VERSION = "phase45"

    def __init__(self, db):
        self.restaurant_repository = RestaurantRepository(db)
        self.experience_repository = ExperienceRepository(db)

    def build_your_night(self, user: User, payload: BuildYourNightRequest) -> RecommendationResponse:
        restaurants = self.restaurant_repository.list_restaurants_with_details()
        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="build",
            outing_type=payload.outing_type,
            mood=payload.mood,
            budget=payload.budget,
            pace=payload.pace,
            social_context=payload.social_context,
            preferred_cuisines=payload.preferred_cuisines,
            drinks_focus=payload.drinks_focus,
            atmosphere=payload.atmosphere,
        )
        return RecommendationResponse(
            mode="build-your-night",
            engine_version=self.ENGINE_VERSION,
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type=payload.outing_type,
                budget=payload.budget,
                pace=payload.pace,
                social_context=payload.social_context,
                preferred_cuisines=payload.preferred_cuisines,
                drinks_focus=payload.drinks_focus,
                atmosphere=payload.atmosphere,
            ),
            results=ranked,
        )

    def describe_your_night(self, user: User, payload: DescribeYourNightRequest) -> RecommendationResponse:
        parsed = self._parse_prompt(payload.prompt)
        restaurants = self.restaurant_repository.list_restaurants_with_details()
        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="describe",
            outing_type=parsed["outing_type"],
            mood=parsed["mood"],
            budget=parsed["budget"],
            pace=parsed["pace"],
            social_context=parsed["social_context"],
            preferred_cuisines=parsed["preferred_cuisines"],
            drinks_focus=parsed["drinks_focus"],
            atmosphere=parsed["atmosphere"],
        )
        return RecommendationResponse(
            mode="describe-your-night",
            engine_version=self.ENGINE_VERSION,
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type=parsed["outing_type"],
                budget=parsed["budget"],
                pace=parsed["pace"],
                social_context=parsed["social_context"],
                preferred_cuisines=parsed["preferred_cuisines"],
                drinks_focus=parsed["drinks_focus"],
                atmosphere=parsed["atmosphere"],
            ),
            results=ranked,
        )

    def surprise_me(self, user: User, payload: SurpriseMeRequest) -> RecommendationResponse:
        restaurants = self.restaurant_repository.list_restaurants_with_details()
        preference = user.preference

        preferred_atmosphere = preference.atmosphere_preferences if preference else []
        preferred_cuisines = preference.cuisine_preferences if preference else []
        preferred_social = preference.social_preferences if preference else []

        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="surprise",
            outing_type="surprise",
            mood=None,
            budget=preference.price_sensitivity if preference else None,
            pace=None,
            social_context=preferred_social[0] if preferred_social else None,
            preferred_cuisines=preferred_cuisines,
            drinks_focus=payload.include_drinks,
            atmosphere=preferred_atmosphere,
        )
        return RecommendationResponse(
            mode="surprise-me",
            engine_version=self.ENGINE_VERSION,
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type="surprise",
                budget=preference.price_sensitivity if preference else None,
                pace=None,
                social_context=preferred_social[0] if preferred_social else None,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=payload.include_drinks,
                atmosphere=preferred_atmosphere,
            ),
            results=ranked,
        )

    def _timestamp(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def _build_request_summary(
        self,
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
    ) -> RecommendationRequestSummary:
        return RecommendationRequestSummary(
            outing_type=outing_type,
            budget=budget,
            pace=pace,
            social_context=social_context,
            preferred_cuisines=preferred_cuisines,
            drinks_focus=drinks_focus,
            atmosphere=atmosphere,
        )

    def _parse_prompt(self, prompt: str) -> dict:
        text = self._normalize_text(prompt)

        budget = None
        if any(word in text for word in ["cheap", "budget", "affordable", "inexpensive"]):
            budget = "$"
        elif any(word in text for word in ["fancy", "upscale", "premium", "special occasion"]):
            budget = "$$$"
        elif any(word in text for word in ["mid-range", "moderate", "balanced"]):
            budget = "$$"

        pace = None
        if any(word in text for word in ["quick", "fast", "late night", "bite"]):
            pace = "fast"
        elif any(word in text for word in ["slow", "relaxed"]):
            pace = "slow"
        elif any(word in text for word in ["leisurely", "romantic", "drawn out"]):
            pace = "leisurely"
        elif "moderate" in text:
            pace = "moderate"

        social_context = None
        if any(word in text for word in ["friends", "crew"]):
            social_context = "friends"
        elif any(word in text for word in ["group", "crowd", "party"]):
            social_context = "group"
        elif any(word in text for word in ["solo", "alone"]):
            social_context = "solo"
        elif any(word in text for word in ["date", "romantic"]):
            social_context = "date"

        outing_type = "natural-language"
        if any(word in text for word in ["date", "romantic"]):
            outing_type = "date-night"
        elif any(word in text for word in ["drinks", "cocktails", "bar", "brewery", "wine", "cider"]):
            outing_type = "drinks-night"
        elif any(word in text for word in ["coffee", "cafe", "espresso", "study"]):
            outing_type = "coffee-stop"
        elif any(word in text for word in ["quick", "fast", "grab and go"]):
            outing_type = "quick-bite"
        elif any(word in text for word in ["special occasion", "anniversary", "celebrate"]):
            outing_type = "special-occasion"
        elif any(word in text for word in ["group dinner", "large table", "shared plates"]):
            outing_type = "group-dinner"
        elif any(word in text for word in ["casual", "easy", "simple bite"]):
            outing_type = "casual-bite"

        atmosphere = []
        for word in ["cozy", "lively", "quiet", "casual", "scenic", "historic", "refined", "upscale", "rustic"]:
            if word in text:
                atmosphere.append(word)

        preferred_cuisines = []
        for word in [
            "pizza",
            "mediterranean",
            "asian",
            "bakery",
            "dessert",
            "seasonal",
            "turkish",
            "coffee",
            "beer",
            "wine",
            "cider",
            "pasta",
            "cocktail",
            "cocktails",
        ]:
            if word in text:
                preferred_cuisines.append(word)

        drinks_focus = any(
            word in text
            for word in ["drink", "drinks", "cocktail", "cocktails", "bar", "beer", "wine", "cider"]
        )

        return {
            "outing_type": outing_type,
            "mood": None,
            "budget": budget,
            "pace": pace,
            "social_context": social_context,
            "preferred_cuisines": preferred_cuisines,
            "drinks_focus": drinks_focus,
            "atmosphere": atmosphere,
        }

    def _normalize_text(self, value: Optional[str]) -> str:
        return (value or "").strip().lower()

    def _text_blob(self, *parts: Optional[str]) -> str:
        return " ".join(self._normalize_text(part) for part in parts if part).strip()

    def _has_tag(self, tag_names: list[str], candidate: str) -> bool:
        target = self._normalize_text(candidate)
        return any(target == tag or target in tag for tag in tag_names)

    def _append_reason(self, reasons: list[str], message: str) -> None:
        if message not in reasons:
            reasons.append(message)

    def _append_signal(self, signals: list[str], message: str) -> None:
        if message not in signals:
            signals.append(message)

    def _add_breakdown(self, breakdown: dict[str, float], label: str, points: float) -> None:
        breakdown[label] = round(breakdown.get(label, 0.0) + points, 2)

    def _fit_label(self, score: float, confidence_level: str) -> str:
        if confidence_level == "high" and score >= 11:
            return "excellent fit"
        if confidence_level in {"high", "medium"} and score >= 7:
            return "strong fit"
        if score >= 4:
            return "possible fit"
        return "explore"

    def _apply_outing_type_score(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int]:
        if not outing_type:
            return 0.0, 0

        score = 0.0
        strong_matches = 0
        value = self._normalize_text(outing_type)
        atmosphere_text = self._normalize_text(restaurant.atmosphere)
        social_style = self._normalize_text(restaurant.social_style)
        pace = self._normalize_text(restaurant.pace)

        if value == "date-night":
            if social_style == "date":
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Strong date-night fit with a date-oriented dining style")
                self._append_signal(matched_signals, "date-night fit")
            if self._has_tag(restaurant_tag_names, "date-night") or self._has_tag(restaurant_tag_names, "special-occasion"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Tagged for date-night or special-occasion dining")
                self._append_signal(matched_signals, "occasion tag alignment")
            for term in ["quiet", "cozy", "scenic", "refined", "upscale", "historic"]:
                if term in atmosphere_text:
                    score += 0.7

        elif value == "group-dinner":
            if social_style == "group":
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for group dining")
                self._append_signal(matched_signals, "group dining fit")
            if self._has_tag(restaurant_tag_names, "group-friendly") or self._has_tag(restaurant_tag_names, "shared-plates"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Supports shared or group-friendly dining")
                self._append_signal(matched_signals, "shared/group-friendly support")

        elif value == "drinks-night":
            if restaurant.serves_alcohol:
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a drinks-forward night out")
                self._append_signal(matched_signals, "alcohol service")
            for term in ["beer", "wine", "cider", "brewery", "pub", "brewpub", "winery", "cidery", "night-out"]:
                if self._has_tag(restaurant_tag_names, term):
                    score += 0.8

        elif value == "quick-bite":
            if pace == "fast":
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a fast quick-bite outing")
                self._append_signal(matched_signals, "fast pace")
            if self._has_tag(restaurant_tag_names, "quick-bite") or self._has_tag(restaurant_tag_names, "takeout"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Supports quick and convenient dining")
                self._append_signal(matched_signals, "quick-bite support")
            if restaurant.price_tier == "$":
                score += 1.0

        elif value == "coffee-stop":
            coffee_hits = 0
            for term in ["coffee", "coffeehouse", "specialty-coffee", "cafe", "espresso", "study-friendly"]:
                if self._has_tag(restaurant_tag_names, term):
                    score += 1.1
                    coffee_hits += 1
            if "quiet" in atmosphere_text:
                score += 0.8
            if coffee_hits > 0:
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a coffee-stop outing")
                self._append_signal(matched_signals, "coffee-stop alignment")

        elif value == "special-occasion":
            if restaurant.price_tier == "$$$":
                score += 2.5
                strong_matches += 1
                self._append_reason(reasons, "Fits a special-occasion price tier")
                self._append_signal(matched_signals, "premium price tier")
            if self._has_tag(restaurant_tag_names, "special-occasion"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Tagged for special occasions")
                self._append_signal(matched_signals, "special-occasion tag")
            for term in ["refined", "scenic", "historic", "upscale"]:
                if term in atmosphere_text:
                    score += 0.9

        elif value == "casual-bite":
            if "casual" in atmosphere_text:
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a casual-bite atmosphere")
                self._append_signal(matched_signals, "casual atmosphere")
            if pace in {"fast", "moderate"}:
                score += 1.5
            if restaurant.price_tier in {"$", "$$"}:
                score += 1.0

        if score != 0:
            self._add_breakdown(breakdown, "outing type", score)

        return score, strong_matches

    def _apply_contradiction_penalties(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        drinks_focus: bool,
        atmosphere: list[str],
        reasons: list[str],
        penalized_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int]:
        penalty = 0.0
        contradictions = 0

        outing = self._normalize_text(outing_type)
        budget_value = self._normalize_text(budget)
        pace_value = self._normalize_text(pace)
        social_value = self._normalize_text(social_context)
        restaurant_pace = self._normalize_text(restaurant.pace)
        restaurant_social = self._normalize_text(restaurant.social_style)
        atmosphere_text = self._normalize_text(restaurant.atmosphere)
        atmosphere_values = [self._normalize_text(value) for value in atmosphere]

        if budget_value == "$" and restaurant.price_tier == "$$$":
            penalty -= 1.75
            contradictions += 1
            self._append_reason(reasons, "Penalized because it conflicts with a budget-first plan")
            self._append_signal(penalized_signals, "too expensive for budget-first plan")

        if outing == "quick-bite" and restaurant_pace in {"slow", "leisurely"}:
            penalty -= 2.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because the pace is too slow for a quick bite")
            self._append_signal(penalized_signals, "pace too slow for quick bite")

        if outing == "quick-bite" and restaurant.price_tier == "$$$":
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because it feels too premium for a quick bite")
            self._append_signal(penalized_signals, "too premium for quick bite")

        if outing == "coffee-stop" and self._has_tag(restaurant_tag_names, "night-out"):
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because it leans too much toward nightlife for a coffee stop")
            self._append_signal(penalized_signals, "too nightlife-led for coffee stop")

        if social_value == "solo" and restaurant_social == "group":
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because it skews too group-oriented for a solo outing")
            self._append_signal(penalized_signals, "too group-oriented for solo outing")

        if social_value == "date" and restaurant_social == "group":
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because it skews too group-oriented for a date")
            self._append_signal(penalized_signals, "too group-oriented for date outing")

        if "quiet" in atmosphere_values and "lively" in atmosphere_text:
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because the atmosphere is livelier than requested")
            self._append_signal(penalized_signals, "more lively than requested")

        if "lively" in atmosphere_values and "quiet" in atmosphere_text:
            penalty -= 1.0
            contradictions += 1
            self._append_reason(reasons, "Penalized because the atmosphere is quieter than requested")
            self._append_signal(penalized_signals, "quieter than requested")

        if pace_value == "fast" and restaurant_pace in {"slow", "leisurely"}:
            penalty -= 1.75
            contradictions += 1
            self._append_reason(reasons, "Penalized because the restaurant pace is too slow")
            self._append_signal(penalized_signals, "restaurant pace too slow")

        if pace_value == "leisurely" and restaurant_pace == "fast":
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because the restaurant pace is too rushed")
            self._append_signal(penalized_signals, "restaurant pace too rushed")

        if not drinks_focus and restaurant.serves_alcohol:
            if any(self._has_tag(restaurant_tag_names, tag) for tag in ["pub", "brewery", "brewpub", "winery", "cidery", "night-out"]):
                penalty -= 0.85
                contradictions += 1
                self._append_reason(reasons, "Penalized because the venue is more drinks-led than requested")
                self._append_signal(penalized_signals, "too drinks-led for current build")

        if penalty != 0:
            self._add_breakdown(breakdown, "penalties", penalty)

        return penalty, contradictions

    def _apply_combination_bonus(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int]:
        bonus = 0.0
        strong_matches = 0

        outing = self._normalize_text(outing_type)
        budget_value = self._normalize_text(budget)
        pace_value = self._normalize_text(pace)
        social_value = self._normalize_text(social_context)
        atmosphere_values = {self._normalize_text(value) for value in atmosphere}
        cuisine_values = {self._normalize_text(value) for value in preferred_cuisines}
        atmosphere_text = self._normalize_text(restaurant.atmosphere)

        if outing == "date-night":
            if social_value == "date" and budget_value == "$$$" and atmosphere_values.intersection({"scenic", "refined", "quiet", "cozy"}):
                bonus += 2.25
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a luxury date-night combination")
                self._append_signal(matched_signals, "luxury date-night combination")

        if outing == "drinks-night":
            if drinks_focus and cuisine_values.intersection({"beer", "wine", "cider"}) and (
                self._has_tag(restaurant_tag_names, "night-out")
                or self._has_tag(restaurant_tag_names, "brewery")
                or self._has_tag(restaurant_tag_names, "pub")
                or self._has_tag(restaurant_tag_names, "winery")
                or self._has_tag(restaurant_tag_names, "cidery")
            ):
                bonus += 2.25
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a drinks-night build with strong beverage alignment")
                self._append_signal(matched_signals, "strong drinks-night combination")

        if outing == "coffee-stop":
            if social_value == "solo" and "quiet" in atmosphere_values and "coffee" in cuisine_values:
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a quiet solo coffee-stop combination")
                self._append_signal(matched_signals, "quiet solo coffee combination")

        if outing == "quick-bite":
            if budget_value == "$" and pace_value == "fast":
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a fast and budget-friendly quick-bite build")
                self._append_signal(matched_signals, "fast budget quick-bite combination")

        if outing == "special-occasion":
            if budget_value == "$$$" and atmosphere_values.intersection({"refined", "scenic", "upscale"}):
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a premium special-occasion combination")
                self._append_signal(matched_signals, "premium special-occasion combination")

        if outing == "group-dinner":
            if social_value == "group" and (
                "lively" in atmosphere_values
                or self._has_tag(restaurant_tag_names, "shared-plates")
                or self._has_tag(restaurant_tag_names, "group-friendly")
            ):
                bonus += 1.8
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a social group-dinner combination")
                self._append_signal(matched_signals, "social group-dinner combination")

        if outing == "casual-bite":
            if social_value in {"friends", "group"} and "casual" in atmosphere_values and budget_value in {"$", "$$"}:
                bonus += 1.6
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a casual shared-night combination")
                self._append_signal(matched_signals, "casual shared-night combination")

        if "refined" in atmosphere_values and "casual" in atmosphere_text:
            bonus -= 0.65

        if bonus != 0:
            self._add_breakdown(breakdown, "combination bonus", bonus)

        return bonus, strong_matches

    def _select_menu_items(
        self,
        restaurant: Restaurant,
        preferred_cuisines: list[str],
        drinks_focus: bool,
        outing_type: Optional[str],
    ) -> tuple[list[str], list[str]]:
        cuisine_values = {self._normalize_text(value) for value in preferred_cuisines}
        outing = self._normalize_text(outing_type)

        dish_candidates: list[tuple[float, str]] = []
        drink_candidates: list[tuple[float, str]] = []

        for item in restaurant.menu_items:
            item_text = self._text_blob(item.name, item.description)
            item_tag_names = [self._normalize_text(tag.name) for tag in item.tags]
            item_score = 0.0

            if item.is_signature:
                item_score += 1.1

            for value in cuisine_values:
                if value in item_text or any(value == tag or value in tag for tag in item_tag_names):
                    item_score += 2.0

            if item.category == "dish":
                if outing in {"date-night", "special-occasion"} and item.is_signature:
                    item_score += 0.8
                if outing == "quick-bite" and item.price is not None and item.price <= 18:
                    item_score += 0.8
                if outing == "casual-bite" and ("share" in item_text or "comfort" in item_text):
                    item_score += 0.6
                dish_candidates.append((item_score, item.name))

            elif item.category == "drink":
                if drinks_focus:
                    item_score += 1.3
                if outing == "coffee-stop" and any(term in item_text for term in ["coffee", "espresso", "latte", "cappuccino"]):
                    item_score += 2.2
                if outing == "drinks-night" and any(term in item_text for term in ["beer", "wine", "cider", "cocktail", "flight"]):
                    item_score += 2.2
                drink_candidates.append((item_score, item.name))

        dish_candidates.sort(key=lambda entry: (-entry[0], entry[1].lower()))
        drink_candidates.sort(key=lambda entry: (-entry[0], entry[1].lower()))

        suggested_dishes = [name for _, name in dish_candidates[:2]]
        suggested_drinks = [name for _, name in drink_candidates[:2]]

        return suggested_dishes, suggested_drinks

    def _determine_confidence(
        self,
        score: float,
        strong_matches: int,
        soft_matches: int,
        contradictions: int,
    ) -> str:
        if score >= 11 and strong_matches >= 4 and contradictions <= 1:
            return "high"
        if score >= 7 and strong_matches >= 2 and contradictions <= 2:
            return "medium"
        if strong_matches + soft_matches >= 3 and contradictions <= 2:
            return "medium"
        return "exploratory"

    def _build_explanation(
        self,
        outing_type: Optional[str],
        confidence_level: str,
        matched_signals: list[str],
        penalized_signals: list[str],
    ) -> str:
        outing = self._normalize_text(outing_type).replace("-", " ")
        prefix_map = {
            "high": "High-confidence match.",
            "medium": "Solid fit.",
            "exploratory": "Exploratory fit.",
        }
        prefix = prefix_map.get(confidence_level, "Recommendation ready.")

        if outing and outing not in {"surprise", "natural language"}:
            if matched_signals:
                sentence = f"{prefix} Good alignment for {outing}, driven by {matched_signals[0]}."
            else:
                sentence = f"{prefix} Good alignment for {outing}."
        elif matched_signals:
            sentence = f"{prefix} Driven by {matched_signals[0]}."
        else:
            sentence = prefix

        if penalized_signals:
            sentence += f" Watch-out: {penalized_signals[0]}."

        return sentence

    def _score_restaurants(
        self,
        user: User,
        restaurants: list[Restaurant],
        mode: str,
        outing_type: Optional[str],
        mood: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
    ) -> list[RecommendationItem]:
        preference = user.preference
        experiences = self.experience_repository.list_by_user_id(user.id)

        positively_rated_restaurant_ids = {
            experience.restaurant_id
            for experience in experiences
            if experience.restaurant_id is not None
            and experience.overall_rating is not None
            and float(experience.overall_rating) >= 4
        }

        negatively_rated_restaurant_ids = {
            experience.restaurant_id
            for experience in experiences
            if experience.restaurant_id is not None
            and experience.overall_rating is not None
            and float(experience.overall_rating) <= 2.5
        }

        results: list[RecommendationItem] = []

        for restaurant in restaurants:
            score = 0.0
            reasons: list[str] = []
            matched_signals: list[str] = []
            penalized_signals: list[str] = []
            breakdown: dict[str, float] = {}
            strong_matches = 0
            soft_matches = 0
            contradictions = 0

            restaurant_tag_names = [self._normalize_text(tag.name) for tag in restaurant.tags]
            description_text = self._normalize_text(restaurant.description)
            atmosphere_text = self._normalize_text(restaurant.atmosphere)
            social_style = self._normalize_text(restaurant.social_style)
            pace_value = self._normalize_text(restaurant.pace)

            outing_score, outing_strong = self._apply_outing_type_score(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                reasons=reasons,
                matched_signals=matched_signals,
                breakdown=breakdown,
            )
            score += outing_score
            strong_matches += outing_strong

            if budget and restaurant.price_tier == budget:
                score += 2.6
                strong_matches += 1
                self._append_reason(reasons, f"Matches your budget target ({budget})")
                self._append_signal(matched_signals, f"budget fit ({budget})")
                self._add_breakdown(breakdown, "budget", 2.6)
            elif budget == "$$" and restaurant.price_tier in {"$", "$$$"}:
                score += 0.35
                soft_matches += 1
                self._add_breakdown(breakdown, "budget", 0.35)

            if pace and pace_value == self._normalize_text(pace):
                score += 2.3
                strong_matches += 1
                self._append_reason(reasons, f"Fits your preferred pace ({pace})")
                self._append_signal(matched_signals, f"pace fit ({pace})")
                self._add_breakdown(breakdown, "pace", 2.3)

            if social_context and social_style == self._normalize_text(social_context):
                score += 2.5
                strong_matches += 1
                self._append_reason(reasons, f"Works well for your social setting ({social_context})")
                self._append_signal(matched_signals, f"social fit ({social_context})")
                self._add_breakdown(breakdown, "social context", 2.5)

            for value in atmosphere:
                lowered = self._normalize_text(value)
                if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                    score += 1.6
                    soft_matches += 1
                    self._append_reason(reasons, f"Matches the atmosphere you asked for ({value})")
                    self._append_signal(matched_signals, f"atmosphere match ({value})")
                    self._add_breakdown(breakdown, "atmosphere", 1.6)

            for cuisine in preferred_cuisines:
                lowered = self._normalize_text(cuisine)
                if self._has_tag(restaurant_tag_names, lowered):
                    score += 1.85
                    soft_matches += 1
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")
                    self._append_signal(matched_signals, f"interest match ({cuisine})")
                    self._add_breakdown(breakdown, "interests", 1.85)
                elif lowered in description_text or lowered in atmosphere_text:
                    score += 1.0
                    soft_matches += 1
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")
                    self._append_signal(matched_signals, f"interest match ({cuisine})")
                    self._add_breakdown(breakdown, "interests", 1.0)

            if drinks_focus and restaurant.serves_alcohol:
                score += 1.8
                soft_matches += 1
                self._append_reason(reasons, "Supports a drink-focused outing")
                self._append_signal(matched_signals, "drink-focused support")
                self._add_breakdown(breakdown, "drinks focus", 1.8)

            combination_bonus, combination_strong = self._apply_combination_bonus(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                budget=budget,
                pace=pace,
                social_context=social_context,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=drinks_focus,
                atmosphere=atmosphere,
                reasons=reasons,
                matched_signals=matched_signals,
                breakdown=breakdown,
            )
            score += combination_bonus
            strong_matches += combination_strong

            contradiction_penalty, contradiction_count = self._apply_contradiction_penalties(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                budget=budget,
                pace=pace,
                social_context=social_context,
                drinks_focus=drinks_focus,
                atmosphere=atmosphere,
                reasons=reasons,
                penalized_signals=penalized_signals,
                breakdown=breakdown,
            )
            score += contradiction_penalty
            contradictions += contradiction_count

            if preference is not None:
                preference_points = 0.0

                for value in preference.atmosphere_preferences:
                    lowered = self._normalize_text(value)
                    if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                        score += 1.0
                        preference_points += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved atmosphere preference ({value})")
                        self._append_signal(matched_signals, f"saved atmosphere preference ({value})")

                for value in preference.social_preferences:
                    if social_style and self._normalize_text(value) in social_style:
                        score += 1.0
                        preference_points += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved social preference ({value})")
                        self._append_signal(matched_signals, f"saved social preference ({value})")

                for value in preference.cuisine_preferences:
                    lowered = self._normalize_text(value)
                    if self._has_tag(restaurant_tag_names, lowered) or lowered in description_text:
                        score += 1.0
                        preference_points += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved cuisine preference ({value})")
                        self._append_signal(matched_signals, f"saved cuisine preference ({value})")

                if preference.price_sensitivity and restaurant.price_tier == preference.price_sensitivity:
                    score += 0.75
                    preference_points += 0.75
                    soft_matches += 1
                    self._append_reason(reasons, "Fits your saved budget preference")
                    self._append_signal(matched_signals, "saved budget preference")

                if preference_points != 0:
                    self._add_breakdown(breakdown, "saved preferences", preference_points)

            history_points = 0.0

            if restaurant.id in positively_rated_restaurant_ids:
                score += 1.5
                history_points += 1.5
                soft_matches += 1
                self._append_reason(reasons, "You rated this restaurant well before")
                self._append_signal(matched_signals, "positive rating history")

            if restaurant.id in negatively_rated_restaurant_ids:
                score -= 2.0
                history_points -= 2.0
                contradictions += 1
                self._append_reason(reasons, "Lowered because of a past low rating")
                self._append_signal(penalized_signals, "past low rating")

            if history_points != 0:
                self._add_breakdown(breakdown, "history", history_points)

            suggested_dishes, suggested_drinks = self._select_menu_items(
                restaurant=restaurant,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=drinks_focus,
                outing_type=outing_type,
            )

            if not reasons:
                reasons.append("General profile match")

            confidence_level = self._determine_confidence(
                score=score,
                strong_matches=strong_matches,
                soft_matches=soft_matches,
                contradictions=contradictions,
            )

            explanation = self._build_explanation(
                outing_type=outing_type,
                confidence_level=confidence_level,
                matched_signals=matched_signals,
                penalized_signals=penalized_signals,
            )

            fit_label = self._fit_label(score, confidence_level)

            score_breakdown = [
                ScoreBreakdownItem(label=label, points=round(points, 2))
                for label, points in sorted(
                    breakdown.items(),
                    key=lambda entry: (-abs(entry[1]), entry[0].lower())
                )
            ]

            results.append(
                RecommendationItem(
                    restaurant_id=restaurant.id,
                    restaurant_name=restaurant.name,
                    score=round(score, 2),
                    fit_label=fit_label,
                    reasons=reasons[:6],
                    explanation=explanation,
                    confidence_level=confidence_level,
                    matched_signals=matched_signals[:6],
                    penalized_signals=penalized_signals[:4],
                    score_breakdown=score_breakdown[:8],
                    suggested_dishes=suggested_dishes,
                    suggested_drinks=suggested_drinks,
                )
            )

        results.sort(key=lambda item: item.score, reverse=True)

        ranked_results: list[RecommendationItem] = []
        for index, item in enumerate(results[:5], start=1):
            ranked_results.append(
                RecommendationItem(
                    restaurant_id=item.restaurant_id,
                    restaurant_name=item.restaurant_name,
                    score=item.score,
                    rank=index,
                    fit_label=item.fit_label,
                    reasons=item.reasons,
                    explanation=item.explanation,
                    confidence_level=item.confidence_level,
                    matched_signals=item.matched_signals,
                    penalized_signals=item.penalized_signals,
                    score_breakdown=item.score_breakdown,
                    suggested_dishes=item.suggested_dishes,
                    suggested_drinks=item.suggested_drinks,
                )
            )

        return ranked_results
PY

cat > frontend/src/types.ts <<'TS'
export type AuthUser = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  onboarding_completed: boolean;
};

export type UserProfileResponse = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  is_active: boolean;
  onboarding_completed: boolean;
  created_at: string;
};

export type TokenResponse = {
  access_token: string;
  token_type: string;
};

export type RestaurantListItem = {
  id: number;
  name: string;
  description: string | null;
  city: string;
  price_tier: string;
  atmosphere: string | null;
  pace: string | null;
  social_style: string | null;
  serves_alcohol: boolean;
};

export type Tag = {
  id: number;
  name: string;
  category: string;
};

export type MenuItem = {
  id: number;
  restaurant_id: number;
  name: string;
  category: string;
  price: number | null;
  description: string | null;
  is_signature: boolean;
  tags: Tag[];
};

export type RestaurantDetail = RestaurantListItem & {
  tags: Tag[];
  menu_items: MenuItem[];
};

export type OnboardingPayload = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string | null;
  spice_tolerance: string | null;
  price_sensitivity: string | null;
};

export type OnboardingResponse = {
  message: string;
  onboarding_completed: boolean;
};

export type ScoreBreakdownItem = {
  label: string;
  points: number;
};

export type RecommendationRequestSummary = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus: boolean;
  atmosphere: string[];
};

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  rank?: number;
  fit_label?: string;
  reasons: string[];
  explanation?: string | null;
  confidence_level?: "high" | "medium" | "exploratory" | string;
  matched_signals?: string[];
  penalized_signals?: string[];
  score_breakdown?: ScoreBreakdownItem[];
  suggested_dishes: string[];
  suggested_drinks: string[];
};

export type RecommendationResponse = {
  mode: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: RecommendationRequestSummary;
  results: RecommendationItem[];
};

export type ExperienceRating = {
  id: number;
  category: string;
  score: number;
};

export type Experience = {
  id: number;
  user_id: number;
  restaurant_id: number | null;
  title: string | null;
  occasion: string | null;
  social_context: string | null;
  notes: string | null;
  overall_rating: number | null;
  created_at: string;
  ratings: ExperienceRating[];
};
TS

cat > frontend/src/components/dining/RecommendationCard.tsx <<'TS'
import { useState } from "react";

import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";
import { ScoreBreakdownItem } from "../../types";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  rank?: number;
  fitLabel?: string;
  explanation?: string;
  confidenceLevel?: string;
  tags?: string[];
  matchedSignals?: string[];
  penalizedSignals?: string[];
  scoreBreakdown?: ScoreBreakdownItem[];
  ctaLabel?: string;
  onClick?: () => void;
};

function formatScore(score?: number) {
  if (score === undefined || score === null || Number.isNaN(score)) {
    return null;
  }

  return `${Math.round(score * 100)}% match`;
}

function confidenceTone(confidenceLevel?: string): "default" | "accent" | "success" | "warning" {
  switch ((confidenceLevel || "").toLowerCase()) {
    case "high":
      return "success";
    case "medium":
      return "accent";
    case "exploratory":
      return "warning";
    default:
      return "default";
  }
}

function confidenceLabel(confidenceLevel?: string): string | null {
  if (!confidenceLevel) {
    return null;
  }

  if (confidenceLevel === "high") {
    return "High confidence";
  }

  if (confidenceLevel === "medium") {
    return "Medium confidence";
  }

  if (confidenceLevel === "exploratory") {
    return "Exploratory";
  }

  return confidenceLevel;
}

function fitTone(fitLabel?: string): "default" | "accent" | "success" | "warning" {
  switch ((fitLabel || "").toLowerCase()) {
    case "excellent fit":
      return "success";
    case "strong fit":
      return "accent";
    case "possible fit":
      return "warning";
    default:
      return "default";
  }
}

function formatBreakdownPoints(points: number): string {
  return `${points >= 0 ? "+" : ""}${points.toFixed(2)}`;
}

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  rank,
  fitLabel,
  explanation,
  confidenceLevel,
  tags = [],
  matchedSignals = [],
  penalizedSignals = [],
  scoreBreakdown = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const [expanded, setExpanded] = useState(false);
  const scoreLabel = formatScore(score);
  const confidence = confidenceLabel(confidenceLevel);

  return (
    <Card
      className="recommendation-card"
      title={rank ? `#${rank} • ${title}` : title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={
        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
          {scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : <Badge>Match pending</Badge>}
          {fitLabel ? <Badge tone={fitTone(fitLabel)}>{fitLabel}</Badge> : null}
          {confidence ? <Badge tone={confidenceTone(confidenceLevel)}>{confidence}</Badge> : null}
        </div>
      }
    >
      <div className="grid" style={{ gap: "0.9rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {explanation || "A recommendation is ready, but no explanation was provided yet."}
        </p>

        {tags.length > 0 ? (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            {tags.map((tag) => (
              <Badge key={tag} tone="accent">
                {tag}
              </Badge>
            ))}
          </div>
        ) : (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            <Badge>Context-aware</Badge>
            <Badge tone="accent">Dining fit</Badge>
          </div>
        )}

        <div className="button-row" style={{ marginTop: 0 }}>
          <Button variant="ghost" onClick={() => setExpanded((prev) => !prev)}>
            {expanded ? "Hide scoring detail" : "Show scoring detail"}
          </Button>

          {onClick ? (
            <Button variant="ghost" onClick={onClick}>
              {ctaLabel}
            </Button>
          ) : null}
        </div>

        {expanded ? (
          <div className="grid" style={{ gap: "0.85rem" }}>
            {matchedSignals.length > 0 ? (
              <div className="item">
                <strong>Matched signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {matchedSignals.map((signal) => (
                    <Badge key={signal} tone="success">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {penalizedSignals.length > 0 ? (
              <div className="item">
                <strong>Penalized signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {penalizedSignals.map((signal) => (
                    <Badge key={signal} tone="warning">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {scoreBreakdown.length > 0 ? (
              <div className="item">
                <strong>Score breakdown</strong>
                <div style={{ display: "grid", gap: "0.45rem", marginTop: "0.6rem" }}>
                  {scoreBreakdown.map((entry) => (
                    <div
                      key={`${entry.label}-${entry.points}`}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        gap: "1rem",
                        padding: "0.55rem 0.7rem",
                        borderRadius: "0.75rem",
                        background: "rgba(15, 23, 42, 0.35)",
                        border: "1px solid rgba(148, 163, 184, 0.15)"
                      }}
                    >
                      <span>{entry.label}</span>
                      <strong>{formatBreakdownPoints(entry.points)}</strong>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>
    </Card>
  );
}
TS

cat > frontend/src/pages/RecommendationsPage.tsx <<'TS'
import { FormEvent, useEffect, useMemo, useState } from "react";

import RecommendationCard from "../components/dining/RecommendationCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RecommendationItem, RecommendationResponse } from "../types";

type Mode = "build" | "describe" | "surprise";
type SingleBuildField = "outing_type" | "budget" | "pace" | "social_context";
type MultiBuildField = "preferred_cuisines" | "atmosphere";

type BuildFormState = {
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
};

type BlockOption = {
  label: string;
  value: string;
  hint?: string;
};

type BuildPreset = {
  label: string;
  description: string;
  state: BuildFormState;
};

type SavedRun = {
  id: string;
  createdAt: string;
  engineVersion: string;
  requestSummary: BuildFormState;
  resultCount: number;
  topResultName: string | null;
};

const RUN_STORAGE_KEY = "build-your-night-recent-runs-v1";

const modeMeta: Record<
  Mode,
  {
    eyebrow: string;
    title: string;
    subtitle: string;
    bullets: string[];
  }
> = {
  build: {
    eyebrow: "Structured mode",
    title: "Build Your Night",
    subtitle:
      "Build the night by clicking exact option blocks that map directly to the recommendation engine.",
    bullets: [
      "Uses canonical values shared with the backend scorer.",
      "Best for controlled demos and predictable comparisons.",
      "Now includes transparency, saved runs, and exportable diagnostics."
    ]
  },
  describe: {
    eyebrow: "Prompt mode",
    title: "Describe Your Night",
    subtitle:
      "Write the kind of night you want in natural language and let the system interpret it.",
    bullets: [
      "Best when the vibe matters more than form fields.",
      "Feels closer to a real assistant experience.",
      "Useful for testing natural-language intent parsing."
    ]
  },
  surprise: {
    eyebrow: "Exploration mode",
    title: "Surprise Me",
    subtitle: "Get recommendations quickly with minimal friction.",
    bullets: [
      "Fastest path to discovery.",
      "Uses your saved preferences when available.",
      "Good for novelty and low-effort browsing."
    ]
  }
};

const outingOptions: BlockOption[] = [
  { label: "Casual bite", value: "casual-bite", hint: "easy, flexible, low-pressure" },
  { label: "Date night", value: "date-night", hint: "romantic, polished, slower" },
  { label: "Group dinner", value: "group-dinner", hint: "social, shareable, energetic" },
  { label: "Drinks night", value: "drinks-night", hint: "beer, wine, pub, brewery" },
  { label: "Quick bite", value: "quick-bite", hint: "fast, convenient, affordable" },
  { label: "Coffee stop", value: "coffee-stop", hint: "café, coffeehouse, study-friendly" },
  { label: "Special occasion", value: "special-occasion", hint: "refined, scenic, memorable" }
];

const budgetOptions: BlockOption[] = [
  { label: "$", value: "$", hint: "budget-friendly" },
  { label: "$$", value: "$$", hint: "mid-range" },
  { label: "$$$", value: "$$$", hint: "premium" }
];

const paceOptions: BlockOption[] = [
  { label: "Fast", value: "fast" },
  { label: "Moderate", value: "moderate" },
  { label: "Slow", value: "slow" },
  { label: "Leisurely", value: "leisurely" }
];

const socialOptions: BlockOption[] = [
  { label: "Solo", value: "solo" },
  { label: "Friends", value: "friends" },
  { label: "Group", value: "group" },
  { label: "Date", value: "date" }
];

const cuisineOptions: BlockOption[] = [
  { label: "Pizza", value: "pizza" },
  { label: "Mediterranean", value: "mediterranean" },
  { label: "Asian", value: "asian" },
  { label: "Bakery", value: "bakery" },
  { label: "Dessert", value: "dessert" },
  { label: "Seasonal", value: "seasonal" },
  { label: "Turkish", value: "turkish" },
  { label: "Coffee", value: "coffee" },
  { label: "Beer", value: "beer" },
  { label: "Wine", value: "wine" },
  { label: "Cider", value: "cider" }
];

const atmosphereOptions: BlockOption[] = [
  { label: "Cozy", value: "cozy" },
  { label: "Lively", value: "lively" },
  { label: "Quiet", value: "quiet" },
  { label: "Casual", value: "casual" },
  { label: "Scenic", value: "scenic" },
  { label: "Historic", value: "historic" },
  { label: "Refined", value: "refined" },
  { label: "Upscale", value: "upscale" },
  { label: "Rustic", value: "rustic" }
];

const yesNoOptions: BlockOption[] = [
  { label: "Yes", value: "yes", hint: "drinks should matter" },
  { label: "No", value: "no", hint: "food and setting first" }
];

const initialBuildForm: BuildFormState = {
  outing_type: "casual-bite",
  budget: "",
  pace: "",
  social_context: "",
  preferred_cuisines: [],
  atmosphere: [],
  drinks_focus: false
};

const buildPresets: BuildPreset[] = [
  {
    label: "Scenic date night",
    description: "Luxury, scenic, quieter, wine-friendly validation case.",
    state: {
      outing_type: "date-night",
      budget: "$$$",
      pace: "leisurely",
      social_context: "date",
      preferred_cuisines: ["wine", "seasonal"],
      atmosphere: ["scenic", "quiet", "refined"],
      drinks_focus: true
    }
  },
  {
    label: "Fast solo bite",
    description: "Budget, fast, solo validation case.",
    state: {
      outing_type: "quick-bite",
      budget: "$",
      pace: "fast",
      social_context: "solo",
      preferred_cuisines: ["asian"],
      atmosphere: ["casual"],
      drinks_focus: false
    }
  },
  {
    label: "Quiet coffee stop",
    description: "Solo coffee validation case.",
    state: {
      outing_type: "coffee-stop",
      budget: "$",
      pace: "slow",
      social_context: "solo",
      preferred_cuisines: ["coffee"],
      atmosphere: ["quiet"],
      drinks_focus: false
    }
  },
  {
    label: "Group drinks night",
    description: "Social drinks-forward validation case.",
    state: {
      outing_type: "drinks-night",
      budget: "$$",
      pace: "moderate",
      social_context: "group",
      preferred_cuisines: ["beer", "wine"],
      atmosphere: ["lively", "casual"],
      drinks_focus: true
    }
  }
];

function normalizeScore(score?: number): number | undefined {
  if (typeof score !== "number" || Number.isNaN(score)) {
    return undefined;
  }

  return Math.max(0, Math.min(score / 14, 1));
}

function normalizeRecommendation(item: RecommendationItem, index: number) {
  const reasons = item.reasons ?? [];
  const suggestedDishes = item.suggested_dishes ?? [];
  const suggestedDrinks = item.suggested_drinks ?? [];

  const tagValues = [
    ...suggestedDishes.map((dish) => `dish: ${dish}`),
    ...suggestedDrinks.map((drink) => `drink: ${drink}`)
  ].slice(0, 4);

  return {
    id: item.restaurant_id ?? index,
    title: item.restaurant_name ?? `Recommendation ${index + 1}`,
    restaurantName: item.restaurant_name,
    rank: item.rank,
    fitLabel: item.fit_label,
    explanation:
      item.explanation ||
      (reasons.length > 0
        ? reasons.join(" • ")
        : "This restaurant matched your current dining request."),
    score: normalizeScore(item.score),
    confidenceLevel: item.confidence_level,
    matchedSignals: item.matched_signals ?? [],
    penalizedSignals: item.penalized_signals ?? [],
    scoreBreakdown: item.score_breakdown ?? [],
    tags: tagValues
  };
}

function toggleArrayValue(values: string[], value: string): string[] {
  if (values.includes(value)) {
    return values.filter((entry) => entry !== value);
  }

  return [...values, value];
}

function BlockSection({
  title,
  subtitle,
  options,
  selectedValue,
  onSelect
}: {
  title: string;
  subtitle: string;
  options: BlockOption[];
  selectedValue: string;
  onSelect: (value: string) => void;
}) {
  return (
    <div className="build-section">
      <div className="build-section__copy">
        <strong>{title}</strong>
        <p className="muted">{subtitle}</p>
      </div>
      <div className="build-block-grid">
        {options.map((option) => {
          const active = selectedValue === option.value;
          return (
            <button
              key={option.value}
              type="button"
              className={active ? "build-block active" : "build-block"}
              onClick={() => onSelect(option.value)}
            >
              <span className="build-block__label">{option.label}</span>
              {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function MultiBlockSection({
  title,
  subtitle,
  options,
  selectedValues,
  onToggle
}: {
  title: string;
  subtitle: string;
  options: BlockOption[];
  selectedValues: string[];
  onToggle: (value: string) => void;
}) {
  return (
    <div className="build-section">
      <div className="build-section__copy">
        <strong>{title}</strong>
        <p className="muted">{subtitle}</p>
      </div>
      <div className="build-block-grid">
        {options.map((option) => {
          const active = selectedValues.includes(option.value);
          return (
            <button
              key={option.value}
              type="button"
              className={active ? "build-block active" : "build-block"}
              onClick={() => onToggle(option.value)}
            >
              <span className="build-block__label">{option.label}</span>
              {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function formatRunSummary(run: SavedRun): string {
  const parts: string[] = [];
  if (run.requestSummary.outing_type) parts.push(run.requestSummary.outing_type);
  if (run.requestSummary.budget) parts.push(run.requestSummary.budget);
  if (run.requestSummary.pace) parts.push(run.requestSummary.pace);
  if (run.requestSummary.social_context) parts.push(run.requestSummary.social_context);
  return parts.join(" • ");
}

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [results, setResults] = useState<RecommendationItem[]>([]);
  const [lastResponse, setLastResponse] = useState<RecommendationResponse | null>(null);
  const [savedRuns, setSavedRuns] = useState<SavedRun[]>([]);

  const [buildForm, setBuildForm] = useState<BuildFormState>(initialBuildForm);
  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);

  const activeMeta = modeMeta[mode];

  useEffect(() => {
    try {
      const raw = localStorage.getItem(RUN_STORAGE_KEY);
      if (!raw) return;
      const parsed = JSON.parse(raw) as SavedRun[];
      if (Array.isArray(parsed)) {
        setSavedRuns(parsed);
      }
    } catch {
      setSavedRuns([]);
    }
  }, []);

  const normalizedResults = useMemo(
    () => results.map((item, index) => normalizeRecommendation(item, index)),
    [results]
  );

  const buildSummary = useMemo(() => {
    const parts: string[] = [];

    if (buildForm.outing_type) parts.push(`outing: ${buildForm.outing_type}`);
    if (buildForm.budget) parts.push(`budget: ${buildForm.budget}`);
    if (buildForm.pace) parts.push(`pace: ${buildForm.pace}`);
    if (buildForm.social_context) parts.push(`social: ${buildForm.social_context}`);
    if (buildForm.preferred_cuisines.length > 0) {
      parts.push(`interests: ${buildForm.preferred_cuisines.join(", ")}`);
    }
    if (buildForm.atmosphere.length > 0) {
      parts.push(`atmosphere: ${buildForm.atmosphere.join(", ")}`);
    }
    parts.push(`drinks focus: ${buildForm.drinks_focus ? "yes" : "no"}`);

    return parts;
  }, [buildForm]);

  function persistRun(data: RecommendationResponse, requestSummary: BuildFormState) {
    const nextRun: SavedRun = {
      id: `${Date.now()}`,
      createdAt: data.generated_at || new Date().toISOString(),
      engineVersion: data.engine_version || "unknown",
      requestSummary,
      resultCount: data.results.length,
      topResultName: data.results[0]?.restaurant_name || null
    };

    const nextRuns = [nextRun, ...savedRuns].slice(0, 8);
    setSavedRuns(nextRuns);
    localStorage.setItem(RUN_STORAGE_KEY, JSON.stringify(nextRuns));
  }

  async function runRequest(
    endpoint: string,
    payload: Record<string, unknown>,
    options?: { saveBuildRun?: boolean; buildState?: BuildFormState }
  ) {
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = await apiRequest<RecommendationResponse>(endpoint, {
        method: "POST",
        body: payload
      });

      const recs = Array.isArray(data.results) ? data.results : [];

      setResults(recs);
      setLastResponse(data);

      if (options?.saveBuildRun && options.buildState) {
        persistRun(data, options.buildState);
      }

      setSuccess(
        recs.length > 0
          ? `Generated ${recs.length} recommendation${recs.length === 1 ? "" : "s"}.`
          : "Request completed, but no recommendations were returned."
      );
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Failed to generate recommendations.";
      setError(message);
      setResults([]);
      setLastResponse(null);
    } finally {
      setLoading(false);
    }
  }

  async function handleBuildSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest(
      "/recommendations/build-your-night",
      {
        outing_type: buildForm.outing_type,
        budget: buildForm.budget || null,
        pace: buildForm.pace || null,
        social_context: buildForm.social_context || null,
        preferred_cuisines: buildForm.preferred_cuisines,
        drinks_focus: buildForm.drinks_focus,
        atmosphere: buildForm.atmosphere
      },
      {
        saveBuildRun: true,
        buildState: buildForm
      }
    );
  }

  async function handleDescribeSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest("/recommendations/describe-your-night", {
      prompt: describeText.trim()
    });
  }

  async function handleSurprise() {
    await runRequest("/recommendations/surprise-me", {
      include_drinks: includeDrinks
    });
  }

  function selectSingle(field: SingleBuildField, value: string) {
    setBuildForm((prev) => ({ ...prev, [field]: prev[field] === value ? "" : value }));
  }

  function toggleMulti(field: MultiBuildField, value: string) {
    setBuildForm((prev) => ({
      ...prev,
      [field]: toggleArrayValue(prev[field], value)
    }));
  }

  function resetBuildForm() {
    setBuildForm(initialBuildForm);
  }

  function applyPreset(preset: BuildPreset) {
    setMode("build");
    setBuildForm(preset.state);
  }

  function applySavedRun(run: SavedRun) {
    setMode("build");
    setBuildForm(run.requestSummary);
  }

  function clearSavedRuns() {
    setSavedRuns([]);
    localStorage.removeItem(RUN_STORAGE_KEY);
  }

  function exportDiagnostics() {
    if (!lastResponse) {
      setError("No diagnostics available to export yet.");
      return;
    }

    const blob = new Blob([JSON.stringify(lastResponse, null, 2)], {
      type: "application/json"
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    anchor.href = url;
    anchor.download = `recommendation-diagnostics-${stamp}.json`;
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendation studio</p>
        <h1 className="page-title">Generate a better dining fit</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Choose the mode that best matches your decision style. Structured inputs
          give you tighter control, prompt mode feels more conversational, and
          surprise mode is the fastest path to discovery.
        </p>
      </section>

      <section className="grid grid-3">
        <button
          type="button"
          className={mode === "build" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("build")}
        >
          <p className="navbar-eyebrow">Structured</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Build Your Night
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want more control over the recommendation signals.
          </p>
        </button>

        <button
          type="button"
          className={mode === "describe" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("describe")}
        >
          <p className="navbar-eyebrow">Natural language</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Describe Your Night
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want to describe the vibe in your own words.
          </p>
        </button>

        <button
          type="button"
          className={mode === "surprise" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("surprise")}
        >
          <p className="navbar-eyebrow">Fast path</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Surprise Me
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want novelty with almost no effort.
          </p>
        </button>
      </section>

      {mode === "build" ? (
        <>
          <section className="card">
            <p className="navbar-eyebrow">Validation presets</p>
            <h3 style={{ marginTop: "0.35rem" }}>Apply a known test build</h3>
            <p className="muted" style={{ marginTop: 0 }}>
              These presets help you validate whether the engine is ranking the right types of venues.
            </p>
            <div style={{ display: "grid", gap: "0.85rem", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))" }}>
              {buildPresets.map((preset) => (
                <div
                  key={preset.label}
                  style={{
                    border: "1px solid rgba(148, 163, 184, 0.18)",
                    borderRadius: "1rem",
                    padding: "0.95rem",
                    background: "rgba(15, 23, 42, 0.4)"
                  }}
                >
                  <strong>{preset.label}</strong>
                  <p className="muted" style={{ marginTop: "0.45rem", marginBottom: "0.85rem" }}>
                    {preset.description}
                  </p>
                  <Button variant="secondary" onClick={() => applyPreset(preset)}>
                    Apply preset
                  </Button>
                </div>
              ))}
            </div>
          </section>

          <section className="card">
            <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap", alignItems: "center" }}>
              <div>
                <p className="navbar-eyebrow">Saved runs</p>
                <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>Recent Build Your Night runs</h3>
                <p className="muted" style={{ margin: 0 }}>
                  Reapply earlier builds fast and export the latest diagnostics for QA.
                </p>
              </div>
              <div className="button-row">
                <Button variant="secondary" onClick={exportDiagnostics}>
                  Export latest diagnostics
                </Button>
                <Button variant="ghost" onClick={clearSavedRuns}>
                  Clear saved runs
                </Button>
              </div>
            </div>

            {savedRuns.length === 0 ? (
              <p className="muted" style={{ marginTop: "1rem", marginBottom: 0 }}>
                No saved runs yet. Generate a Build Your Night recommendation to populate this panel.
              </p>
            ) : (
              <div style={{ display: "grid", gap: "0.8rem", marginTop: "1rem" }}>
                {savedRuns.map((run) => (
                  <div
                    key={run.id}
                    style={{
                      border: "1px solid rgba(148, 163, 184, 0.18)",
                      borderRadius: "1rem",
                      padding: "0.9rem",
                      background: "rgba(15, 23, 42, 0.32)",
                      display: "grid",
                      gap: "0.45rem"
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
                      <strong>{formatRunSummary(run) || "Saved build"}</strong>
                      <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                        <Badge tone="accent">{run.engineVersion}</Badge>
                        <Badge>{run.resultCount} results</Badge>
                      </div>
                    </div>
                    <p className="muted" style={{ margin: 0 }}>
                      Top result: {run.topResultName || "none"} • {new Date(run.createdAt).toLocaleString()}
                    </p>
                    <div className="button-row">
                      <Button variant="secondary" onClick={() => applySavedRun(run)}>
                        Reapply build
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </>
      ) : null}

      <section className="grid grid-2">
        <Card
          title={activeMeta.title}
          subtitle={activeMeta.subtitle}
          actions={<Badge tone="accent">{activeMeta.eyebrow}</Badge>}
        >
          <div className="item">
            <strong>When to use this mode</strong>
            <ul className="muted" style={{ marginBottom: 0 }}>
              {activeMeta.bullets.map((bullet) => (
                <li key={bullet} style={{ marginBottom: "0.4rem" }}>
                  {bullet}
                </li>
              ))}
            </ul>
          </div>

          {error ? <div className="error">{error}</div> : null}
          {success ? <div className="success">{success}</div> : null}

          {mode === "build" ? (
            <form className="form" onSubmit={handleBuildSubmit}>
              <div className="build-night-layout">
                <BlockSection
                  title="Pick the kind of night"
                  subtitle="Choose the primary intent first."
                  options={outingOptions}
                  selectedValue={buildForm.outing_type}
                  onSelect={(value) => selectSingle("outing_type", value)}
                />

                <BlockSection
                  title="Choose your budget"
                  subtitle="Match the spend level you actually want."
                  options={budgetOptions}
                  selectedValue={buildForm.budget}
                  onSelect={(value) => selectSingle("budget", value)}
                />

                <BlockSection
                  title="Set the pace"
                  subtitle="Control how fast or relaxed the outing should feel."
                  options={paceOptions}
                  selectedValue={buildForm.pace}
                  onSelect={(value) => selectSingle("pace", value)}
                />

                <BlockSection
                  title="Who is this for"
                  subtitle="Tell the engine the social setup."
                  options={socialOptions}
                  selectedValue={buildForm.social_context}
                  onSelect={(value) => selectSingle("social_context", value)}
                />

                <MultiBlockSection
                  title="Pick food and drink interests"
                  subtitle="Select as many cuisine or drink signals as you want."
                  options={cuisineOptions}
                  selectedValues={buildForm.preferred_cuisines}
                  onToggle={(value) => toggleMulti("preferred_cuisines", value)}
                />

                <MultiBlockSection
                  title="Choose the atmosphere"
                  subtitle="These values directly influence the scorer."
                  options={atmosphereOptions}
                  selectedValues={buildForm.atmosphere}
                  onToggle={(value) => toggleMulti("atmosphere", value)}
                />

                <div className="build-section">
                  <div className="build-section__copy">
                    <strong>Should drinks matter</strong>
                    <p className="muted">Toggle whether the engine should actively prefer drink-friendly venues.</p>
                  </div>
                  <div className="build-block-grid build-block-grid--compact">
                    {yesNoOptions.map((option) => {
                      const active = buildForm.drinks_focus === (option.value === "yes");
                      return (
                        <button
                          key={option.value}
                          type="button"
                          className={active ? "build-block active" : "build-block"}
                          onClick={() =>
                            setBuildForm((prev) => ({
                              ...prev,
                              drinks_focus: option.value === "yes"
                            }))
                          }
                        >
                          <span className="build-block__label">{option.label}</span>
                          {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>

              <div className="build-summary">
                <strong>Current build</strong>
                <div className="build-summary__chips">
                  {buildSummary.map((value) => (
                    <span key={value} className="build-summary__chip">
                      {value}
                    </span>
                  ))}
                </div>
              </div>

              <div className="button-row">
                <Button type="button" variant="secondary" onClick={resetBuildForm} disabled={loading}>
                  Reset selections
                </Button>
                <Button type="submit" disabled={loading}>
                  {loading ? "Generating..." : "Generate recommendations"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "describe" ? (
            <form className="form" onSubmit={handleDescribeSubmit}>
              <div className="form-row">
                <label htmlFor="describe_prompt">Describe the night you want</label>
                <textarea
                  id="describe_prompt"
                  value={describeText}
                  onChange={(e) => setDescribeText(e.target.value)}
                  placeholder="I want a cozy dinner spot with good drinks, relaxed pacing, and food that feels memorable without being too formal..."
                />
              </div>

              <div className="button-row">
                <Button type="submit" disabled={loading || describeText.trim().length < 3}>
                  {loading ? "Interpreting..." : "Interpret and recommend"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "surprise" ? (
            <div className="form">
              <div className="item">
                <strong>Low-friction discovery</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  This mode sends a minimal valid backend payload and uses your saved
                  onboarding preferences when available.
                </p>
              </div>

              <div className="form-row">
                <label htmlFor="include_drinks">Include drinks</label>
                <input
                  id="include_drinks"
                  type="checkbox"
                  checked={includeDrinks}
                  onChange={(e) => setIncludeDrinks(e.target.checked)}
                />
              </div>

              <div className="button-row">
                <Button onClick={handleSurprise} disabled={loading}>
                  {loading ? "Finding a surprise..." : "Surprise me"}
                </Button>
              </div>
            </div>
          ) : null}
        </Card>

        <Card
          title="Recommendation output"
          subtitle="Curated results from the active mode"
          actions={
            normalizedResults.length > 0 ? (
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                <Badge tone="success">
                  {normalizedResults.length} result{normalizedResults.length === 1 ? "" : "s"}
                </Badge>
                {lastResponse?.engine_version ? <Badge tone="accent">{lastResponse.engine_version}</Badge> : null}
              </div>
            ) : (
              <Badge>Waiting</Badge>
            )
          }
        >
          {lastResponse?.generated_at ? (
            <div className="item" style={{ marginBottom: "0.9rem" }}>
              <strong>Last run metadata</strong>
              <p className="muted" style={{ margin: "0.35rem 0 0" }}>
                Generated: {new Date(lastResponse.generated_at).toLocaleString()}
              </p>
              {lastResponse.request_summary ? (
                <p className="muted" style={{ margin: "0.2rem 0 0" }}>
                  Request: {lastResponse.request_summary.outing_type || "n/a"}
                  {lastResponse.request_summary.budget ? ` • ${lastResponse.request_summary.budget}` : ""}
                  {lastResponse.request_summary.pace ? ` • ${lastResponse.request_summary.pace}` : ""}
                  {lastResponse.request_summary.social_context ? ` • ${lastResponse.request_summary.social_context}` : ""}
                </p>
              ) : null}
            </div>
          ) : null}

          {normalizedResults.length === 0 ? (
            <div className="list">
              <div className="item">
                <strong>No recommendations yet</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Run one of the recommendation modes to populate this panel with
                  curated dining suggestions.
                </p>
              </div>

              <div className="item">
                <strong>Best next move</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Use a validation preset, generate results, inspect the scoring detail,
                  and export diagnostics when the run looks correct.
                </p>
              </div>
            </div>
          ) : (
            <div className="list">
              {normalizedResults.map((item) => (
                <RecommendationCard
                  key={item.id}
                  title={item.title}
                  restaurantName={item.restaurantName}
                  rank={item.rank}
                  fitLabel={item.fitLabel}
                  score={item.score}
                  explanation={item.explanation}
                  confidenceLevel={item.confidenceLevel}
                  matchedSignals={item.matchedSignals}
                  penalizedSignals={item.penalizedSignals}
                  scoreBreakdown={item.scoreBreakdown}
                  tags={item.tags}
                />
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
TS

echo "running backend syntax validation..."
python3 -m py_compile \
  backend/app/services/recommendation_service.py \
  backend/app/schemas/recommendation.py

echo "phase 4/5 patch applied successfully"
echo "backups saved in: $backup_dir"
