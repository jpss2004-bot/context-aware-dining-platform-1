#!/bin/bash
set -euo pipefail

PATCH_NAME="patch5_onboarding_account_hardening"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Creating backup at: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

FILES_TO_BACKUP=(
  "app/schemas/onboarding.py"
  "app/services/onboarding_catalog.py"
  "app/services/onboarding_service.py"
  "app/repositories/user_repository.py"
  "app/api/routes/users.py"
)

for file in "${FILES_TO_BACKUP[@]}"; do
  if [ -f "$file" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$file")"
    cp "$file" "${BACKUP_DIR}/$file"
  fi
done

mkdir -p app/schemas app/services app/api/routes app/repositories

cat > app/schemas/onboarding.py <<'PY'
from typing import Optional

from pydantic import BaseModel, Field, field_validator, model_validator


def _normalize_string_list(values: list[str]) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()

    for value in values or []:
        normalized = " ".join(str(value).strip().split())
        lowered = normalized.lower()
        if not normalized or lowered in seen:
            continue
        cleaned.append(normalized)
        seen.add(lowered)

    return cleaned


class OnboardingOptionValue(BaseModel):
    value: str
    label: str
    description: Optional[str] = None


class OnboardingFieldDefinition(BaseModel):
    key: str
    label: str
    description: str
    help_text: Optional[str] = None
    select_mode: str
    optional: bool
    allow_skip: bool
    ui_control: str
    step_order: int
    options: list[OnboardingOptionValue] = Field(default_factory=list)


class OnboardingOptionsResponse(BaseModel):
    version: str
    fields: list[OnboardingFieldDefinition] = Field(default_factory=list)


class OnboardingRequest(BaseModel):
    dietary_restrictions: list[str] = Field(default_factory=list)
    cuisine_preferences: list[str] = Field(default_factory=list)
    texture_preferences: list[str] = Field(default_factory=list)
    dining_pace_preferences: list[str] = Field(default_factory=list)
    social_preferences: list[str] = Field(default_factory=list)
    drink_preferences: list[str] = Field(default_factory=list)
    atmosphere_preferences: list[str] = Field(default_factory=list)
    favorite_dining_experiences: list[str] = Field(default_factory=list)
    favorite_restaurants: list[str] = Field(default_factory=list)
    bio: Optional[str] = None
    spice_tolerance: Optional[str] = None
    price_sensitivity: Optional[str] = None
    budget_min_per_person: Optional[float] = None
    budget_max_per_person: Optional[float] = None
    onboarding_version: Optional[str] = None

    @field_validator(
        "dietary_restrictions",
        "cuisine_preferences",
        "texture_preferences",
        "dining_pace_preferences",
        "social_preferences",
        "drink_preferences",
        "atmosphere_preferences",
        "favorite_dining_experiences",
        "favorite_restaurants",
        mode="before",
    )
    @classmethod
    def normalize_list_fields(cls, value):
        if value is None:
            return []
        if not isinstance(value, list):
            return []
        return _normalize_string_list(value)

    @field_validator("bio", "spice_tolerance", "price_sensitivity", "onboarding_version", mode="before")
    @classmethod
    def normalize_optional_strings(cls, value):
        if value is None:
            return None
        normalized = " ".join(str(value).strip().split())
        return normalized or None

    @model_validator(mode="after")
    def validate_budget_range(self):
        if self.budget_min_per_person is not None and self.budget_min_per_person < 0:
            raise ValueError("budget_min_per_person cannot be negative")
        if self.budget_max_per_person is not None and self.budget_max_per_person < 0:
            raise ValueError("budget_max_per_person cannot be negative")
        if (
            self.budget_min_per_person is not None
            and self.budget_max_per_person is not None
            and self.budget_min_per_person > self.budget_max_per_person
        ):
            raise ValueError("budget_min_per_person cannot be greater than budget_max_per_person")
        return self


class OnboardingResponse(BaseModel):
    message: str
    onboarding_completed: bool


class OnboardingStateResponse(BaseModel):
    dietary_restrictions: list[str] = Field(default_factory=list)
    cuisine_preferences: list[str] = Field(default_factory=list)
    texture_preferences: list[str] = Field(default_factory=list)
    dining_pace_preferences: list[str] = Field(default_factory=list)
    social_preferences: list[str] = Field(default_factory=list)
    drink_preferences: list[str] = Field(default_factory=list)
    atmosphere_preferences: list[str] = Field(default_factory=list)
    favorite_dining_experiences: list[str] = Field(default_factory=list)
    favorite_restaurants: list[str] = Field(default_factory=list)
    bio: Optional[str] = None
    spice_tolerance: Optional[str] = None
    price_sensitivity: Optional[str] = None
    budget_min_per_person: Optional[float] = None
    budget_max_per_person: Optional[float] = None
    onboarding_version: Optional[str] = None
    onboarding_completed: bool = False
PY

cat > app/services/onboarding_catalog.py <<'PY'
from app.schemas.onboarding import (
    OnboardingFieldDefinition,
    OnboardingOptionValue,
    OnboardingOptionsResponse,
)


ONBOARDING_OPTIONS = OnboardingOptionsResponse(
    version="v3-ux-ready",
    fields=[
        OnboardingFieldDefinition(
            key="cuisine_preferences",
            label="Cuisine preferences",
            description="Choose cuisines you usually enjoy so recommendations can start from familiar options.",
            help_text="This helps the system prioritize the food styles you already like.",
            select_mode="multi",
            optional=False,
            allow_skip=False,
            ui_control="chips",
            step_order=1,
            options=[
                OnboardingOptionValue(value="italian", label="Italian"),
                OnboardingOptionValue(value="japanese", label="Japanese"),
                OnboardingOptionValue(value="canadian", label="Canadian"),
                OnboardingOptionValue(value="seafood", label="Seafood"),
                OnboardingOptionValue(value="mexican", label="Mexican"),
                OnboardingOptionValue(value="cafe", label="Cafe / Bakery"),
                OnboardingOptionValue(value="pub fare", label="Pub fare"),
                OnboardingOptionValue(value="fast food", label="Fast food"),
            ],
        ),
        OnboardingFieldDefinition(
            key="atmosphere_preferences",
            label="Atmosphere preferences",
            description="Pick the kinds of dining environments you naturally gravitate toward.",
            help_text="These options help match the overall feel of a venue, not just the food.",
            select_mode="multi",
            optional=True,
            allow_skip=True,
            ui_control="chips",
            step_order=2,
            options=[
                OnboardingOptionValue(value="cozy", label="Cozy"),
                OnboardingOptionValue(value="romantic", label="Date night"),
                OnboardingOptionValue(value="casual", label="Casual"),
                OnboardingOptionValue(value="upscale", label="Upscale"),
                OnboardingOptionValue(value="family friendly", label="Family friendly"),
                OnboardingOptionValue(
                    value="live music",
                    label="Live music",
                    description="Select this when live performances matter to the experience.",
                ),
                OnboardingOptionValue(
                    value="trivia",
                    label="Trivia night",
                    description="Select this when recurring trivia events matter to the experience.",
                ),
            ],
        ),
        OnboardingFieldDefinition(
            key="dining_pace_preferences",
            label="Dining pace",
            description="Choose whether you usually want a quick stop, a balanced meal, or a slower experience.",
            help_text="This helps distinguish a quick bite from a slow sit-down meal.",
            select_mode="multi",
            optional=True,
            allow_skip=True,
            ui_control="chips",
            step_order=3,
            options=[
                OnboardingOptionValue(value="quick", label="Quick bite"),
                OnboardingOptionValue(value="steady", label="Balanced pace"),
                OnboardingOptionValue(value="slow", label="Slow experience"),
            ],
        ),
        OnboardingFieldDefinition(
            key="social_preferences",
            label="Who you usually dine with",
            description="This helps rank places better for solo meals, dates, families, and group outings.",
            help_text="Choose the social contexts that matter most often for your decisions.",
            select_mode="multi",
            optional=True,
            allow_skip=True,
            ui_control="chips",
            step_order=4,
            options=[
                OnboardingOptionValue(value="solo", label="Solo"),
                OnboardingOptionValue(value="date", label="Date night"),
                OnboardingOptionValue(value="friends", label="Friends / group outing"),
                OnboardingOptionValue(value="family", label="Family"),
                OnboardingOptionValue(value="students", label="Students / budget-conscious"),
            ],
        ),
        OnboardingFieldDefinition(
            key="drink_preferences",
            label="Drink preferences",
            description="Choose drink categories that matter during recommendations.",
            help_text="Useful when the outing is more coffee-focused, cocktail-focused, or drinks-led.",
            select_mode="multi",
            optional=True,
            allow_skip=True,
            ui_control="chips",
            step_order=5,
            options=[
                OnboardingOptionValue(value="coffee", label="Coffee"),
                OnboardingOptionValue(value="mocktails", label="Mocktails"),
                OnboardingOptionValue(value="cocktails", label="Cocktails"),
                OnboardingOptionValue(value="wine", label="Wine"),
                OnboardingOptionValue(value="beer", label="Beer"),
            ],
        ),
        OnboardingFieldDefinition(
            key="dietary_restrictions",
            label="Dietary restrictions",
            description="Only choose restrictions that should actively filter recommendations.",
            help_text="This step is optional. Leave it empty if nothing should restrict your results.",
            select_mode="multi",
            optional=True,
            allow_skip=True,
            ui_control="chips",
            step_order=6,
            options=[
                OnboardingOptionValue(value="vegetarian", label="Vegetarian"),
                OnboardingOptionValue(value="vegan", label="Vegan"),
                OnboardingOptionValue(value="gluten free", label="Gluten free"),
                OnboardingOptionValue(value="dairy free", label="Dairy free"),
                OnboardingOptionValue(value="halal", label="Halal"),
                OnboardingOptionValue(value="nut aware", label="Nut aware"),
            ],
        ),
        OnboardingFieldDefinition(
            key="price_sensitivity",
            label="Budget comfort",
            description="Pick the overall budget feel that suits you most often.",
            help_text="This is the general budget style you are most comfortable with.",
            select_mode="single",
            optional=True,
            allow_skip=True,
            ui_control="radio",
            step_order=7,
            options=[
                OnboardingOptionValue(
                    value="budget",
                    label="Budget-conscious",
                    description="Usually looking for lower-cost options.",
                ),
                OnboardingOptionValue(
                    value="balanced",
                    label="Balanced",
                    description="Comfortable with moderate prices.",
                ),
                OnboardingOptionValue(
                    value="premium",
                    label="Premium",
                    description="Comfortable paying more for the right experience.",
                ),
            ],
        ),
        OnboardingFieldDefinition(
            key="budget_range",
            label="Numeric budget range",
            description="A frontend can capture this as min/max spend per person in dollars.",
            help_text="Useful for users who want more precise budget control than a simple label.",
            select_mode="range",
            optional=True,
            allow_skip=True,
            ui_control="range",
            step_order=8,
            options=[],
        ),
    ],
)


def get_onboarding_options() -> OnboardingOptionsResponse:
    return ONBOARDING_OPTIONS
PY

cat > app/services/onboarding_service.py <<'PY'
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.onboarding import OnboardingRequest, OnboardingStateResponse
from app.services.onboarding_catalog import get_onboarding_options


def _clean_list(values: list[str]) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()

    for value in values or []:
        normalized = " ".join(str(value).strip().split())
        lowered = normalized.lower()
        if not normalized or lowered in seen:
            continue
        cleaned.append(normalized)
        seen.add(lowered)

    return cleaned


class OnboardingService:
    def __init__(self, db: Session):
        self.db = db
        self.user_repository = UserRepository(db)

    def save_onboarding(self, user: User, payload: OnboardingRequest) -> User:
        self.user_repository.upsert_preferences(
            user_id=user.id,
            dietary_restrictions=_clean_list(payload.dietary_restrictions),
            cuisine_preferences=_clean_list(payload.cuisine_preferences),
            texture_preferences=_clean_list(payload.texture_preferences),
            dining_pace_preferences=_clean_list(payload.dining_pace_preferences),
            social_preferences=_clean_list(payload.social_preferences),
            drink_preferences=_clean_list(payload.drink_preferences),
            atmosphere_preferences=_clean_list(payload.atmosphere_preferences),
            spice_tolerance=payload.spice_tolerance,
            price_sensitivity=payload.price_sensitivity,
            budget_min_per_person=payload.budget_min_per_person,
            budget_max_per_person=payload.budget_max_per_person,
            onboarding_version=payload.onboarding_version,
        )

        self.user_repository.upsert_profile(
            user_id=user.id,
            bio=payload.bio,
            favorite_dining_experiences=_clean_list(payload.favorite_dining_experiences),
            favorite_restaurants=_clean_list(payload.favorite_restaurants),
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
            budget_min_per_person=preference.budget_min_per_person if preference else None,
            budget_max_per_person=preference.budget_max_per_person if preference else None,
            onboarding_version=preference.onboarding_version if preference else None,
            onboarding_completed=bool(hydrated_user.onboarding_completed) if hydrated_user else False,
        )

    def get_onboarding_options(self):
        return get_onboarding_options()
PY

cat > app/repositories/user_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.user import User, UserPreference, UserProfile


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def _base_user_query(self):
        return self.db.query(User).options(
            joinedload(User.profile),
            joinedload(User.preference),
            joinedload(User.presets),
        )

    def get_by_email(self, email: str):
        return self._base_user_query().filter(User.email == email.lower()).first()

    def get_by_id(self, user_id: int):
        return self._base_user_query().filter(User.id == user_id).first()

    def create_user(self, first_name: str, last_name: str, email: str, hashed_password: str):
        user = User(
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            email=email.lower().strip(),
            hashed_password=hashed_password,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def upsert_preferences(
        self,
        user_id: int,
        dietary_restrictions: list[str],
        cuisine_preferences: list[str],
        texture_preferences: list[str],
        dining_pace_preferences: list[str],
        social_preferences: list[str],
        drink_preferences: list[str],
        atmosphere_preferences: list[str],
        spice_tolerance: str = None,
        price_sensitivity: str = None,
        budget_min_per_person: float = None,
        budget_max_per_person: float = None,
        onboarding_version: str = None,
    ):
        preference = self.db.query(UserPreference).filter(UserPreference.user_id == user_id).first()

        if preference is None:
            preference = UserPreference(user_id=user_id)
            self.db.add(preference)

        preference.dietary_restrictions = dietary_restrictions
        preference.cuisine_preferences = cuisine_preferences
        preference.texture_preferences = texture_preferences
        preference.dining_pace_preferences = dining_pace_preferences
        preference.social_preferences = social_preferences
        preference.drink_preferences = drink_preferences
        preference.atmosphere_preferences = atmosphere_preferences
        preference.spice_tolerance = spice_tolerance
        preference.price_sensitivity = price_sensitivity
        preference.budget_min_per_person = budget_min_per_person
        preference.budget_max_per_person = budget_max_per_person
        preference.onboarding_version = onboarding_version

        self.db.commit()
        self.db.refresh(preference)
        return preference

    def upsert_profile(
        self,
        user_id: int,
        bio: str = None,
        favorite_dining_experiences: list[str] = None,
        favorite_restaurants: list[str] = None,
    ):
        profile = self.db.query(UserProfile).filter(UserProfile.user_id == user_id).first()

        if profile is None:
            profile = UserProfile(user_id=user_id)
            self.db.add(profile)

        profile.bio = bio
        profile.favorite_dining_experiences = favorite_dining_experiences or []
        profile.favorite_restaurants = favorite_restaurants or []

        self.db.commit()
        self.db.refresh(profile)
        return profile

    def mark_onboarding_complete(self, user_id: int):
        user = self.db.query(User).filter(User.id == user_id).first()
        if user is None:
            return None

        user.onboarding_completed = True
        self.db.commit()
        self.db.refresh(user)
        return user
PY

cat > app/schemas/account.py <<'PY'
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class DashboardUserSummary(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    is_active: bool
    onboarding_completed: bool
    created_at: datetime


class DashboardProfileSummary(BaseModel):
    bio: Optional[str] = None
    favorite_dining_experiences: list[str] = Field(default_factory=list)
    favorite_restaurants: list[str] = Field(default_factory=list)


class DashboardPreferenceSummary(BaseModel):
    dietary_restrictions: list[str] = Field(default_factory=list)
    cuisine_preferences: list[str] = Field(default_factory=list)
    texture_preferences: list[str] = Field(default_factory=list)
    dining_pace_preferences: list[str] = Field(default_factory=list)
    social_preferences: list[str] = Field(default_factory=list)
    drink_preferences: list[str] = Field(default_factory=list)
    atmosphere_preferences: list[str] = Field(default_factory=list)
    spice_tolerance: Optional[str] = None
    price_sensitivity: Optional[str] = None
    budget_min_per_person: Optional[float] = None
    budget_max_per_person: Optional[float] = None
    onboarding_version: Optional[str] = None


class DashboardPresetSummary(BaseModel):
    preset_id: str
    name: str
    description: Optional[str] = None
    updated_at: datetime


class DashboardExperienceSummary(BaseModel):
    experience_id: int
    title: Optional[str] = None
    restaurant_name: Optional[str] = None
    overall_rating: Optional[float] = None
    created_at: datetime


class SavedContentResponse(BaseModel):
    favorite_restaurants: list[str] = Field(default_factory=list)
    favorite_dining_experiences: list[str] = Field(default_factory=list)
    user_presets: list[DashboardPresetSummary] = Field(default_factory=list)
    recent_experiences: list[DashboardExperienceSummary] = Field(default_factory=list)


class UserDashboardResponse(BaseModel):
    user: DashboardUserSummary
    profile: DashboardProfileSummary
    preferences: DashboardPreferenceSummary
    saved_content: SavedContentResponse
    counts: dict[str, int] = Field(default_factory=dict)
PY

cat > app/services/account_service.py <<'PY'
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
PY

cat > app/api/routes/users.py <<'PY'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.account import SavedContentResponse, UserDashboardResponse
from app.schemas.user import UserResponse
from app.services.account_service import AccountService

router = APIRouter()


@router.get("/me/dashboard", response_model=UserDashboardResponse)
def get_current_user_dashboard(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return AccountService(db).get_dashboard(current_user)


@router.get("/me/saved-content", response_model=SavedContentResponse)
def get_current_user_saved_content(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return AccountService(db).get_saved_content(current_user)


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user=Depends(get_current_user)):
    return current_user
PY

PYTHON_BIN="python3"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi

echo "Using Python: ${PYTHON_BIN}"
PYTHONPATH=. "${PYTHON_BIN}" -m compileall app

echo "Running import smoke tests..."
PYTHONPATH=. "${PYTHON_BIN}" - <<'PY'
from app.services.account_service import AccountService
from app.schemas.account import UserDashboardResponse, SavedContentResponse
from app.api.routes.users import router as users_router
from app.schemas.onboarding import OnboardingRequest
from app.services.onboarding_catalog import get_onboarding_options

print("AccountService import OK")
print("account schemas import OK")
print("users route import OK")
print("OnboardingRequest import OK")
print("onboarding options version =", get_onboarding_options().version)

sample = OnboardingRequest(
    cuisine_preferences=[" Pizza ", "pizza", "Fast Food"],
    dietary_restrictions=["", "Gluten Free", "gluten free"],
    budget_min_per_person=10,
    budget_max_per_person=25,
)
print("normalized cuisines =", sample.cuisine_preferences)
print("normalized dietary =", sample.dietary_restrictions)
PY

echo "Patch 5 complete."
echo "Backup saved at: ${BACKUP_DIR}"
