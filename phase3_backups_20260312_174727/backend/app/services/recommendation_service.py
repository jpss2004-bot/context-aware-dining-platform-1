from typing import Optional

from app.models.restaurant import MenuItem, Restaurant
from app.models.user import User
from app.repositories.experience_repository import ExperienceRepository
from app.repositories.restaurant_repository import RestaurantRepository
from app.schemas.recommendation import (
    BuildYourNightRequest,
    DescribeYourNightRequest,
    RecommendationItem,
    RecommendationResponse,
    SurpriseMeRequest,
)


class RecommendationService:
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
        return RecommendationResponse(mode="build-your-night", results=ranked)

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
        return RecommendationResponse(mode="describe-your-night", results=ranked)

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
        return RecommendationResponse(mode="surprise-me", results=ranked)

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
        elif any(word in text for word in ["drinks", "cocktails", "bar", "brewery", "wine"]):
            outing_type = "drinks-night"
        elif any(word in text for word in ["coffee", "cafe", "espresso", "study"]):
            outing_type = "coffee-stop"
        elif any(word in text for word in ["quick", "fast", "grab and go"]):
            outing_type = "quick-bite"
        elif any(word in text for word in ["special occasion", "anniversary", "celebrate"]):
            outing_type = "special-occasion"
        elif any(word in text for word in ["group dinner", "large table", "shared plates"]):
            outing_type = "group-dinner"

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

    def _menu_item_matches_term(self, item: MenuItem, term: str) -> bool:
        target = self._normalize_text(term)
        text = self._text_blob(item.name, item.description)
        tag_names = [self._normalize_text(tag.name) for tag in item.tags]
        return target in text or any(target == tag or target in tag for tag in tag_names)

    def _apply_outing_type_score(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        reasons: list[str],
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
            if self._has_tag(restaurant_tag_names, "date-night") or self._has_tag(restaurant_tag_names, "special-occasion"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Tagged for date-night or special-occasion dining")
            for term in ["quiet", "cozy", "scenic", "refined", "upscale", "historic"]:
                if term in atmosphere_text:
                    score += 0.7

        elif value == "group-dinner":
            if social_style == "group":
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for group dining")
            if self._has_tag(restaurant_tag_names, "group-friendly") or self._has_tag(restaurant_tag_names, "shared-plates"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Supports shared or group-friendly dining")

        elif value == "drinks-night":
            if restaurant.serves_alcohol:
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a drinks-forward night out")
            for term in ["beer", "wine", "cider", "brewery", "pub", "brewpub", "winery", "cidery", "night-out"]:
                if self._has_tag(restaurant_tag_names, term):
                    score += 0.8

        elif value == "quick-bite":
            if pace == "fast":
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a fast quick-bite outing")
            if self._has_tag(restaurant_tag_names, "quick-bite") or self._has_tag(restaurant_tag_names, "takeout"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Supports quick and convenient dining")
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

        elif value == "special-occasion":
            if restaurant.price_tier == "$$$":
                score += 2.5
                strong_matches += 1
                self._append_reason(reasons, "Fits a special-occasion price tier")
            if self._has_tag(restaurant_tag_names, "special-occasion"):
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Tagged for special occasions")
            for term in ["refined", "scenic", "historic", "upscale"]:
                if term in atmosphere_text:
                    score += 0.9

        elif value == "casual-bite":
            if "casual" in atmosphere_text:
                score += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a casual-bite atmosphere")
            if pace in {"fast", "moderate"}:
                score += 1.5
            if restaurant.price_tier in {"$", "$$"}:
                score += 1.0

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

        if budget_value == "$" and restaurant.price_tier == "$$$":
            penalty -= 1.75
            contradictions += 1
            self._append_reason(reasons, "Penalized because it conflicts with a budget-first plan")

        if outing == "quick-bite" and restaurant_pace in {"slow", "leisurely"}:
            penalty -= 2.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because the pace is too slow for a quick bite")

        if outing == "quick-bite" and restaurant.price_tier == "$$$":
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because it feels too premium for a quick bite")

        if outing == "coffee-stop" and self._has_tag(restaurant_tag_names, "night-out"):
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because it leans too much toward nightlife for a coffee stop")

        if social_value == "solo" and restaurant_social == "group":
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because it skews too group-oriented for a solo outing")

        if social_value == "date" and restaurant_social == "group":
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because it skews too group-oriented for a date")

        if "quiet" in [self._normalize_text(value) for value in atmosphere] and "lively" in atmosphere_text:
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because the atmosphere is livelier than requested")

        if "lively" in [self._normalize_text(value) for value in atmosphere] and "quiet" in atmosphere_text:
            penalty -= 1.0
            contradictions += 1
            self._append_reason(reasons, "Penalized because the atmosphere is quieter than requested")

        if pace_value == "fast" and restaurant_pace in {"slow", "leisurely"}:
            penalty -= 1.75
            contradictions += 1
            self._append_reason(reasons, "Penalized because the restaurant pace is too slow")

        if pace_value == "leisurely" and restaurant_pace == "fast":
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because the restaurant pace is too rushed")

        if not drinks_focus and restaurant.serves_alcohol:
            if any(self._has_tag(restaurant_tag_names, tag) for tag in ["pub", "brewery", "brewpub", "winery", "cidery", "night-out"]):
                penalty -= 0.85
                contradictions += 1
                self._append_reason(reasons, "Penalized because the venue is more drinks-led than requested")

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

        if outing == "coffee-stop":
            if social_value == "solo" and "quiet" in atmosphere_values and "coffee" in cuisine_values:
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a quiet solo coffee-stop combination")

        if outing == "quick-bite":
            if budget_value == "$" and pace_value == "fast":
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a fast and budget-friendly quick-bite build")

        if outing == "special-occasion":
            if budget_value == "$$$" and atmosphere_values.intersection({"refined", "scenic", "upscale"}):
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a premium special-occasion combination")

        if outing == "group-dinner":
            if social_value == "group" and (
                "lively" in atmosphere_values
                or self._has_tag(restaurant_tag_names, "shared-plates")
                or self._has_tag(restaurant_tag_names, "group-friendly")
            ):
                bonus += 1.8
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a social group-dinner combination")

        if outing == "casual-bite":
            if social_value in {"friends", "group"} and "casual" in atmosphere_values and budget_value in {"$", "$$"}:
                bonus += 1.6
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a casual shared-night combination")

        if "refined" in atmosphere_values and "casual" in atmosphere_text:
            bonus -= 0.65

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
        reasons: list[str],
    ) -> str:
        outing = self._normalize_text(outing_type).replace("-", " ")
        prefix_map = {
            "high": "High-confidence match.",
            "medium": "Solid fit.",
            "exploratory": "Exploratory fit.",
        }
        prefix = prefix_map.get(confidence_level, "Recommendation ready.")

        top_reasons = reasons[:2]
        if outing and outing not in {"surprise", "natural language"}:
            if top_reasons:
                return f"{prefix} Good alignment for {outing}, especially because {top_reasons[0].lower()}."
            return f"{prefix} Good alignment for {outing}."
        if top_reasons:
            return f"{prefix} {top_reasons[0]}"
        return prefix

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
            )
            score += outing_score
            strong_matches += outing_strong

            if budget and restaurant.price_tier == budget:
                score += 2.6
                strong_matches += 1
                self._append_reason(reasons, f"Matches your budget target ({budget})")
            elif budget == "$$" and restaurant.price_tier in {"$", "$$$"}:
                score += 0.35
                soft_matches += 1

            if pace and pace_value == self._normalize_text(pace):
                score += 2.3
                strong_matches += 1
                self._append_reason(reasons, f"Fits your preferred pace ({pace})")

            if social_context and social_style == self._normalize_text(social_context):
                score += 2.5
                strong_matches += 1
                self._append_reason(reasons, f"Works well for your social setting ({social_context})")

            for value in atmosphere:
                lowered = self._normalize_text(value)
                if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                    score += 1.6
                    soft_matches += 1
                    self._append_reason(reasons, f"Matches the atmosphere you asked for ({value})")

            for cuisine in preferred_cuisines:
                lowered = self._normalize_text(cuisine)
                if self._has_tag(restaurant_tag_names, lowered):
                    score += 1.85
                    soft_matches += 1
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")
                elif lowered in description_text or lowered in atmosphere_text:
                    score += 1.0
                    soft_matches += 1
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")

            if drinks_focus and restaurant.serves_alcohol:
                score += 1.8
                soft_matches += 1
                self._append_reason(reasons, "Supports a drink-focused outing")

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
            )
            score += contradiction_penalty
            contradictions += contradiction_count

            if preference is not None:
                for value in preference.atmosphere_preferences:
                    lowered = self._normalize_text(value)
                    if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                        score += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved atmosphere preference ({value})")

                for value in preference.social_preferences:
                    if social_style and self._normalize_text(value) in social_style:
                        score += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved social preference ({value})")

                for value in preference.cuisine_preferences:
                    lowered = self._normalize_text(value)
                    if self._has_tag(restaurant_tag_names, lowered) or lowered in description_text:
                        score += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved cuisine preference ({value})")

                if preference.price_sensitivity and restaurant.price_tier == preference.price_sensitivity:
                    score += 0.75
                    soft_matches += 1
                    self._append_reason(reasons, "Fits your saved budget preference")

            if restaurant.id in positively_rated_restaurant_ids:
                score += 1.5
                soft_matches += 1
                self._append_reason(reasons, "You rated this restaurant well before")

            if restaurant.id in negatively_rated_restaurant_ids:
                score -= 2.0
                contradictions += 1
                self._append_reason(reasons, "Lowered because of a past low rating")

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
                reasons=reasons,
            )

            results.append(
                RecommendationItem(
                    restaurant_id=restaurant.id,
                    restaurant_name=restaurant.name,
                    score=round(score, 2),
                    reasons=reasons[:5],
                    explanation=explanation,
                    confidence_level=confidence_level,
                    suggested_dishes=suggested_dishes,
                    suggested_drinks=suggested_drinks,
                )
            )

        results.sort(key=lambda item: item.score, reverse=True)
        return results[:5]
