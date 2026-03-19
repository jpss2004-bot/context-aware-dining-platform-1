from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.onboarding import OnboardingRequest, OnboardingStateResponse


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

    def get_onboarding_state(self, user: User) -> OnboardingStateResponse:
        hydrated_user = self.user_repository.get_by_id(user.id)

        preference = hydrated_user.preference if hydrated_user else None
        profile = hydrated_user.profile if hydrated_user else None

        return OnboardingStateResponse(
            dietary_restrictions=list(preference.dietary_restrictions or []) if preference else [],
            cuisine_preferences=list(preference.cuisine_preferences or []) if preference else [],
            texture_preferences=list(preference.texture_preferences or []) if preference else [],
            dining_pace_preferences=list(preference.dining_pace_preferences or []) if preference else [],
            social_preferences=list(preference.social_preferences or []) if preference else [],
            drink_preferences=list(preference.drink_preferences or []) if preference else [],
            atmosphere_preferences=list(preference.atmosphere_preferences or []) if preference else [],
            favorite_dining_experiences=list(profile.favorite_dining_experiences or []) if profile else [],
            favorite_restaurants=list(profile.favorite_restaurants or []) if profile else [],
            bio=profile.bio if profile else None,
            spice_tolerance=preference.spice_tolerance if preference else None,
            price_sensitivity=preference.price_sensitivity if preference else None,
            onboarding_completed=bool(hydrated_user.onboarding_completed) if hydrated_user else False,
        )
