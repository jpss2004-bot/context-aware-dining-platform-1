#!/bin/bash
set -euo pipefail

PATCH_NAME="patch4_presets_builder_support"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Creating backup at: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

FILES_TO_BACKUP=(
  "app/models/user.py"
  "app/models/__init__.py"
  "app/api/router.py"
  "app/db/init_db.py"
  "app/schemas/recommendation.py"
  "app/services/recommendation_service.py"
)

for file in "${FILES_TO_BACKUP[@]}"; do
  if [ -f "$file" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$file")"
    cp "$file" "${BACKUP_DIR}/$file"
  fi
done

mkdir -p app/models app/schemas app/repositories app/services app/api/routes

cat > app/models/preset.py <<'PY'
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class UserPreset(Base):
    __tablename__ = "user_presets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    selection_payload: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="presets")
PY

cat > app/models/user.py <<'PY'
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    profile: Mapped[Optional["UserProfile"]] = relationship(
        "UserProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    preference: Mapped[Optional["UserPreference"]] = relationship(
        "UserPreference",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    experiences: Mapped[list["Experience"]] = relationship(
        "Experience",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    presets: Mapped[list["UserPreset"]] = relationship(
        "UserPreset",
        back_populates="user",
        cascade="all, delete-orphan",
    )


class UserProfile(Base):
    __tablename__ = "profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    bio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    favorite_dining_experiences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    favorite_restaurants: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="profile")


class UserPreference(Base):
    __tablename__ = "preferences"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)

    dietary_restrictions: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    cuisine_preferences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    texture_preferences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    dining_pace_preferences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    social_preferences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    drink_preferences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    atmosphere_preferences: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    spice_tolerance: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    price_sensitivity: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    budget_min_per_person: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    budget_max_per_person: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    onboarding_version: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="preference")


from app.models.experience import Experience  # noqa: E402
from app.models.preset import UserPreset  # noqa: E402
PY

cat > app/models/__init__.py <<'PY'
from app.models.experience import Experience, ExperienceRating
from app.models.preset import UserPreset
from app.models.restaurant import MenuItem, Restaurant, Tag
from app.models.user import User, UserPreference, UserProfile

__all__ = [
    "User",
    "UserProfile",
    "UserPreference",
    "UserPreset",
    "Restaurant",
    "MenuItem",
    "Tag",
    "Experience",
    "ExperienceRating",
]
PY

cat > app/schemas/preset.py <<'PY'
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class PresetSelectionPayload(BaseModel):
    outing_type: Optional[str] = None
    mood: Optional[str] = None
    budget: Optional[str] = None
    pace: Optional[str] = None
    social_context: Optional[str] = None
    preferred_cuisines: list[str] = Field(default_factory=list)
    drinks_focus: Optional[bool] = None
    atmosphere: list[str] = Field(default_factory=list)

    towns: list[str] = Field(default_factory=list)
    include_tags: list[str] = Field(default_factory=list)
    exclude_tags: list[str] = Field(default_factory=list)
    family_friendly: Optional[bool] = None
    student_friendly: Optional[bool] = None
    date_night: Optional[bool] = None
    quick_bite: Optional[bool] = None
    fast_food: Optional[bool] = None
    requires_dine_in: Optional[bool] = None
    requires_takeout: Optional[bool] = None
    requires_delivery: Optional[bool] = None
    requires_reservations: Optional[bool] = None
    requires_live_music: Optional[bool] = None
    requires_trivia: Optional[bool] = None
    include_dish_hints: Optional[bool] = None


class PresetResponse(BaseModel):
    preset_id: str
    owner_type: str
    owner_user_id: Optional[int] = None
    is_editable: bool
    name: str
    description: Optional[str] = None
    selection_payload: PresetSelectionPayload
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class CreateUserPresetRequest(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    description: Optional[str] = Field(default=None, max_length=500)
    selection_payload: PresetSelectionPayload


class UpdateUserPresetRequest(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=150)
    description: Optional[str] = Field(default=None, max_length=500)
    selection_payload: Optional[PresetSelectionPayload] = None


class PresetApplyResponse(BaseModel):
    preset: PresetResponse
    builder_payload: PresetSelectionPayload
    banner_message: str
    can_customize: bool = True


class PresetDeleteResponse(BaseModel):
    message: str
    deleted_preset_id: str
PY

cat > app/schemas/recommendation.py <<'PY'
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

    towns: list[str] = Field(default_factory=list)
    include_tags: list[str] = Field(default_factory=list)
    exclude_tags: list[str] = Field(default_factory=list)
    family_friendly: Optional[bool] = None
    student_friendly: Optional[bool] = None
    date_night: Optional[bool] = None
    quick_bite: Optional[bool] = None
    fast_food: Optional[bool] = None
    requires_dine_in: Optional[bool] = None
    requires_takeout: Optional[bool] = None
    requires_delivery: Optional[bool] = None
    requires_reservations: Optional[bool] = None
    requires_live_music: Optional[bool] = None
    requires_trivia: Optional[bool] = None
    include_dish_hints: bool = True

    preset_id: Optional[str] = None
    use_preset_defaults: bool = True


class DescribeYourNightRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=1000)


class SurpriseMeRequest(BaseModel):
    include_drinks: bool = False
    exclude_restaurant_ids: list[int] = Field(default_factory=list)
    count: int = Field(default=5, ge=1, le=5)


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

    towns: list[str] = Field(default_factory=list)
    include_tags: list[str] = Field(default_factory=list)
    exclude_tags: list[str] = Field(default_factory=list)
    family_friendly: Optional[bool] = None
    student_friendly: Optional[bool] = None
    date_night: Optional[bool] = None
    quick_bite: Optional[bool] = None
    fast_food: Optional[bool] = None
    requires_dine_in: Optional[bool] = None
    requires_takeout: Optional[bool] = None
    requires_delivery: Optional[bool] = None
    requires_reservations: Optional[bool] = None
    requires_live_music: Optional[bool] = None
    requires_trivia: Optional[bool] = None

    preset_id: Optional[str] = None


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
    engine_version: str = "phase4-presets-v1"
    generated_at: str
    request_summary: RecommendationRequestSummary
    results: list[RecommendationItem]
PY

cat > app/repositories/preset_repository.py <<'PY'
from sqlalchemy.orm import Session

from app.models.preset import UserPreset


class PresetRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_user_presets(self, user_id: int) -> list[UserPreset]:
        return (
            self.db.query(UserPreset)
            .filter(UserPreset.user_id == user_id)
            .order_by(UserPreset.updated_at.desc(), UserPreset.id.desc())
            .all()
        )

    def get_user_preset(self, user_id: int, preset_id: int):
        return (
            self.db.query(UserPreset)
            .filter(UserPreset.user_id == user_id, UserPreset.id == preset_id)
            .first()
        )

    def create_user_preset(self, user_id: int, name: str, description: str | None, selection_payload: dict) -> UserPreset:
        preset = UserPreset(
            user_id=user_id,
            name=name.strip(),
            description=description.strip() if description else None,
            selection_payload=selection_payload,
        )
        self.db.add(preset)
        self.db.commit()
        self.db.refresh(preset)
        return preset

    def update_user_preset(
        self,
        preset: UserPreset,
        name: str | None = None,
        description: str | None = None,
        selection_payload: dict | None = None,
    ) -> UserPreset:
        if name is not None:
            preset.name = name.strip()
        if description is not None:
            preset.description = description.strip() if description else None
        if selection_payload is not None:
            preset.selection_payload = selection_payload

        self.db.commit()
        self.db.refresh(preset)
        return preset

    def delete_user_preset(self, preset: UserPreset) -> None:
        self.db.delete(preset)
        self.db.commit()
PY

cat > app/services/preset_catalog.py <<'PY'
from app.schemas.preset import PresetResponse, PresetSelectionPayload


SYSTEM_PRESETS: list[PresetResponse] = [
    PresetResponse(
        preset_id="system:student-quick-bite",
        owner_type="system",
        is_editable=False,
        name="Student Quick Bite",
        description="Fast, casual, budget-conscious preset built for quick meals and takeout-friendly options.",
        selection_payload=PresetSelectionPayload(
            outing_type="quick-bite",
            budget="$",
            pace="fast",
            social_context="friends",
            preferred_cuisines=["pizza", "fast food"],
            atmosphere=["casual"],
            student_friendly=True,
            quick_bite=True,
            requires_takeout=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:date-night",
        owner_type="system",
        is_editable=False,
        name="Date Night",
        description="Preset for slower, more polished dining with stronger date-night signals.",
        selection_payload=PresetSelectionPayload(
            outing_type="date-night",
            budget="$$$",
            pace="leisurely",
            social_context="date",
            atmosphere=["cozy", "refined", "scenic"],
            date_night=True,
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:group-drinks",
        owner_type="system",
        is_editable=False,
        name="Group Drinks",
        description="Preset for breweries, pubs, and social venues suited to a drinks-forward group outing.",
        selection_payload=PresetSelectionPayload(
            outing_type="drinks-night",
            budget="$$",
            social_context="group",
            preferred_cuisines=["beer", "wine", "cider", "pub"],
            drinks_focus=True,
            atmosphere=["lively", "casual"],
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:coffee-catchup",
        owner_type="system",
        is_editable=False,
        name="Coffee Catch-Up",
        description="Preset for cafés, coffeehouses, and relaxed daytime stops.",
        selection_payload=PresetSelectionPayload(
            outing_type="coffee-stop",
            budget="$",
            pace="slow",
            social_context="friends",
            preferred_cuisines=["coffee", "bakery", "dessert"],
            atmosphere=["cozy", "casual"],
            include_tags=["coffee"],
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:family-dinner",
        owner_type="system",
        is_editable=False,
        name="Family Dinner",
        description="Preset for family-friendly restaurants with broader appeal and easier logistics.",
        selection_payload=PresetSelectionPayload(
            outing_type="family-dining",
            budget="$$",
            pace="moderate",
            social_context="family",
            atmosphere=["casual", "family friendly"],
            family_friendly=True,
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:scenic-special-occasion",
        owner_type="system",
        is_editable=False,
        name="Scenic Special Occasion",
        description="Preset for more premium, reservation-friendly outings with scenic or refined qualities.",
        selection_payload=PresetSelectionPayload(
            outing_type="special-occasion",
            budget="$$$",
            pace="leisurely",
            social_context="date",
            atmosphere=["scenic", "refined", "upscale"],
            date_night=True,
            requires_reservations=True,
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
]


def list_system_presets() -> list[PresetResponse]:
    return SYSTEM_PRESETS


def get_system_preset_by_id(preset_id: str) -> PresetResponse | None:
    for preset in SYSTEM_PRESETS:
        if preset.preset_id == preset_id:
            return preset
    return None
PY

cat > app/services/preset_service.py <<'PY'
from fastapi import HTTPException, status

from app.repositories.preset_repository import PresetRepository
from app.schemas.preset import (
    CreateUserPresetRequest,
    PresetApplyResponse,
    PresetDeleteResponse,
    PresetResponse,
    PresetSelectionPayload,
    UpdateUserPresetRequest,
)
from app.services.preset_catalog import get_system_preset_by_id, list_system_presets


class PresetService:
    def __init__(self, db):
        self.repository = PresetRepository(db)

    def _parse_user_preset_id(self, preset_id: str) -> int:
        if not preset_id.startswith("user:"):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )
        try:
            return int(preset_id.split(":", 1)[1])
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid preset id format",
            ) from exc

    def _ensure_payload_is_recommendation_ready(self, payload: PresetSelectionPayload) -> None:
        if not payload.outing_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Preset selection_payload.outing_type is required",
            )

    def _user_preset_to_response(self, preset) -> PresetResponse:
        return PresetResponse(
            preset_id=f"user:{preset.id}",
            owner_type="user",
            owner_user_id=preset.user_id,
            is_editable=True,
            name=preset.name,
            description=preset.description,
            selection_payload=PresetSelectionPayload(**(preset.selection_payload or {})),
            created_at=preset.created_at,
            updated_at=preset.updated_at,
        )

    def list_presets_for_user(self, user) -> list[PresetResponse]:
        system_presets = list_system_presets()
        user_presets = [
            self._user_preset_to_response(item)
            for item in self.repository.list_user_presets(user.id)
        ]
        return system_presets + user_presets

    def get_preset_for_user(self, user, preset_id: str) -> PresetResponse:
        system_preset = get_system_preset_by_id(preset_id)
        if system_preset is not None:
            return system_preset

        numeric_id = self._parse_user_preset_id(preset_id)
        preset = self.repository.get_user_preset(user.id, numeric_id)
        if preset is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )
        return self._user_preset_to_response(preset)

    def create_user_preset(self, user, payload: CreateUserPresetRequest) -> PresetResponse:
        self._ensure_payload_is_recommendation_ready(payload.selection_payload)

        preset = self.repository.create_user_preset(
            user_id=user.id,
            name=payload.name,
            description=payload.description,
            selection_payload=payload.selection_payload.model_dump(exclude_none=True),
        )
        return self._user_preset_to_response(preset)

    def update_user_preset(self, user, preset_id: str, payload: UpdateUserPresetRequest) -> PresetResponse:
        numeric_id = self._parse_user_preset_id(preset_id)
        preset = self.repository.get_user_preset(user.id, numeric_id)
        if preset is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )

        selection_payload = None
        if payload.selection_payload is not None:
            self._ensure_payload_is_recommendation_ready(payload.selection_payload)
            selection_payload = payload.selection_payload.model_dump(exclude_none=True)

        updated = self.repository.update_user_preset(
            preset=preset,
            name=payload.name,
            description=payload.description,
            selection_payload=selection_payload,
        )
        return self._user_preset_to_response(updated)

    def delete_user_preset(self, user, preset_id: str) -> PresetDeleteResponse:
        numeric_id = self._parse_user_preset_id(preset_id)
        preset = self.repository.get_user_preset(user.id, numeric_id)
        if preset is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )

        self.repository.delete_user_preset(preset)
        return PresetDeleteResponse(
            message="Preset deleted successfully",
            deleted_preset_id=preset_id,
        )

    def apply_preset_for_user(self, user, preset_id: str) -> PresetApplyResponse:
        preset = self.get_preset_for_user(user, preset_id)
        builder_payload = preset.selection_payload

        return PresetApplyResponse(
            preset=preset,
            builder_payload=builder_payload,
            banner_message=f'Preset "{preset.name}" applied. You can customize any field before generating recommendations.',
            can_customize=True,
        )
PY

cat > app/api/routes/presets.py <<'PY'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.preset import (
    CreateUserPresetRequest,
    PresetApplyResponse,
    PresetDeleteResponse,
    PresetResponse,
    UpdateUserPresetRequest,
)
from app.services.preset_service import PresetService

router = APIRouter()


@router.get("", response_model=list[PresetResponse])
def list_presets(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).list_presets_for_user(current_user)


@router.get("/{preset_id}", response_model=PresetResponse)
def get_preset(
    preset_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).get_preset_for_user(current_user, preset_id)


@router.post("", response_model=PresetResponse)
def create_user_preset(
    payload: CreateUserPresetRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).create_user_preset(current_user, payload)


@router.put("/{preset_id}", response_model=PresetResponse)
def update_user_preset(
    preset_id: str,
    payload: UpdateUserPresetRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).update_user_preset(current_user, preset_id, payload)


@router.delete("/{preset_id}", response_model=PresetDeleteResponse)
def delete_user_preset(
    preset_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).delete_user_preset(current_user, preset_id)


@router.post("/{preset_id}/apply", response_model=PresetApplyResponse)
def apply_preset(
    preset_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).apply_preset_for_user(current_user, preset_id)
PY

cat > app/api/router.py <<'PY'
from fastapi import APIRouter

from app.api.routes import auth, experiences, onboarding, presets, recommendations, restaurants, users

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])
api_router.include_router(presets.router, prefix="/presets", tags=["presets"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
api_router.include_router(experiences.router, prefix="/experiences", tags=["experiences"])
api_router.include_router(restaurants.router, prefix="/restaurants", tags=["restaurants"])
PY

cat > app/db/init_db.py <<'PY'
from app.db.base import Base
from app.db.schema_upgrade import apply_patch1_schema_upgrades
from app.db.session import engine
from app.models import experience, preset, restaurant, user  # noqa: F401


def init_db() -> None:
    Base.metadata.create_all(bind=engine)
    apply_patch1_schema_upgrades(engine)


if __name__ == "__main__":
    init_db()
    print("database tables created successfully")
PY

python3 <<'PY'
from pathlib import Path
import re

path = Path("app/services/recommendation_service.py")
text = path.read_text()

old_import = """from app.schemas.recommendation import (
    BuildYourNightRequest,
    DescribeYourNightRequest,
    RecommendationItem,
    RecommendationRequestSummary,
    RecommendationResponse,
    ScoreBreakdownItem,
    SurpriseMeRequest,
)
"""
new_import = old_import + "from app.services.preset_service import PresetService\n"
if old_import not in text:
    raise SystemExit("Expected recommendation import block not found")
text = text.replace(old_import, new_import, 1)

old_init = """    def __init__(self, db):
        self.restaurant_repository = RestaurantRepository(db)
        self.experience_repository = ExperienceRepository(db)
"""
new_init = """    def __init__(self, db):
        self.restaurant_repository = RestaurantRepository(db)
        self.experience_repository = ExperienceRepository(db)
        self.preset_service = PresetService(db)

    def _resolve_build_payload(self, user: User, payload: BuildYourNightRequest):
        if not payload.preset_id or payload.use_preset_defaults is False:
            return payload, None

        preset = self.preset_service.get_preset_for_user(user, payload.preset_id)
        base_payload = preset.selection_payload.model_dump(exclude_none=True)
        explicitly_provided = set(getattr(payload, "model_fields_set", set())) - {"preset_id", "use_preset_defaults"}

        for field_name in explicitly_provided:
            base_payload[field_name] = getattr(payload, field_name)

        base_payload["preset_id"] = payload.preset_id
        base_payload["use_preset_defaults"] = payload.use_preset_defaults

        resolved_payload = BuildYourNightRequest(**base_payload)
        return resolved_payload, preset
"""
if old_init not in text:
    raise SystemExit("Expected RecommendationService __init__ block not found")
text = text.replace(old_init, new_init, 1)

build_pattern = re.compile(
    r"    def build_your_night\(self, user: User, payload: BuildYourNightRequest\) -> RecommendationResponse:\n.*?(?=^    def describe_your_night)",
    re.MULTILINE | re.DOTALL,
)
new_build = """    def build_your_night(self, user: User, payload: BuildYourNightRequest) -> RecommendationResponse:
        resolved_payload, _preset = self._resolve_build_payload(user, payload)

        restaurants = self.restaurant_repository.list_restaurants_with_details()
        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="build",
            outing_type=resolved_payload.outing_type,
            mood=resolved_payload.mood,
            budget=resolved_payload.budget,
            pace=resolved_payload.pace,
            social_context=resolved_payload.social_context,
            preferred_cuisines=resolved_payload.preferred_cuisines,
            drinks_focus=resolved_payload.drinks_focus,
            atmosphere=resolved_payload.atmosphere,
            towns=resolved_payload.towns,
            include_tags=resolved_payload.include_tags,
            exclude_tags=resolved_payload.exclude_tags,
            family_friendly=resolved_payload.family_friendly,
            student_friendly=resolved_payload.student_friendly,
            date_night=resolved_payload.date_night,
            quick_bite=resolved_payload.quick_bite,
            fast_food=resolved_payload.fast_food,
            requires_dine_in=resolved_payload.requires_dine_in,
            requires_takeout=resolved_payload.requires_takeout,
            requires_delivery=resolved_payload.requires_delivery,
            requires_reservations=resolved_payload.requires_reservations,
            requires_live_music=resolved_payload.requires_live_music,
            requires_trivia=resolved_payload.requires_trivia,
            include_dish_hints=resolved_payload.include_dish_hints,
        )
        return RecommendationResponse(
            mode="build-your-night",
            engine_version="phase4-presets-v1",
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type=resolved_payload.outing_type,
                budget=resolved_payload.budget,
                pace=resolved_payload.pace,
                social_context=resolved_payload.social_context,
                preferred_cuisines=resolved_payload.preferred_cuisines,
                drinks_focus=resolved_payload.drinks_focus,
                atmosphere=resolved_payload.atmosphere,
                towns=resolved_payload.towns,
                include_tags=resolved_payload.include_tags,
                exclude_tags=resolved_payload.exclude_tags,
                family_friendly=resolved_payload.family_friendly,
                student_friendly=resolved_payload.student_friendly,
                date_night=resolved_payload.date_night,
                quick_bite=resolved_payload.quick_bite,
                fast_food=resolved_payload.fast_food,
                requires_dine_in=resolved_payload.requires_dine_in,
                requires_takeout=resolved_payload.requires_takeout,
                requires_delivery=resolved_payload.requires_delivery,
                requires_reservations=resolved_payload.requires_reservations,
                requires_live_music=resolved_payload.requires_live_music,
                requires_trivia=resolved_payload.requires_trivia,
                preset_id=resolved_payload.preset_id,
            ),
            results=ranked,
        )

"""
if not build_pattern.search(text):
    raise SystemExit("Expected build_your_night method block not found")
text = build_pattern.sub(new_build, text, count=1)

text = text.replace(
    """        return RecommendationResponse(
            mode="describe-your-night",
            engine_version=self.ENGINE_VERSION,
""",
    """        return RecommendationResponse(
            mode="describe-your-night",
            engine_version="phase4-presets-v1",
""",
    1,
)
text = text.replace(
    """                requires_live_music=parsed["requires_live_music"],
                requires_trivia=parsed["requires_trivia"],
            ),
""",
    """                requires_live_music=parsed["requires_live_music"],
                requires_trivia=parsed["requires_trivia"],
                preset_id=None,
            ),
""",
    1,
)

text = text.replace(
    """        return RecommendationResponse(
            mode="surprise-me",
            engine_version=self.ENGINE_VERSION,
""",
    """        return RecommendationResponse(
            mode="surprise-me",
            engine_version="phase4-presets-v1",
""",
    1,
)
text = text.replace(
    """                requires_live_music=None,
                requires_trivia=None,
            ),
""",
    """                requires_live_music=None,
                requires_trivia=None,
                preset_id=None,
            ),
""",
    1,
)

summary_pattern = re.compile(
    r"    def _build_request_summary\([\s\S]*?(?=^    def _parse_prompt)",
    re.MULTILINE | re.DOTALL,
)
new_summary = """    def _build_request_summary(
        self,
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
        towns: list[str],
        include_tags: list[str],
        exclude_tags: list[str],
        family_friendly: Optional[bool],
        student_friendly: Optional[bool],
        date_night: Optional[bool],
        quick_bite: Optional[bool],
        fast_food: Optional[bool],
        requires_dine_in: Optional[bool],
        requires_takeout: Optional[bool],
        requires_delivery: Optional[bool],
        requires_reservations: Optional[bool],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        preset_id: Optional[str],
    ) -> RecommendationRequestSummary:
        return RecommendationRequestSummary(
            outing_type=outing_type,
            budget=budget,
            pace=pace,
            social_context=social_context,
            preferred_cuisines=preferred_cuisines,
            drinks_focus=drinks_focus,
            atmosphere=atmosphere,
            towns=towns,
            include_tags=include_tags,
            exclude_tags=exclude_tags,
            family_friendly=family_friendly,
            student_friendly=student_friendly,
            date_night=date_night,
            quick_bite=quick_bite,
            fast_food=fast_food,
            requires_dine_in=requires_dine_in,
            requires_takeout=requires_takeout,
            requires_delivery=requires_delivery,
            requires_reservations=requires_reservations,
            requires_live_music=requires_live_music,
            requires_trivia=requires_trivia,
            preset_id=preset_id,
        )

"""
if not summary_pattern.search(text):
    raise SystemExit("Expected _build_request_summary block not found")
text = summary_pattern.sub(new_summary, text, count=1)

path.write_text(text)
PY

PYTHON_BIN="python3"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi

echo "Using Python: ${PYTHON_BIN}"
PYTHONPATH=. "${PYTHON_BIN}" -m compileall app

echo "Running schema initialization to create the user_presets table..."
PYTHONPATH=. "${PYTHON_BIN}" - <<'PY'
from app.db.init_db import init_db
init_db()
print("Patch 4 schema initialization completed.")
PY

echo "Running import smoke tests..."
PYTHONPATH=. "${PYTHON_BIN}" - <<'PY'
from app.api.routes.presets import router as presets_router
from app.services.preset_service import PresetService
from app.schemas.preset import CreateUserPresetRequest
print("presets router import OK")
print("PresetService import OK")
print("Preset schemas import OK")
PY

echo "Patch 4 complete."
echo "Backup saved at: ${BACKUP_DIR}"
