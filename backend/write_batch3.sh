#!/bin/bash

set -e

if [ ! -d "backend/app" ]; then
  echo "error: run this from inside the context-aware-dining-platform folder"
  exit 1
fi

cat > backend/app/schemas/__init__.py <<'PY'
# schemas package
PY

cat > backend/app/schemas/auth.py <<'PY'
from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class AuthUserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    onboarding_completed: bool

    model_config = {"from_attributes": True}
PY

cat > backend/app/schemas/user.py <<'PY'
from datetime import datetime

from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    is_active: bool
    onboarding_completed: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserSummaryResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr

    model_config = {"from_attributes": True}
PY

cat > backend/app/schemas/onboarding.py <<'PY'
from pydantic import BaseModel, Field


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
    bio: str | None = None
    spice_tolerance: str | None = None
    price_sensitivity: str | None = None


class OnboardingResponse(BaseModel):
    message: str
    onboarding_completed: bool
PY

cat > backend/app/schemas/restaurant.py <<'PY'
from pydantic import BaseModel


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
    price: float | None
    description: str | None
    is_signature: bool
    tags: list[TagResponse] = []

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    id: int
    name: str
    description: str | None
    city: str
    price_tier: str
    atmosphere: str | None
    pace: str | None
    social_style: str | None
    serves_alcohol: bool

    model_config = {"from_attributes": True}


class RestaurantDetailResponse(BaseModel):
    id: int
    name: str
    description: str | None
    city: str
    price_tier: str
    atmosphere: str | None
    pace: str | None
    social_style: str | None
    serves_alcohol: bool
    tags: list[TagResponse] = []
    menu_items: list[MenuItemResponse] = []

    model_config = {"from_attributes": True}
PY

cat > backend/app/schemas/experience.py <<'PY'
from datetime import datetime

from pydantic import BaseModel, Field


class ExperienceRatingCreate(BaseModel):
    category: str = Field(min_length=1, max_length=100)
    score: float = Field(ge=0, le=5)


class ExperienceCreateRequest(BaseModel):
    restaurant_id: int | None = None
    title: str | None = Field(default=None, max_length=200)
    occasion: str | None = Field(default=None, max_length=100)
    social_context: str | None = Field(default=None, max_length=100)
    notes: str | None = None
    overall_rating: float | None = Field(default=None, ge=0, le=5)
    menu_item_ids: list[int] = Field(default_factory=list)
    ratings: list[ExperienceRatingCreate] = Field(default_factory=list)


class ExperienceRatingResponse(BaseModel):
    id: int
    category: str
    score: float

    model_config = {"from_attributes": True}


class ExperienceResponse(BaseModel):
    id: int
    user_id: int
    restaurant_id: int | None
    title: str | None
    occasion: str | None
    social_context: str | None
    notes: str | None
    overall_rating: float | None
    created_at: datetime
    ratings: list[ExperienceRatingResponse] = []

    model_config = {"from_attributes": True}
PY

cat > backend/app/schemas/recommendation.py <<'PY'
from pydantic import BaseModel, Field


class BuildYourNightRequest(BaseModel):
    outing_type: str = Field(min_length=1, max_length=100)
    mood: str | None = None
    budget: str | None = None
    pace: str | None = None
    social_context: str | None = None
    preferred_cuisines: list[str] = Field(default_factory=list)
    drinks_focus: bool = False
    atmosphere: list[str] = Field(default_factory=list)


class DescribeYourNightRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=1000)


class SurpriseMeRequest(BaseModel):
    include_drinks: bool = False


class RecommendationItem(BaseModel):
    restaurant_id: int
    restaurant_name: str
    score: float
    reasons: list[str]
    suggested_dishes: list[str] = []
    suggested_drinks: list[str] = []


class RecommendationResponse(BaseModel):
    mode: str
    results: list[RecommendationItem]
PY

cat > backend/app/repositories/__init__.py <<'PY'
# repositories package
PY

cat > backend/app/repositories/user_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.user import User, UserPreference, UserProfile


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str) -> User | None:
        return (
            self.db.query(User)
            .options(joinedload(User.profile), joinedload(User.preference))
            .filter(User.email == email.lower())
            .first()
        )

    def get_by_id(self, user_id: int) -> User | None:
        return (
            self.db.query(User)
            .options(joinedload(User.profile), joinedload(User.preference))
            .filter(User.id == user_id)
            .first()
        )

    def create_user(
        self,
        first_name: str,
        last_name: str,
        email: str,
        hashed_password: str,
    ) -> User:
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
        spice_tolerance: str | None,
        price_sensitivity: str | None,
    ) -> UserPreference:
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

        self.db.commit()
        self.db.refresh(preference)
        return preference

    def upsert_profile(
        self,
        user_id: int,
        bio: str | None,
        favorite_dining_experiences: list[str],
        favorite_restaurants: list[str],
    ) -> UserProfile:
        profile = self.db.query(UserProfile).filter(UserProfile.user_id == user_id).first()

        if profile is None:
            profile = UserProfile(user_id=user_id)
            self.db.add(profile)

        profile.bio = bio
        profile.favorite_dining_experiences = favorite_dining_experiences
        profile.favorite_restaurants = favorite_restaurants

        self.db.commit()
        self.db.refresh(profile)
        return profile

    def mark_onboarding_complete(self, user_id: int) -> User | None:
        user = self.db.query(User).filter(User.id == user_id).first()
        if user is None:
            return None

        user.onboarding_completed = True
        self.db.commit()
        self.db.refresh(user)
        return user
PY

cat > backend/app/repositories/restaurant_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.restaurant import MenuItem, Restaurant, Tag


class RestaurantRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_restaurants(self) -> list[Restaurant]:
        return (
            self.db.query(Restaurant)
            .order_by(Restaurant.name.asc())
            .all()
        )

    def get_restaurant_by_id(self, restaurant_id: int) -> Restaurant | None:
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.menu_items).joinedload(MenuItem.tags),
            )
            .filter(Restaurant.id == restaurant_id)
            .first()
        )

    def list_restaurants_with_details(self) -> list[Restaurant]:
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.menu_items).joinedload(MenuItem.tags),
            )
            .order_by(Restaurant.name.asc())
            .all()
        )

    def get_menu_items_by_ids(self, menu_item_ids: list[int]) -> list[MenuItem]:
        if not menu_item_ids:
            return []

        return (
            self.db.query(MenuItem)
            .options(joinedload(MenuItem.tags))
            .filter(MenuItem.id.in_(menu_item_ids))
            .all()
        )

    def list_tags(self) -> list[Tag]:
        return self.db.query(Tag).order_by(Tag.category.asc(), Tag.name.asc()).all()
PY

cat > backend/app/repositories/experience_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.experience import Experience, ExperienceRating
from app.models.restaurant import MenuItem


class ExperienceRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_experience(
        self,
        user_id: int,
        restaurant_id: int | None,
        title: str | None,
        occasion: str | None,
        social_context: str | None,
        notes: str | None,
        overall_rating: float | None,
        menu_items: list[MenuItem],
        ratings: list[dict],
    ) -> Experience:
        experience = Experience(
            user_id=user_id,
            restaurant_id=restaurant_id,
            title=title,
            occasion=occasion,
            social_context=social_context,
            notes=notes,
            overall_rating=overall_rating,
        )
        experience.menu_items = menu_items

        self.db.add(experience)
        self.db.flush()

        for rating in ratings:
            self.db.add(
                ExperienceRating(
                    experience_id=experience.id,
                    category=rating["category"],
                    score=rating["score"],
                )
            )

        self.db.commit()
        self.db.refresh(experience)
        return self.get_by_id(experience.id)

    def get_by_id(self, experience_id: int) -> Experience | None:
        return (
            self.db.query(Experience)
            .options(joinedload(Experience.ratings), joinedload(Experience.menu_items))
            .filter(Experience.id == experience_id)
            .first()
        )

    def list_by_user_id(self, user_id: int) -> list[Experience]:
        return (
            self.db.query(Experience)
            .options(joinedload(Experience.ratings), joinedload(Experience.menu_items))
            .filter(Experience.user_id == user_id)
            .order_by(Experience.created_at.desc())
            .all()
        )
PY

echo "batch 3 files written successfully"
