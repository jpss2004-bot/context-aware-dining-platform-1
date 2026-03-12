#!/bin/bash

set -e

if [ ! -d "backend/app" ]; then
  echo "error: run this from inside the context-aware-dining-platform folder"
  exit 1
fi

cat > backend/app/db/__init__.py <<'PY'
# db package
PY

cat > backend/app/db/base.py <<'PY'
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass
PY

cat > backend/app/db/session.py <<'PY'
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    class_=Session,
)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
PY

cat > backend/app/db/deps.py <<'PY'
from app.db.session import get_db

__all__ = ["get_db"]
PY

cat > backend/app/db/init_db.py <<'PY'
from app.db.base import Base
from app.db.session import engine
from app.models import experience, restaurant, user  # noqa: F401


def init_db() -> None:
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    init_db()
    print("database tables created successfully")
PY

cat > backend/app/db/seed.py <<'PY'
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.restaurant import MenuItem, Restaurant, Tag


def seed_db() -> None:
    db: Session = SessionLocal()

    try:
        existing = db.query(Restaurant).first()
        if existing:
            print("seed skipped: restaurants already exist")
            return

        cozy = Tag(name="cozy", category="atmosphere")
        lively = Tag(name="lively", category="atmosphere")
        romantic = Tag(name="romantic", category="occasion")
        cocktails = Tag(name="cocktails", category="drinks")
        pasta = Tag(name="pasta", category="cuisine")
        comfort = Tag(name="comfort-food", category="style")
        quick = Tag(name="quick-bite", category="style")
        group_friendly = Tag(name="group-friendly", category="social")
        quiet = Tag(name="quiet", category="social")

        db.add_all([cozy, lively, romantic, cocktails, pasta, comfort, quick, group_friendly, quiet])
        db.flush()

        restaurants = [
            Restaurant(
                name="Luna Trattoria",
                description="Warm Italian spot with handmade pasta and a relaxed romantic mood.",
                city="Wolfville",
                price_tier="$$",
                atmosphere="cozy",
                pace="leisurely",
                social_style="romantic",
                serves_alcohol=True,
                tags=[cozy, romantic, pasta, comfort],
            ),
            Restaurant(
                name="North End Social",
                description="Energetic small-plates venue with cocktails and a lively evening crowd.",
                city="Wolfville",
                price_tier="$$$",
                atmosphere="lively",
                pace="moderate",
                social_style="group",
                serves_alcohol=True,
                tags=[lively, cocktails, group_friendly],
            ),
            Restaurant(
                name="Campus Quick Bowl",
                description="Fast casual bowls and wraps for quick solo meals or easy takeout.",
                city="Wolfville",
                price_tier="$",
                atmosphere="casual",
                pace="fast",
                social_style="solo",
                serves_alcohol=False,
                tags=[quick, quiet],
            ),
        ]

        db.add_all(restaurants)
        db.flush()

        menu_items = [
            MenuItem(
                restaurant_id=restaurants[0].id,
                name="Truffle Mushroom Tagliatelle",
                category="dish",
                price=21.50,
                description="Rich pasta with mushrooms and parmesan.",
                is_signature=True,
                tags=[pasta, comfort],
            ),
            MenuItem(
                restaurant_id=restaurants[0].id,
                name="House Red Wine",
                category="drink",
                price=10.00,
                description="Medium-bodied red wine by the glass.",
                is_signature=False,
                tags=[romantic],
            ),
            MenuItem(
                restaurant_id=restaurants[1].id,
                name="Smoked Chili Sliders",
                category="dish",
                price=16.00,
                description="Shareable sliders with smoky chili sauce.",
                is_signature=True,
                tags=[group_friendly],
            ),
            MenuItem(
                restaurant_id=restaurants[1].id,
                name="Citrus Gin Fizz",
                category="drink",
                price=14.00,
                description="Bright gin cocktail with citrus and herbs.",
                is_signature=True,
                tags=[cocktails, lively],
            ),
            MenuItem(
                restaurant_id=restaurants[2].id,
                name="Chicken Rice Bowl",
                category="dish",
                price=12.50,
                description="Fast, filling rice bowl with grilled chicken.",
                is_signature=True,
                tags=[quick],
            ),
            MenuItem(
                restaurant_id=restaurants[2].id,
                name="Iced Matcha",
                category="drink",
                price=5.50,
                description="Cold matcha with milk over ice.",
                is_signature=False,
                tags=[quiet],
            ),
        ]

        db.add_all(menu_items)
        db.commit()
        print("database seeded successfully")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_db()
PY

cat > backend/app/models/__init__.py <<'PY'
from app.models.experience import Experience, ExperienceRating
from app.models.restaurant import MenuItem, Restaurant, Tag
from app.models.user import User, UserPreference, UserProfile

__all__ = [
    "User",
    "UserProfile",
    "UserPreference",
    "Restaurant",
    "MenuItem",
    "Tag",
    "Experience",
    "ExperienceRating",
]
PY

cat > backend/app/models/user.py <<'PY'
from datetime import datetime, timezone

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

    profile: Mapped["UserProfile | None"] = relationship(
        "UserProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    preference: Mapped["UserPreference | None"] = relationship(
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
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
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
    spice_tolerance: Mapped[str | None] = mapped_column(String(50), nullable=True)
    price_sensitivity: Mapped[str | None] = mapped_column(String(50), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="preference")


from app.models.experience import Experience  # noqa: E402
PY

cat > backend/app/models/restaurant.py <<'PY'
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Table, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

restaurant_tags = Table(
    "restaurant_tags",
    Base.metadata,
    mapped_column("restaurant_id", ForeignKey("restaurants.id", ondelete="CASCADE"), primary_key=True),
    mapped_column("tag_id", ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
)

menu_item_tags = Table(
    "menu_item_tags",
    Base.metadata,
    mapped_column("menu_item_id", ForeignKey("menu_items.id", ondelete="CASCADE"), primary_key=True),
    mapped_column("tag_id", ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
)

experience_menu_items = Table(
    "experience_menu_items",
    Base.metadata,
    mapped_column("experience_id", ForeignKey("experiences.id", ondelete="CASCADE"), primary_key=True),
    mapped_column("menu_item_id", ForeignKey("menu_items.id", ondelete="CASCADE"), primary_key=True),
)


class Restaurant(Base):
    __tablename__ = "restaurants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    city: Mapped[str] = mapped_column(String(100), nullable=False, default="Wolfville")
    price_tier: Mapped[str] = mapped_column(String(10), nullable=False, default="$$")
    atmosphere: Mapped[str | None] = mapped_column(String(100), nullable=True)
    pace: Mapped[str | None] = mapped_column(String(100), nullable=True)
    social_style: Mapped[str | None] = mapped_column(String(100), nullable=True)
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
    category: Mapped[str] = mapped_column(String(50), nullable=False)  # dish or drink
    price: Mapped[float | None] = mapped_column(Float, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
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

cat > backend/app/models/experience.py <<'PY'
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.restaurant import experience_menu_items


class Experience(Base):
    __tablename__ = "experiences"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    restaurant_id: Mapped[int] = mapped_column(ForeignKey("restaurants.id", ondelete="SET NULL"), nullable=True, index=True)

    title: Mapped[str | None] = mapped_column(String(200), nullable=True)
    occasion: Mapped[str | None] = mapped_column(String(100), nullable=True)
    social_context: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    overall_rating: Mapped[float | None] = mapped_column(Numeric(3, 2), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="experiences")
    restaurant: Mapped["Restaurant | None"] = relationship("Restaurant", back_populates="experiences")
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

echo "batch 2 files written successfully"
