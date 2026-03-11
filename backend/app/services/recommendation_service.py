from typing import Optional

from app.models.restaurant import Restaurant
from app.models.user import User
from app.repositories.restaurant_repository import RestaurantRepository
from app.repositories.experience_repository import ExperienceRepository
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
            social_context = "romantic"

        atmosphere = []
        for word in ["cozy", "lively", "quiet", "romantic", "casual"]:
            if word in text:
                atmosphere.append(word)

        preferred_cuisines = []
        for word in ["italian", "pasta", "cocktails", "comfort", "quick"]:
            if word in text:
                preferred_cuisines.append(word)

        drinks_focus = any(word in text for word in ["drink", "drinks", "cocktail", "cocktails", "bar"])

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

            if budget and restaurant.price_tier == budget:
                score += 2.0
                reasons.append(f"Matches your budget target ({budget})")

            if pace and restaurant.pace and restaurant.pace.lower() == pace.lower():
                score += 2.0
                reasons.append(f"Fits your preferred pace ({pace})")

            if social_context and restaurant.social_style and restaurant.social_style.lower() == social_context.lower():
                score += 2.5
                reasons.append(f"Works well for your social setting ({social_context})")

            for value in atmosphere:
                if restaurant.atmosphere and value.lower() in restaurant.atmosphere.lower():
                    score += 1.5
                    reasons.append(f"Matches the atmosphere you asked for ({value})")

            for cuisine in preferred_cuisines:
                if cuisine.lower() in restaurant_tag_names or cuisine.lower() in (restaurant.description or "").lower():
                    score += 1.5
                    reasons.append(f"Aligns with your food or drink interest ({cuisine})")

            if drinks_focus and restaurant.serves_alcohol:
                score += 1.5
                reasons.append("Supports a drink-focused outing")

            if preference is not None:
                for value in preference.atmosphere_preferences:
                    if restaurant.atmosphere and value.lower() in restaurant.atmosphere.lower():
                        score += 1.0
                        reasons.append(f"Matches your saved atmosphere preference ({value})")

                for value in preference.social_preferences:
                    if restaurant.social_style and value.lower() in restaurant.social_style.lower():
                        score += 1.0
                        reasons.append(f"Matches your saved social preference ({value})")

                for value in preference.cuisine_preferences:
                    if value.lower() in restaurant_tag_names or value.lower() in (restaurant.description or "").lower():
                        score += 1.0
                        reasons.append(f"Matches your saved cuisine preference ({value})")

                if preference.price_sensitivity and restaurant.price_tier == preference.price_sensitivity:
                    score += 0.75
                    reasons.append("Fits your saved budget preference")

            if restaurant.id in positively_rated_restaurant_ids:
                score += 1.5
                reasons.append("You rated this restaurant well before")

            if restaurant.id in negatively_rated_restaurant_ids:
                score -= 2.0
                reasons.append("Lowered because of a past low rating")

            suggested_dishes = [
                item.name for item in restaurant.menu_items
                if item.category == "dish"
            ][:2]

            suggested_drinks = [
                item.name for item in restaurant.menu_items
                if item.category == "drink"
            ][:2]

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
