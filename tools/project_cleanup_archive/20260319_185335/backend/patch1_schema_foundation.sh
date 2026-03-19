#!/bin/bash
set -euo pipefail

PATCH_NAME="patch1_schema_foundation"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Creating backup at: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

FILES_TO_BACKUP=(
  "app/models/restaurant.py"
  "app/models/user.py"
  "app/schemas/restaurant.py"
  "app/schemas/onboarding.py"
  "app/repositories/user_repository.py"
  "app/services/onboarding_service.py"
  "app/api/routes/onboarding.py"
  "app/db/init_db.py"
  "app/db/reset_and_seed_restaurants.py"
)

for file in "${FILES_TO_BACKUP[@]}"; do
  if [ -f "$file" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$file")"
    cp "$file" "${BACKUP_DIR}/$file"
  fi
done

mkdir -p app/db app/services app/models app/schemas app/repositories app/api/routes

cat > app/models/restaurant.py <<'PY'
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Table, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

restaurant_tags = Table(
    "restaurant_tags",
    Base.metadata,
    Column("restaurant_id", ForeignKey("restaurants.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
)

menu_item_tags = Table(
    "menu_item_tags",
    Base.metadata,
    Column("menu_item_id", ForeignKey("menu_items.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
)

experience_menu_items = Table(
    "experience_menu_items",
    Base.metadata,
    Column("experience_id", ForeignKey("experiences.id", ondelete="CASCADE"), primary_key=True),
    Column("menu_item_id", ForeignKey("menu_items.id", ondelete="CASCADE"), primary_key=True),
)


class Restaurant(Base):
    __tablename__ = "restaurants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    city: Mapped[str] = mapped_column(String(100), nullable=False, default="Wolfville")
    town: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True)
    region: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    address: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True)
    subcategory: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True)
    price_tier: Mapped[str] = mapped_column(String(10), nullable=False, default="$$")
    price_min_per_person: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    price_max_per_person: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    atmosphere: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    pace: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    social_style: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    serves_alcohol: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    offers_dine_in: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    offers_takeout: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    offers_delivery: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    accepts_reservations: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    supports_brunch: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    supports_lunch: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    supports_dinner: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    supports_dessert: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    supports_coffee: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_fast_food: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_family_friendly: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_date_night: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_student_friendly: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_quick_bite: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    has_live_music: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    has_trivia_night: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    event_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    source_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    menu_items: Mapped[list["MenuItem"]] = relationship(
        "MenuItem",
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
    tags: Mapped[list["Tag"]] = relationship(
        "Tag",
        secondary=restaurant_tags,
        back_populates="restaurants",
    )
    experiences: Mapped[list["Experience"]] = relationship(
        "Experience",
        back_populates="restaurant",
    )


class MenuItem(Base):
    __tablename__ = "menu_items"
    __table_args__ = (
        UniqueConstraint("restaurant_id", "name", name="uq_menu_item_restaurant_name"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    restaurant_id: Mapped[int] = mapped_column(ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    price: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_signature: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    meal_period: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    recommendation_hint: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_dish_highlight: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    restaurant: Mapped["Restaurant"] = relationship("Restaurant", back_populates="menu_items")
    tags: Mapped[list["Tag"]] = relationship(
        "Tag",
        secondary=menu_item_tags,
        back_populates="menu_items",
    )
    experiences: Mapped[list["Experience"]] = relationship(
        "Experience",
        secondary=experience_menu_items,
        back_populates="menu_items",
    )


class Tag(Base):
    __tablename__ = "tags"
    __table_args__ = (
        UniqueConstraint("name", "category", name="uq_tag_name_category"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(100), nullable=False, index=True)

    restaurants: Mapped[list["Restaurant"]] = relationship(
        "Restaurant",
        secondary=restaurant_tags,
        back_populates="tags",
    )
    menu_items: Mapped[list["MenuItem"]] = relationship(
        "MenuItem",
        secondary=menu_item_tags,
        back_populates="tags",
    )
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
PY

cat > app/schemas/restaurant.py <<'PY'
from typing import Optional

from pydantic import BaseModel, Field


class TagResponse(BaseModel):
    id: int
    name: str
    category: str

    model_config = {"from_attributes": True}


class MenuItemResponse(BaseModel):
    id: int
    restaurant_id: int
    name: str
    category: str
    price: Optional[float]
    description: Optional[str]
    is_signature: bool
    meal_period: Optional[str] = None
    recommendation_hint: Optional[str] = None
    is_dish_highlight: bool = False
    tags: list[TagResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    city: str
    town: Optional[str] = None
    region: Optional[str] = None
    address: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    price_tier: str
    price_min_per_person: Optional[float] = None
    price_max_per_person: Optional[float] = None
    atmosphere: Optional[str]
    pace: Optional[str]
    social_style: Optional[str]
    serves_alcohol: bool
    offers_dine_in: Optional[bool] = None
    offers_takeout: Optional[bool] = None
    offers_delivery: Optional[bool] = None
    accepts_reservations: Optional[bool] = None
    supports_brunch: Optional[bool] = None
    supports_lunch: Optional[bool] = None
    supports_dinner: Optional[bool] = None
    supports_dessert: Optional[bool] = None
    supports_coffee: Optional[bool] = None
    is_fast_food: Optional[bool] = None
    is_family_friendly: Optional[bool] = None
    is_date_night: Optional[bool] = None
    is_student_friendly: Optional[bool] = None
    is_quick_bite: Optional[bool] = None
    has_live_music: Optional[bool] = None
    has_trivia_night: Optional[bool] = None
    event_notes: Optional[str] = None
    source_url: Optional[str] = None
    source_notes: Optional[str] = None

    model_config = {"from_attributes": True}


class RestaurantDetailResponse(RestaurantListResponse):
    tags: list[TagResponse] = Field(default_factory=list)
    menu_items: list[MenuItemResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}
PY

cat > app/schemas/onboarding.py <<'PY'
from typing import Optional

from pydantic import BaseModel, Field


class OnboardingOptionValue(BaseModel):
    value: str
    label: str
    description: Optional[str] = None


class OnboardingFieldDefinition(BaseModel):
    key: str
    label: str
    description: str
    select_mode: str
    optional: bool
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
    version="v2-foundation",
    fields=[
        OnboardingFieldDefinition(
            key="cuisine_preferences",
            label="Cuisine preferences",
            description="Choose cuisines you usually enjoy so recommendations can start from familiar options.",
            select_mode="multi",
            optional=False,
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
            select_mode="multi",
            optional=True,
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
            select_mode="multi",
            optional=True,
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
            select_mode="multi",
            optional=True,
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
            select_mode="multi",
            optional=True,
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
            description="Only choose restrictions that should actively filter recommendations. This step is optional.",
            select_mode="multi",
            optional=True,
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
            select_mode="single",
            optional=True,
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
            select_mode="range",
            optional=True,
            step_order=8,
            options=[],
        ),
    ],
)


def get_onboarding_options() -> OnboardingOptionsResponse:
    return ONBOARDING_OPTIONS
PY

cat > app/repositories/user_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.user import User, UserPreference, UserProfile


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str):
        return (
            self.db.query(User)
            .options(joinedload(User.profile), joinedload(User.preference))
            .filter(User.email == email.lower())
            .first()
        )

    def get_by_id(self, user_id: int):
        return (
            self.db.query(User)
            .options(joinedload(User.profile), joinedload(User.preference))
            .filter(User.id == user_id)
            .first()
        )

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

cat > app/services/onboarding_service.py <<'PY'
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.onboarding import OnboardingRequest, OnboardingStateResponse
from app.services.onboarding_catalog import get_onboarding_options


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
            budget_min_per_person=payload.budget_min_per_person,
            budget_max_per_person=payload.budget_max_per_person,
            onboarding_version=payload.onboarding_version,
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
            budget_min_per_person=preference.budget_min_per_person if preference else None,
            budget_max_per_person=preference.budget_max_per_person if preference else None,
            onboarding_version=preference.onboarding_version if preference else None,
            onboarding_completed=bool(hydrated_user.onboarding_completed) if hydrated_user else False,
        )

    def get_onboarding_options(self):
        return get_onboarding_options()
PY

cat > app/api/routes/onboarding.py <<'PY'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.onboarding import (
    OnboardingOptionsResponse,
    OnboardingRequest,
    OnboardingResponse,
    OnboardingStateResponse,
)
from app.services.onboarding_service import OnboardingService

router = APIRouter()


@router.get("", response_model=OnboardingStateResponse)
def get_onboarding(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return OnboardingService(db).get_onboarding_state(current_user)


@router.get("/options", response_model=OnboardingOptionsResponse)
def get_onboarding_options(
    db: Session = Depends(get_db),
):
    return OnboardingService(db).get_onboarding_options()


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

cat > app/db/schema_upgrade.py <<'PY'
from __future__ import annotations

from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine


RESTAURANT_COLUMN_DEFINITIONS = {
    "town": "VARCHAR(100)",
    "region": "VARCHAR(100)",
    "address": "VARCHAR(255)",
    "category": "VARCHAR(100)",
    "subcategory": "VARCHAR(100)",
    "price_min_per_person": "FLOAT",
    "price_max_per_person": "FLOAT",
    "offers_dine_in": "BOOLEAN",
    "offers_takeout": "BOOLEAN",
    "offers_delivery": "BOOLEAN",
    "accepts_reservations": "BOOLEAN",
    "supports_brunch": "BOOLEAN",
    "supports_lunch": "BOOLEAN",
    "supports_dinner": "BOOLEAN",
    "supports_dessert": "BOOLEAN",
    "supports_coffee": "BOOLEAN",
    "is_fast_food": "BOOLEAN",
    "is_family_friendly": "BOOLEAN",
    "is_date_night": "BOOLEAN",
    "is_student_friendly": "BOOLEAN",
    "is_quick_bite": "BOOLEAN",
    "has_live_music": "BOOLEAN",
    "has_trivia_night": "BOOLEAN",
    "event_notes": "TEXT",
    "source_url": "VARCHAR(500)",
    "source_notes": "TEXT",
}

MENU_ITEM_COLUMN_DEFINITIONS = {
    "meal_period": "VARCHAR(50)",
    "recommendation_hint": "TEXT",
    "is_dish_highlight": "BOOLEAN NOT NULL DEFAULT 0",
}

PREFERENCE_COLUMN_DEFINITIONS = {
    "budget_min_per_person": "FLOAT",
    "budget_max_per_person": "FLOAT",
    "onboarding_version": "VARCHAR(50)",
}


def _existing_columns(engine: Engine, table_name: str) -> set[str]:
    inspector = inspect(engine)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _add_missing_columns(engine: Engine, table_name: str, definitions: dict[str, str]) -> list[str]:
    existing = _existing_columns(engine, table_name)
    added: list[str] = []

    with engine.begin() as connection:
        for column_name, ddl in definitions.items():
            if column_name in existing:
                continue
            connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {ddl}"))
            added.append(column_name)

    return added


def apply_patch1_schema_upgrades(engine: Engine) -> dict[str, list[str]]:
    return {
        "restaurants": _add_missing_columns(engine, "restaurants", RESTAURANT_COLUMN_DEFINITIONS),
        "menu_items": _add_missing_columns(engine, "menu_items", MENU_ITEM_COLUMN_DEFINITIONS),
        "preferences": _add_missing_columns(engine, "preferences", PREFERENCE_COLUMN_DEFINITIONS),
    }
PY

cat > app/db/init_db.py <<'PY'
from app.db.base import Base
from app.db.schema_upgrade import apply_patch1_schema_upgrades
from app.db.session import engine
from app.models import experience, restaurant, user  # noqa: F401


def init_db() -> None:
    Base.metadata.create_all(bind=engine)
    apply_patch1_schema_upgrades(engine)


if __name__ == "__main__":
    init_db()
    print("database tables created successfully")
PY

cat > app/db/reset_and_seed_restaurants.py <<'PY'
from sqlalchemy import delete, func
from sqlalchemy.orm import Session

from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models.restaurant import (
    MenuItem,
    Restaurant,
    Tag,
    experience_menu_items,
    menu_item_tags,
    restaurant_tags,
)
from app.db.seed_real_wolfville import RESTAURANTS, upsert_restaurant


def reset_and_seed() -> None:
    init_db()
    db: Session = SessionLocal()

    try:
        print("clearing restaurant-related tables...")

        db.execute(delete(experience_menu_items))
        db.execute(delete(menu_item_tags))
        db.execute(delete(restaurant_tags))

        db.query(MenuItem).delete(synchronize_session=False)
        db.query(Restaurant).delete(synchronize_session=False)
        db.query(Tag).delete(synchronize_session=False)

        db.commit()

        print("seeding canonical wolfville catalog...")
        for item in RESTAURANTS:
            upsert_restaurant(db, item)

        db.commit()

        restaurant_count = db.query(Restaurant).count()
        menu_count = db.query(MenuItem).count()
        tag_count = db.query(Tag).count()

        duplicate_names = (
            db.query(Restaurant.name, func.count(Restaurant.id))
            .group_by(Restaurant.name)
            .having(func.count(Restaurant.id) > 1)
            .all()
        )

        print(f"seed complete: {restaurant_count} restaurants, {menu_count} menu items, {tag_count} tags")

        if duplicate_names:
            print("duplicate restaurant names still detected:")
            for name, count in duplicate_names:
                print(f" - {name}: {count}")
            raise RuntimeError("duplicate restaurant names remain after reseed")

        print("catalog is clean: no duplicate restaurant names found")
        print("patch 1 foundation columns are available for richer restaurant metadata and onboarding budget fields")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    reset_and_seed()
PY

PYTHON_BIN="python3"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi

echo "Using Python: ${PYTHON_BIN}"
"${PYTHON_BIN}" -m compileall app

echo "Patch 1 files written successfully."

if "${PYTHON_BIN}" - <<'PY' >/dev/null 2>&1
import sqlalchemy  # noqa: F401
PY
then
  echo "Applying schema upgrade through init_db()..."
  "${PYTHON_BIN}" - <<'PY'
from app.db.init_db import init_db
init_db()
print("Patch 1 schema initialization completed.")
PY
else
  echo "Skipping runtime schema upgrade because SQLAlchemy is not available in the selected Python environment."
  echo "The code patch is still applied; run init_db later inside your working backend environment."
fi

echo "Backup saved at: ${BACKUP_DIR}"
echo "Patch 1 complete."
