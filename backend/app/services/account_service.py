from app.repositories.experience_repository import ExperienceRepository
from app.repositories.user_repository import UserRepository
from app.schemas.account import (
    DashboardExperienceSummary,
    DashboardPreferenceSummary,
    DashboardPresetSummary,
    DashboardProfileSummary,
    DashboardUserSummary,
    SavedContentResponse,
    UserDashboardResponse,
)


class AccountService:
    def __init__(self, db):
        self.user_repository = UserRepository(db)
        self.experience_repository = ExperienceRepository(db)

    def _build_saved_content(self, user) -> SavedContentResponse:
        hydrated_user = self.user_repository.get_by_id(user.id)
        profile = hydrated_user.profile if hydrated_user else None
        presets = sorted(
            list(hydrated_user.presets or []) if hydrated_user else [],
            key=lambda item: (item.updated_at, item.id),
            reverse=True,
        )
        experiences = self.experience_repository.list_by_user_id(user.id)[:5]

        preset_items = [
            DashboardPresetSummary(
                preset_id=f"user:{preset.id}",
                name=preset.name,
                description=preset.description,
                updated_at=preset.updated_at,
            )
            for preset in presets
        ]

        experience_items = [
            DashboardExperienceSummary(
                experience_id=experience.id,
                title=experience.title,
                restaurant_name=experience.restaurant.name if getattr(experience, "restaurant", None) else None,
                overall_rating=float(experience.overall_rating) if experience.overall_rating is not None else None,
                created_at=experience.created_at,
            )
            for experience in experiences
        ]

        return SavedContentResponse(
            favorite_restaurants=list(profile.favorite_restaurants or []) if profile else [],
            favorite_dining_experiences=list(profile.favorite_dining_experiences or []) if profile else [],
            user_presets=preset_items,
            recent_experiences=experience_items,
        )

    def get_dashboard(self, user) -> UserDashboardResponse:
        hydrated_user = self.user_repository.get_by_id(user.id)
        profile = hydrated_user.profile if hydrated_user else None
        preference = hydrated_user.preference if hydrated_user else None
        saved_content = self._build_saved_content(user)

        return UserDashboardResponse(
            user=DashboardUserSummary(
                id=hydrated_user.id,
                first_name=hydrated_user.first_name,
                last_name=hydrated_user.last_name,
                email=hydrated_user.email,
                is_active=hydrated_user.is_active,
                onboarding_completed=hydrated_user.onboarding_completed,
                created_at=hydrated_user.created_at,
            ),
            profile=DashboardProfileSummary(
                bio=profile.bio if profile else None,
                favorite_dining_experiences=list(profile.favorite_dining_experiences or []) if profile else [],
                favorite_restaurants=list(profile.favorite_restaurants or []) if profile else [],
            ),
            preferences=DashboardPreferenceSummary(
                dietary_restrictions=list(preference.dietary_restrictions or []) if preference else [],
                cuisine_preferences=list(preference.cuisine_preferences or []) if preference else [],
                texture_preferences=list(preference.texture_preferences or []) if preference else [],
                dining_pace_preferences=list(preference.dining_pace_preferences or []) if preference else [],
                social_preferences=list(preference.social_preferences or []) if preference else [],
                drink_preferences=list(preference.drink_preferences or []) if preference else [],
                atmosphere_preferences=list(preference.atmosphere_preferences or []) if preference else [],
                spice_tolerance=preference.spice_tolerance if preference else None,
                price_sensitivity=preference.price_sensitivity if preference else None,
                budget_min_per_person=preference.budget_min_per_person if preference else None,
                budget_max_per_person=preference.budget_max_per_person if preference else None,
                onboarding_version=preference.onboarding_version if preference else None,
            ),
            saved_content=saved_content,
            counts={
                "favorite_restaurants": len(saved_content.favorite_restaurants),
                "favorite_dining_experiences": len(saved_content.favorite_dining_experiences),
                "user_presets": len(saved_content.user_presets),
                "recent_experiences": len(saved_content.recent_experiences),
            },
        )

    def get_saved_content(self, user) -> SavedContentResponse:
        return self._build_saved_content(user)
