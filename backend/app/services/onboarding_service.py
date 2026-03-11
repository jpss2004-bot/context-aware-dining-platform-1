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
