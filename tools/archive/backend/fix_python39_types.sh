#!/bin/bash

set -e

cat > app/core/security.py <<'PY'
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return password_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return password_context.verify(plain_password, hashed_password)


def create_access_token(
    subject: str,
    expires_delta: Optional[timedelta] = None,
) -> str:
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.jwt_access_token_expire_minutes)
    )

    payload: dict[str, Any] = {
        "sub": subject,
        "exp": expire,
    }

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_token(token: str) -> Optional[dict[str, Any]]:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        return payload
    except JWTError:
        return None
PY

cat > app/models/user.py <<'PY'
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String, Text
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
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="preference")


from app.models.experience import Experience  # noqa: E402
PY

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
    price_tier: Mapped[str] = mapped_column(String(10), nullable=False, default="$$")
    atmosphere: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    pace: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    social_style: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    serves_alcohol: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
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

cat > app/models/experience.py <<'PY'
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.restaurant import experience_menu_items


class Experience(Base):
    __tablename__ = "experiences"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    restaurant_id: Mapped[Optional[int]] = mapped_column(ForeignKey("restaurants.id", ondelete="SET NULL"), nullable=True, index=True)

    title: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    occasion: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    social_context: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    overall_rating: Mapped[Optional[float]] = mapped_column(Numeric(3, 2), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="experiences")
    restaurant: Mapped[Optional["Restaurant"]] = relationship("Restaurant", back_populates="experiences")
    ratings: Mapped[list["ExperienceRating"]] = relationship(
        "ExperienceRating",
        back_populates="experience",
        cascade="all, delete-orphan",
    )
    menu_items: Mapped[list["MenuItem"]] = relationship(
        "MenuItem",
        secondary=experience_menu_items,
        back_populates="experiences",
    )


class ExperienceRating(Base):
    __tablename__ = "ratings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    experience_id: Mapped[int] = mapped_column(ForeignKey("experiences.id", ondelete="CASCADE"), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(100), nullable=False)
    score: Mapped[float] = mapped_column(Numeric(3, 2), nullable=False)

    experience: Mapped["Experience"] = relationship("Experience", back_populates="ratings")


from app.models.restaurant import MenuItem, Restaurant  # noqa: E402
from app.models.user import User  # noqa: E402
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
    tags: list[TagResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    city: str
    price_tier: str
    atmosphere: Optional[str]
    pace: Optional[str]
    social_style: Optional[str]
    serves_alcohol: bool

    model_config = {"from_attributes": True}


class RestaurantDetailResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    city: str
    price_tier: str
    atmosphere: Optional[str]
    pace: Optional[str]
    social_style: Optional[str]
    serves_alcohol: bool
    tags: list[TagResponse] = Field(default_factory=list)
    menu_items: list[MenuItemResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}
PY

cat > app/schemas/experience.py <<'PY'
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ExperienceRatingCreate(BaseModel):
    category: str = Field(min_length=1, max_length=100)
    score: float = Field(ge=0, le=5)


class ExperienceCreateRequest(BaseModel):
    restaurant_id: Optional[int] = None
    title: Optional[str] = Field(default=None, max_length=200)
    occasion: Optional[str] = Field(default=None, max_length=100)
    social_context: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = None
    overall_rating: Optional[float] = Field(default=None, ge=0, le=5)
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
    restaurant_id: Optional[int]
    title: Optional[str]
    occasion: Optional[str]
    social_context: Optional[str]
    notes: Optional[str]
    overall_rating: Optional[float]
    created_at: datetime
    ratings: list[ExperienceRatingResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}
PY

cat > app/schemas/onboarding.py <<'PY'
from typing import Optional

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
    bio: Optional[str] = None
    spice_tolerance: Optional[str] = None
    price_sensitivity: Optional[str] = None


class OnboardingResponse(BaseModel):
    message: str
    onboarding_completed: bool
PY

cat > app/services/recommendation_service.py <<'PY'
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
PY

echo "python 3.9 type fixes applied"
