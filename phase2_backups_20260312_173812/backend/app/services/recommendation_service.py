from typing import Optional

from app.models.restaurant import Restaurant
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
        text = prompt.lower()

        budget = None
        if any(word in text for word in ["cheap", "budget", "affordable", "inexpensive"]):
            budget = "$"
        elif any(word in text for word in ["fancy", "upscale", "premium"]):
            budget = "$$$"

        pace = None
        if any(word in text for word in ["quick", "fast", "late night", "bite"]):
            pace = "fast"
        elif any(word in text for word in ["slow", "relaxed", "romantic", "cozy"]):
            pace = "leisurely"

        social_context = None
        if any(word in text for word in ["friends", "group", "crowd", "social"]):
            social_context = "group"
        elif any(word in text for word in ["solo", "alone", "quiet"]):
            social_context = "solo"
        elif any(word in text for word in ["date", "romantic"]):
            social_context = "date"

        atmosphere = []
        for word in ["cozy", "lively", "quiet", "casual", "scenic", "refined", "upscale"]:
            if word in text:
                atmosphere.append(word)

        preferred_cuisines = []
        for word in ["italian", "pasta", "cocktails", "comfort", "quick", "coffee", "beer", "wine"]:
            if word in text:
                preferred_cuisines.append(word)

        drinks_focus = any(word in text for word in ["drink", "drinks", "cocktail", "cocktails", "bar", "beer", "wine"])

        return {
            "outing_type": "natural-language",
            "mood": None,
            "budget": budget,
            "pace": pace,
            "social_context": social_context,
            "preferred_cuisines": preferred_cuisines,
            "drinks_focus": drinks_focus,
            "atmosphere": atmosphere,
        }

    def _has_tag(self, tag_names: list[str], candidate: str) -> bool:
        target = candidate.lower()
        return any(target == tag or target in tag for tag in tag_names)

    def _append_reason(self, reasons: list[str], message: str) -> None:
        if message not in reasons:
            reasons.append(message)

    def _apply_outing_type_score(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        reasons: list[str],
    ) -> float:
        if not outing_type:
            return 0.0

        score = 0.0
        value = outing_type.lower()
        atmosphere_text = (restaurant.atmosphere or "").lower()
        social_style = (restaurant.social_style or "").lower()
        pace = (restaurant.pace or "").lower()

        if value == "date-night":
            if social_style == "date":
                score += 3.0
                self._append_reason(reasons, "Strong fit for a date-night outing")
            if self._has_tag(restaurant_tag_names, "date-night") or self._has_tag(restaurant_tag_names, "special-occasion"):
                score += 2.0
                self._append_reason(reasons, "Tagged for date-night or special-occasion dining")
            for tag in ["quiet", "cozy", "scenic", "refined", "upscale", "historic"]:
                if tag in atmosphere_text:
                    score += 0.75

        elif value == "group-dinner":
            if social_style == "group":
                score += 3.0
                self._append_reason(reasons, "Built for group dining")
            if self._has_tag(restaurant_tag_names, "group-friendly") or self._has_tag(restaurant_tag_names, "shared-plates"):
                score += 2.0
                self._append_reason(reasons, "Supports shared or group-friendly dining")

        elif value == "drinks-night":
            if restaurant.serves_alcohol:
                score += 2.0
                self._append_reason(reasons, "Supports a drink-first night out")
            for tag in ["beer", "wine", "cider", "brewery", "pub", "brewpub", "winery", "cidery", "night-out"]:
                if self._has_tag(restaurant_tag_names, tag):
                    score += 0.8

        elif value == "quick-bite":
            if pace == "fast":
                score += 3.0
                self._append_reason(reasons, "Matches a quick-bite pace")
            if self._has_tag(restaurant_tag_names, "quick-bite") or self._has_tag(restaurant_tag_names, "takeout"):
                score += 2.0
                self._append_reason(reasons, "Supports quick and convenient dining")
            if restaurant.price_tier == "$":
                score += 1.0

        elif value == "coffee-stop":
            for tag in ["coffee", "coffeehouse", "specialty-coffee", "cafe", "espresso", "study-friendly"]:
                if self._has_tag(restaurant_tag_names, tag):
                    score += 1.1
            if "coffee" in atmosphere_text or "quiet" in atmosphere_text:
                score += 0.8
            self._append_reason(reasons, "Aligned with a café or coffee-stop outing")

        elif value == "special-occasion":
            if restaurant.price_tier == "$$$":
                score += 2.5
                self._append_reason(reasons, "Fits a special-occasion price tier")
            if self._has_tag(restaurant_tag_names, "special-occasion"):
                score += 2.0
                self._append_reason(reasons, "Tagged for special occasions")
            for tag in ["refined", "scenic", "historic", "upscale"]:
                if tag in atmosphere_text:
                    score += 0.9

        elif value == "casual-bite":
            if "casual" in atmosphere_text:
                score += 2.0
                self._append_reason(reasons, "Matches a casual-bite atmosphere")
            if pace in {"fast", "moderate"}:
                score += 1.5
            if restaurant.price_tier in {"$", "$$"}:
                score += 1.0

        return score

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

            restaurant_tag_names = [tag.name.lower() for tag in restaurant.tags]
            description_text = (restaurant.description or "").lower()
            atmosphere_text = (restaurant.atmosphere or "").lower()
            social_style = (restaurant.social_style or "").lower()
            pace_value = (restaurant.pace or "").lower()

            score += self._apply_outing_type_score(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                reasons=reasons,
            )

            if budget and restaurant.price_tier == budget:
                score += 2.5
                self._append_reason(reasons, f"Matches your budget target ({budget})")

            if pace and pace_value == pace.lower():
                score += 2.25
                self._append_reason(reasons, f"Fits your preferred pace ({pace})")

            if social_context and social_style == social_context.lower():
                score += 2.5
                self._append_reason(reasons, f"Works well for your social setting ({social_context})")

            for value in atmosphere:
                lowered = value.lower()
                if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                    score += 1.6
                    self._append_reason(reasons, f"Matches the atmosphere you asked for ({value})")

            for cuisine in preferred_cuisines:
                lowered = cuisine.lower()
                if self._has_tag(restaurant_tag_names, lowered):
                    score += 1.75
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")
                elif lowered in description_text or lowered in atmosphere_text:
                    score += 1.0
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")

            if drinks_focus and restaurant.serves_alcohol:
                score += 1.75
                self._append_reason(reasons, "Supports a drink-focused outing")

            if preference is not None:
                for value in preference.atmosphere_preferences:
                    lowered = value.lower()
                    if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                        score += 1.0
                        self._append_reason(reasons, f"Matches your saved atmosphere preference ({value})")

                for value in preference.social_preferences:
                    if social_style and value.lower() in social_style:
                        score += 1.0
                        self._append_reason(reasons, f"Matches your saved social preference ({value})")

                for value in preference.cuisine_preferences:
                    lowered = value.lower()
                    if self._has_tag(restaurant_tag_names, lowered) or lowered in description_text:
                        score += 1.0
                        self._append_reason(reasons, f"Matches your saved cuisine preference ({value})")

                if preference.price_sensitivity and restaurant.price_tier == preference.price_sensitivity:
                    score += 0.75
                    self._append_reason(reasons, "Fits your saved budget preference")

            if restaurant.id in positively_rated_restaurant_ids:
                score += 1.5
                self._append_reason(reasons, "You rated this restaurant well before")

            if restaurant.id in negatively_rated_restaurant_ids:
                score -= 2.0
                self._append_reason(reasons, "Lowered because of a past low rating")

            suggested_dishes = [item.name for item in restaurant.menu_items if item.category == "dish"][:2]
            suggested_drinks = [item.name for item in restaurant.menu_items if item.category == "drink"][:2]

            if not reasons:
                reasons.append("General profile match")

            results.append(
                RecommendationItem(
                    restaurant_id=restaurant.id,
                    restaurant_name=restaurant.name,
                    score=round(score, 2),
                    reasons=reasons[:4],
                    suggested_dishes=suggested_dishes,
                    suggested_drinks=suggested_drinks,
                )
            )

        results.sort(key=lambda item: item.score, reverse=True)
        return results[:5]
