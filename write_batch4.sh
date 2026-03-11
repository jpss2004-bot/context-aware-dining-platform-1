#!/bin/bash

set -e

if [ ! -d "backend/app" ]; then
  echo "error: run this from inside the context-aware-dining-platform folder"
  exit 1
fi

cat > backend/app/services/__init__.py <<'PY'
# services package
PY

cat > backend/app/services/auth_service.py <<'PY'
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password, verify_password
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse


class AuthService:
    def __init__(self, db: Session):
        self.db = db
        self.user_repository = UserRepository(db)

    def register(self, payload: RegisterRequest):
        existing_user = self.user_repository.get_by_email(payload.email)
        if existing_user is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this email already exists",
            )

        user = self.user_repository.create_user(
            first_name=payload.first_name,
            last_name=payload.last_name,
            email=payload.email,
            hashed_password=hash_password(payload.password),
        )
        return user

    def login(self, payload: LoginRequest) -> TokenResponse:
        user = self.user_repository.get_by_email(payload.email)
        if user is None or not verify_password(payload.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )

        access_token = create_access_token(subject=user.email)
        return TokenResponse(access_token=access_token)
PY

cat > backend/app/services/onboarding_service.py <<'PY'
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.onboarding import OnboardingRequest


class OnboardingService:
    def __init__(self, db: Session):
        self.db = db
        self.user_repository = UserRepository(db)

    def save_onboarding(self, user: User, payload: OnboardingRequest) -> User:
        self.user_repository.upsert_preferences(
            user_id=user.id,
            dietary_restrictions=payload.dietary_restrictions,
            cuisine_preferences=payload.cuisine_preferences,
            texture_preferences=payload.texture_preferences,
            dining_pace_preferences=payload.dining_pace_preferences,
            social_preferences=payload.social_preferences,
            drink_preferences=payload.drink_preferences,
            atmosphere_preferences=payload.atmosphere_preferences,
            spice_tolerance=payload.spice_tolerance,
            price_sensitivity=payload.price_sensitivity,
        )

        self.user_repository.upsert_profile(
            user_id=user.id,
            bio=payload.bio,
            favorite_dining_experiences=payload.favorite_dining_experiences,
            favorite_restaurants=payload.favorite_restaurants,
        )

        updated_user = self.user_repository.mark_onboarding_complete(user.id)
        return updated_user
PY

cat > backend/app/services/experience_service.py <<'PY'
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.experience_repository import ExperienceRepository
from app.repositories.restaurant_repository import RestaurantRepository
from app.schemas.experience import ExperienceCreateRequest


class ExperienceService:
    def __init__(self, db: Session):
        self.db = db
        self.experience_repository = ExperienceRepository(db)
        self.restaurant_repository = RestaurantRepository(db)

    def create_experience(self, user: User, payload: ExperienceCreateRequest):
        if payload.restaurant_id is not None:
            restaurant = self.restaurant_repository.get_restaurant_by_id(payload.restaurant_id)
            if restaurant is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Restaurant not found",
                )

        menu_items = self.restaurant_repository.get_menu_items_by_ids(payload.menu_item_ids)

        return self.experience_repository.create_experience(
            user_id=user.id,
            restaurant_id=payload.restaurant_id,
            title=payload.title,
            occasion=payload.occasion,
            social_context=payload.social_context,
            notes=payload.notes,
            overall_rating=payload.overall_rating,
            menu_items=menu_items,
            ratings=[rating.model_dump() for rating in payload.ratings],
        )

    def list_user_experiences(self, user: User):
        return self.experience_repository.list_by_user_id(user.id)
PY

cat > backend/app/services/recommendation_service.py <<'PY'
from app.models.restaurant import MenuItem, Restaurant
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
        outing_type: str | None,
        mood: str | None,
        budget: str | None,
        pace: str | None,
        social_context: str | None,
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
            menu_item_names = [item.name for item in restaurant.menu_items]

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
PY

cat > backend/app/api/routes/auth.py <<'PY'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.auth import AuthUserResponse, LoginRequest, RegisterRequest, TokenResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/register", response_model=AuthUserResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    return AuthService(db).register(payload)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    return AuthService(db).login(payload)


@router.get("/me", response_model=AuthUserResponse)
def get_me(current_user=Depends(get_current_user)):
    return current_user
PY

cat > backend/app/api/routes/onboarding.py <<'PY'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.onboarding import OnboardingRequest, OnboardingResponse
from app.services.onboarding_service import OnboardingService

router = APIRouter()


@router.post("", response_model=OnboardingResponse)
def submit_onboarding(
    payload: OnboardingRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    updated_user = OnboardingService(db).save_onboarding(current_user, payload)
    return OnboardingResponse(
        message="Onboarding saved successfully",
        onboarding_completed=updated_user.onboarding_completed,
    )
PY

cat > backend/app/api/routes/users.py <<'PY'
from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.user import UserResponse

router = APIRouter()


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user=Depends(get_current_user)):
    return current_user
PY

echo "batch 4 files written successfully"
