#!/bin/bash
set -e

PROJECT_ROOT="$(pwd)"

BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

for dir in "$BACKEND_DIR" "$FRONTEND_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "Required directory missing: $dir"
    exit 1
  fi
done

REQUIRED_FILES=(
  "$BACKEND_DIR/app/models/restaurant.py"
  "$BACKEND_DIR/app/models/__init__.py"
  "$BACKEND_DIR/app/schemas/restaurant.py"
  "$BACKEND_DIR/app/schemas/recommendation.py"
  "$BACKEND_DIR/app/repositories/restaurant_repository.py"
  "$BACKEND_DIR/app/db/schema_upgrade.py"
  "$BACKEND_DIR/app/db/init_db.py"
  "$BACKEND_DIR/app/db/seed_real_wolfville.py"
  "$BACKEND_DIR/app/services/recommendation_service.py"
  "$FRONTEND_DIR/src/types.ts"
  "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx"
  "$FRONTEND_DIR/src/pages/RestaurantDetailPage.tsx"
  "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx"
  "$FRONTEND_DIR/src/styles.css"
)

for path in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$path" ]; then
    echo "Required file missing: $path"
    exit 1
  fi
done

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.patch5_event_fastfood_enrichment_backup_$STAMP"

mkdir -p \
  "$BACKUP_DIR/backend/app/models" \
  "$BACKUP_DIR/backend/app/schemas" \
  "$BACKUP_DIR/backend/app/repositories" \
  "$BACKUP_DIR/backend/app/db" \
  "$BACKUP_DIR/backend/app/services" \
  "$BACKUP_DIR/frontend/src/pages" \
  "$BACKUP_DIR/frontend/src/components/navigation" \
  "$BACKUP_DIR/frontend/src"

cp "$BACKEND_DIR/app/models/restaurant.py" "$BACKUP_DIR/backend/app/models/restaurant.py"
cp "$BACKEND_DIR/app/models/__init__.py" "$BACKUP_DIR/backend/app/models/__init__.py"
cp "$BACKEND_DIR/app/schemas/restaurant.py" "$BACKUP_DIR/backend/app/schemas/restaurant.py"
cp "$BACKEND_DIR/app/schemas/recommendation.py" "$BACKUP_DIR/backend/app/schemas/recommendation.py"
cp "$BACKEND_DIR/app/repositories/restaurant_repository.py" "$BACKUP_DIR/backend/app/repositories/restaurant_repository.py"
cp "$BACKEND_DIR/app/db/schema_upgrade.py" "$BACKUP_DIR/backend/app/db/schema_upgrade.py"
cp "$BACKEND_DIR/app/db/init_db.py" "$BACKUP_DIR/backend/app/db/init_db.py"
cp "$BACKEND_DIR/app/db/seed_real_wolfville.py" "$BACKUP_DIR/backend/app/db/seed_real_wolfville.py"
cp "$BACKEND_DIR/app/services/recommendation_service.py" "$BACKUP_DIR/backend/app/services/recommendation_service.py"
cp "$FRONTEND_DIR/src/types.ts" "$BACKUP_DIR/frontend/src/types.ts"
cp "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx" "$BACKUP_DIR/frontend/src/pages/RecommendationsPage.tsx"
cp "$FRONTEND_DIR/src/pages/RestaurantDetailPage.tsx" "$BACKUP_DIR/frontend/src/pages/RestaurantDetailPage.tsx"
cp "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" "$BACKUP_DIR/frontend/src/components/navigation/Sidebar.tsx"
cp "$FRONTEND_DIR/src/styles.css" "$BACKUP_DIR/frontend/src/styles.css"

echo "Backup created at: $BACKUP_DIR"

cat > "$BACKEND_DIR/app/models/restaurant.py" <<'EOF'
from datetime import date, datetime, time, timezone
from typing import Optional

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Table,
    Text,
    Time,
    UniqueConstraint,
)
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
    events: Mapped[list["VenueEvent"]] = relationship(
        "VenueEvent",
        back_populates="restaurant",
        cascade="all, delete-orphan",
        order_by="VenueEvent.name.asc()",
    )
    experiences: Mapped[list["Experience"]] = relationship(
        "Experience",
        back_populates="restaurant",
    )


class VenueEvent(Base):
    __tablename__ = "venue_events"
    __table_args__ = (
        UniqueConstraint(
            "restaurant_id",
            "name",
            "event_type",
            "day_of_week",
            "event_date",
            "recurrence",
            name="uq_venue_event_signature",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    restaurant_id: Mapped[int] = mapped_column(
        ForeignKey("restaurants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    event_type: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    day_of_week: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, index=True)
    event_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    recurrence: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    start_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    end_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    restaurant: Mapped["Restaurant"] = relationship("Restaurant", back_populates="events")


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
EOF

cat > "$BACKEND_DIR/app/models/__init__.py" <<'EOF'
from app.models.experience import Experience, ExperienceRating
from app.models.preset import UserPreset
from app.models.restaurant import MenuItem, Restaurant, Tag, VenueEvent
from app.models.user import User, UserPreference, UserProfile

__all__ = [
    "User",
    "UserProfile",
    "UserPreference",
    "UserPreset",
    "Restaurant",
    "VenueEvent",
    "MenuItem",
    "Tag",
    "Experience",
    "ExperienceRating",
]
EOF

cat > "$BACKEND_DIR/app/schemas/restaurant.py" <<'EOF'
from datetime import date, time
from typing import Optional

from pydantic import BaseModel, Field


class TagResponse(BaseModel):
    id: int
    name: str
    category: str

    model_config = {"from_attributes": True}


class VenueEventResponse(BaseModel):
    id: int
    restaurant_id: int
    name: str
    event_type: str
    description: Optional[str] = None
    day_of_week: Optional[str] = None
    event_date: Optional[date] = None
    recurrence: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    is_active: bool

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
    events: list[VenueEventResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}
EOF

cat > "$BACKEND_DIR/app/schemas/recommendation.py" <<'EOF'
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
    active_event_matches: list[str] = Field(default_factory=list)


class RecommendationResponse(BaseModel):
    mode: str
    engine_version: str = "phase5-events-v1"
    generated_at: str
    request_summary: RecommendationRequestSummary
    results: list[RecommendationItem]
EOF

cat > "$BACKEND_DIR/app/repositories/restaurant_repository.py" <<'EOF'
from sqlalchemy.orm import Session, joinedload

from app.models.restaurant import MenuItem, Restaurant, Tag, VenueEvent


class RestaurantRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_restaurants(self):
        return (
            self.db.query(Restaurant)
            .options(joinedload(Restaurant.events))
            .order_by(Restaurant.name.asc())
            .all()
        )

    def get_restaurant_by_id(self, restaurant_id: int):
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.events),
                joinedload(Restaurant.menu_items).joinedload(MenuItem.tags),
            )
            .filter(Restaurant.id == restaurant_id)
            .first()
        )

    def list_restaurants_with_details(self):
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.events),
                joinedload(Restaurant.menu_items).joinedload(MenuItem.tags),
            )
            .order_by(Restaurant.name.asc())
            .all()
        )

    def get_menu_items_by_ids(self, menu_item_ids: list[int]):
        if not menu_item_ids:
            return []

        return (
            self.db.query(MenuItem)
            .options(joinedload(MenuItem.tags))
            .filter(MenuItem.id.in_(menu_item_ids))
            .all()
        )

    def list_tags(self):
        return self.db.query(Tag).order_by(Tag.category.asc(), Tag.name.asc()).all()

    def list_events(self):
        return self.db.query(VenueEvent).order_by(VenueEvent.name.asc()).all()
EOF

cat > "$BACKEND_DIR/app/db/schema_upgrade.py" <<'EOF'
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


def _create_venue_events_table(engine: Engine) -> list[str]:
    inspector = inspect(engine)
    if "venue_events" in inspector.get_table_names():
        return []

    create_sql = """
    CREATE TABLE venue_events (
        id INTEGER PRIMARY KEY,
        restaurant_id INTEGER NOT NULL,
        name VARCHAR(200) NOT NULL,
        event_type VARCHAR(100) NOT NULL,
        description TEXT,
        day_of_week VARCHAR(20),
        event_date DATE,
        recurrence VARCHAR(50),
        start_time TIME,
        end_time TIME,
        is_active BOOLEAN NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    )
    """
    create_index_sql = """
    CREATE INDEX IF NOT EXISTS ix_venue_events_restaurant_id ON venue_events (restaurant_id)
    """

    with engine.begin() as connection:
        connection.execute(text(create_sql))
        connection.execute(text(create_index_sql))

    return ["venue_events"]


def apply_patch1_schema_upgrades(engine: Engine) -> dict[str, list[str]]:
    return {
        "restaurants": _add_missing_columns(engine, "restaurants", RESTAURANT_COLUMN_DEFINITIONS),
        "menu_items": _add_missing_columns(engine, "menu_items", MENU_ITEM_COLUMN_DEFINITIONS),
        "preferences": _add_missing_columns(engine, "preferences", PREFERENCE_COLUMN_DEFINITIONS),
    }


def apply_patch5_event_schema(engine: Engine) -> dict[str, list[str]]:
    return {
        "tables": _create_venue_events_table(engine),
    }
EOF

cat > "$BACKEND_DIR/app/db/init_db.py" <<'EOF'
from app.db.base import Base
from app.db.schema_upgrade import apply_patch1_schema_upgrades, apply_patch5_event_schema
from app.db.session import engine
from app.models import experience, preset, restaurant, user  # noqa: F401


def init_db() -> None:
    Base.metadata.create_all(bind=engine)
    apply_patch1_schema_upgrades(engine)
    apply_patch5_event_schema(engine)


if __name__ == "__main__":
    init_db()
    print("database tables created successfully")
EOF

python3 - <<'PY'
from pathlib import Path

seed_path = Path("backend/app/db/seed_real_wolfville.py")
text = seed_path.read_text()

if "PATCH5_EVENT_SEEDS_START" not in text:
    text = text.replace(
        "from dataclasses import dataclass, field\n",
        "from dataclasses import dataclass, field\nfrom datetime import time\n",
    )
    text = text.replace(
        "from app.models.restaurant import MenuItem, Restaurant, Tag\n",
        "from app.models.restaurant import MenuItem, Restaurant, Tag, VenueEvent\n",
    )

    insert_block = """

# PATCH5_EVENT_SEEDS_START
EVENT_SEEDS = {
    "The Library Pub": [
        {
            "name": "Thursday Trivia Night",
            "event_type": "trivia",
            "description": "Recurring trivia-oriented pub night that fits social and game-night requests.",
            "day_of_week": "thursday",
            "event_date": None,
            "recurrence": "weekly",
            "start_time": time(19, 0),
            "end_time": time(21, 30),
            "is_active": True,
        },
        {
            "name": "Friday Live Music Session",
            "event_type": "live music",
            "description": "Recurring live-music evening for louder, social pub outings.",
            "day_of_week": "friday",
            "event_date": None,
            "recurrence": "weekly",
            "start_time": time(20, 0),
            "end_time": time(22, 30),
            "is_active": True,
        },
    ],
    "Kings Arms Pub by Lew Murphy's": [
        {
            "name": "Midweek Trivia Social",
            "event_type": "trivia",
            "description": "Recurring trivia event suited to social pub recommendations.",
            "day_of_week": "wednesday",
            "event_date": None,
            "recurrence": "weekly",
            "start_time": time(19, 0),
            "end_time": time(21, 0),
            "is_active": True,
        }
    ],
    "Spitfire Arms Alehouse": [
        {
            "name": "Saturday Live Music",
            "event_type": "live music",
            "description": "Recurring live-music event for energetic group-friendly pub nights.",
            "day_of_week": "saturday",
            "event_date": None,
            "recurrence": "weekly",
            "start_time": time(20, 0),
            "end_time": time(23, 0),
            "is_active": True,
        }
    ],
    "Paddy's Brewpub & Rosie's Family Restaurant": [
        {
            "name": "Theme Night Social",
            "event_type": "themed event",
            "description": "Flexible recurring themed social event suitable for group and pub recommendations.",
            "day_of_week": "friday",
            "event_date": None,
            "recurrence": "weekly",
            "start_time": time(18, 30),
            "end_time": time(21, 0),
            "is_active": True,
        }
    ],
}


def sync_seeded_events(db: Session) -> None:
    for restaurant_name, events in EVENT_SEEDS.items():
        restaurant = db.query(Restaurant).filter(Restaurant.name == restaurant_name).first()
        if restaurant is None:
            continue

        db.query(VenueEvent).filter(VenueEvent.restaurant_id == restaurant.id).delete()

        for event in events:
            db.add(
                VenueEvent(
                    restaurant_id=restaurant.id,
                    name=event["name"],
                    event_type=event["event_type"],
                    description=event["description"],
                    day_of_week=event["day_of_week"],
                    event_date=event["event_date"],
                    recurrence=event["recurrence"],
                    start_time=event["start_time"],
                    end_time=event["end_time"],
                    is_active=event["is_active"],
                )
            )

    db.flush()
# PATCH5_EVENT_SEEDS_END

"""
    text = text.replace("\ndef seed_db() -> None:\n", insert_block + "\ndef seed_db() -> None:\n")
    text = text.replace(
        "        for restaurant in RESTAURANTS:\n            upsert_restaurant(db, restaurant)\n\n        db.commit()\n",
        "        for restaurant in RESTAURANTS:\n            upsert_restaurant(db, restaurant)\n\n        sync_seeded_events(db)\n        db.commit()\n",
    )
    seed_path.write_text(text)
    print("Patched seed_real_wolfville.py")
else:
    print("seed_real_wolfville.py already contains Patch 5 event seeds.")
PY

python3 - <<'PY'
from pathlib import Path

path = Path("backend/app/services/recommendation_service.py")
text = path.read_text()

if "_apply_event_signal_scoring" not in text:
    helper_block = """
    def _event_label(self, event) -> str:
        parts = [event.name]
        if getattr(event, "day_of_week", None):
            parts.append(f"({event.day_of_week.title()})")
        return " ".join(parts)

    def _event_is_current(self, event) -> bool:
        if not getattr(event, "is_active", False):
            return False

        event_date = getattr(event, "event_date", None)
        recurrence = self._normalize_text(getattr(event, "recurrence", None))
        day_of_week = self._normalize_text(getattr(event, "day_of_week", None))
        today = datetime.now(timezone.utc).date()
        today_name = datetime.now(timezone.utc).strftime("%A").lower()

        if event_date is not None:
            return event_date >= today

        if day_of_week and day_of_week == today_name:
            return True

        if recurrence in {"weekly", "biweekly", "monthly", "recurring"}:
            return True

        return day_of_week != "" or recurrence != ""

    def _apply_event_signal_scoring(
        self,
        restaurant: Restaurant,
        outing_type: Optional[str],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int, int, list[str]]:
        points = 0.0
        strong_matches = 0
        contradictions = 0
        event_matches: list[str] = []

        current_events = [
            event for event in getattr(restaurant, "events", [])
            if self._event_is_current(event)
        ]

        for event in current_events:
            normalized_type = self._normalize_text(getattr(event, "event_type", None))
            normalized_name = self._normalize_text(getattr(event, "name", None))
            label = self._event_label(event)

            if requires_live_music is True and ("live music" in normalized_type or "live music" in normalized_name):
                points += 1.6
                strong_matches += 1
                event_matches.append(label)
                self._append_reason(reasons, f"Boosted by an active venue event ({label})")
                self._append_signal(matched_signals, f"event match ({label})")

            if requires_trivia is True and ("trivia" in normalized_type or "trivia" in normalized_name):
                points += 1.6
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Boosted by an active venue event ({label})")
                self._append_signal(matched_signals, f"event match ({label})")

            if self._normalize_text(outing_type) == "drinks-night" and any(
                keyword in normalized_type or keyword in normalized_name
                for keyword in ["live music", "trivia", "themed"]
            ):
                points += 0.8
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Supports a more social outing through an active event ({label})")
                self._append_signal(matched_signals, f"social event support ({label})")

        if points != 0:
            self._add_breakdown(breakdown, "active events", points)

        return points, strong_matches, contradictions, event_matches

    def _build_enriched_explanation(
        self,
        base_explanation: str,
        suggested_dishes: list[str],
        suggested_drinks: list[str],
        event_matches: list[str],
    ) -> str:
        parts = [base_explanation]

        if suggested_dishes:
            parts.append("Try " + ", ".join(suggested_dishes[:2]) + ".")

        if suggested_drinks:
            parts.append("Drink pairing ideas include " + ", ".join(suggested_drinks[:2]) + ".")

        if event_matches:
            parts.append("Current or recurring event context: " + ", ".join(event_matches[:2]) + ".")

        return " ".join(part for part in parts if part)

"""
    text = text.replace("    def _timestamp(self) -> str:\n", helper_block + "    def _timestamp(self) -> str:\n")

text = text.replace(
    "            penalized_signals: list[str] = []\n            breakdown: dict[str, float] = {}\n            strong_matches = 0\n",
    "            penalized_signals: list[str] = []\n            event_matches: list[str] = []\n            breakdown: dict[str, float] = {}\n            strong_matches = 0\n",
)

event_insert_old = """            if direct_meta_points:
                score += direct_meta_points
                soft_matches += 1
                self._add_breakdown(breakdown, "direct metadata", direct_meta_points)

            combination_bonus, combination_strong = self._apply_combination_bonus(
"""
event_insert_new = """            if direct_meta_points:
                score += direct_meta_points
                soft_matches += 1
                self._add_breakdown(breakdown, "direct metadata", direct_meta_points)

            event_points, event_strong, event_contradictions, event_matches = self._apply_event_signal_scoring(
                restaurant=restaurant,
                outing_type=outing_type,
                requires_live_music=requires_live_music,
                requires_trivia=requires_trivia,
                reasons=reasons,
                matched_signals=matched_signals,
                breakdown=breakdown,
            )
            score += event_points
            strong_matches += event_strong
            contradictions += event_contradictions

            combination_bonus, combination_strong = self._apply_combination_bonus(
"""
text = text.replace(event_insert_old, event_insert_new)

explanation_old = """            explanation = self._build_explanation(
                outing_type=outing_type,
                confidence_level=confidence_level,
                matched_signals=matched_signals,
                penalized_signals=penalized_signals,
            )

            fit_label = self._fit_label(score, confidence_level)
"""
explanation_new = """            base_explanation = self._build_explanation(
                outing_type=outing_type,
                confidence_level=confidence_level,
                matched_signals=matched_signals,
                penalized_signals=penalized_signals,
            )
            explanation = self._build_enriched_explanation(
                base_explanation=base_explanation,
                suggested_dishes=suggested_dishes,
                suggested_drinks=suggested_drinks,
                event_matches=event_matches,
            )

            fit_label = self._fit_label(score, confidence_level)
"""
text = text.replace(explanation_old, explanation_new)

text = text.replace(
    "                    suggested_dishes=suggested_dishes,\n                    suggested_drinks=suggested_drinks,\n                )",
    "                    suggested_dishes=suggested_dishes,\n                    suggested_drinks=suggested_drinks,\n                    active_event_matches=event_matches[:3],\n                )",
)

text = text.replace(
    "                    suggested_dishes=item.suggested_dishes,\n                    suggested_drinks=item.suggested_drinks,\n                )",
    "                    suggested_dishes=item.suggested_dishes,\n                    suggested_drinks=item.suggested_drinks,\n                    active_event_matches=item.active_event_matches,\n                )",
)

path.write_text(text)
print("Patched recommendation_service.py")
PY

cat > "$FRONTEND_DIR/src/types.ts" <<'EOF'
export type AuthUser = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  onboarding_completed: boolean;
};

export type UserProfileResponse = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  is_active: boolean;
  onboarding_completed: boolean;
  created_at: string;
};

export type TokenResponse = {
  access_token: string;
  token_type: string;
};

export type Tag = {
  id: number;
  name: string;
  category: string;
};

export type VenueEvent = {
  id: number;
  restaurant_id: number;
  name: string;
  event_type: string;
  description: string | null;
  day_of_week: string | null;
  event_date: string | null;
  recurrence: string | null;
  start_time: string | null;
  end_time: string | null;
  is_active: boolean;
};

export type MenuItem = {
  id: number;
  restaurant_id: number;
  name: string;
  category: string;
  price: number | null;
  description: string | null;
  is_signature: boolean;
  meal_period?: string | null;
  recommendation_hint?: string | null;
  is_dish_highlight?: boolean;
  tags: Tag[];
};

export type RestaurantListItem = {
  id: number;
  name: string;
  description: string | null;
  city: string;
  town?: string | null;
  region?: string | null;
  address?: string | null;
  category?: string | null;
  subcategory?: string | null;
  price_tier: string;
  price_min_per_person?: number | null;
  price_max_per_person?: number | null;
  atmosphere: string | null;
  pace: string | null;
  social_style: string | null;
  serves_alcohol: boolean;
  offers_dine_in?: boolean | null;
  offers_takeout?: boolean | null;
  offers_delivery?: boolean | null;
  accepts_reservations?: boolean | null;
  supports_brunch?: boolean | null;
  supports_lunch?: boolean | null;
  supports_dinner?: boolean | null;
  supports_dessert?: boolean | null;
  supports_coffee?: boolean | null;
  is_fast_food?: boolean | null;
  is_family_friendly?: boolean | null;
  is_date_night?: boolean | null;
  is_student_friendly?: boolean | null;
  is_quick_bite?: boolean | null;
  has_live_music?: boolean | null;
  has_trivia_night?: boolean | null;
  event_notes?: string | null;
  source_url?: string | null;
  source_notes?: string | null;
};

export type RestaurantDetail = RestaurantListItem & {
  tags: Tag[];
  menu_items: MenuItem[];
  events: VenueEvent[];
};

export type OnboardingPayload = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string | null;
  spice_tolerance: string | null;
  price_sensitivity: string | null;
  budget_min_per_person?: number | null;
  budget_max_per_person?: number | null;
  onboarding_version?: string | null;
};

export type OnboardingResponse = {
  message: string;
  onboarding_completed: boolean;
};

export type OnboardingState = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string | null;
  spice_tolerance: string | null;
  price_sensitivity: string | null;
  budget_min_per_person?: number | null;
  budget_max_per_person?: number | null;
  onboarding_version?: string | null;
  onboarding_completed: boolean;
};

export type OnboardingOptionValue = {
  value: string;
  label: string;
  description?: string | null;
};

export type OnboardingFieldDefinition = {
  key: string;
  label: string;
  description: string;
  help_text?: string | null;
  select_mode: "single" | "multi" | "range" | string;
  optional: boolean;
  allow_skip: boolean;
  ui_control: string;
  step_order: number;
  options: OnboardingOptionValue[];
};

export type OnboardingOptionsResponse = {
  version: string;
  fields: OnboardingFieldDefinition[];
};

export type ScoreBreakdownItem = {
  label: string;
  points: number;
};

export type RecommendationRequestSummary = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus: boolean;
  atmosphere: string[];
};

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  rank?: number;
  fit_label?: string;
  reasons: string[];
  explanation?: string | null;
  confidence_level?: "high" | "medium" | "exploratory" | string;
  matched_signals?: string[];
  penalized_signals?: string[];
  score_breakdown?: ScoreBreakdownItem[];
  suggested_dishes: string[];
  suggested_drinks: string[];
  active_event_matches?: string[];
};

export type RecommendationResponse = {
  mode: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: RecommendationRequestSummary;
  results: RecommendationItem[];
};

export type ExperienceRating = {
  id: number;
  category: string;
  score: number;
};

export type Experience = {
  id: number;
  user_id: number;
  restaurant_id: number | null;
  title: string | null;
  occasion: string | null;
  social_context: string | null;
  notes: string | null;
  overall_rating: number | null;
  created_at: string;
  ratings: ExperienceRating[];
};
EOF

python3 - <<'PY'
from pathlib import Path

path = Path("frontend/src/pages/RecommendationsPage.tsx")
text = path.read_text()

text = text.replace(
    '  suggested_drinks: string[];\n};',
    '  suggested_drinks: string[];\n  active_event_matches?: string[];\n};'
)

text = text.replace(
    '{ label: "Dessert", value: "dessert" },',
    '{ label: "Dessert", value: "dessert" },\n  { label: "Fast food", value: "fast food" },'
)

old_tags = """  const tagValues = [
    ...suggestedDishes.map((dish) => `dish: ${dish}`),
    ...suggestedDrinks.map((drink) => `drink: ${drink}`)
  ].slice(0, 4);
"""
new_tags = """  const activeEventMatches = item.active_event_matches ?? [];

  const tagValues = [
    ...activeEventMatches.map((eventLabel) => `event: ${eventLabel}`),
    ...suggestedDishes.map((dish) => `dish: ${dish}`),
    ...suggestedDrinks.map((drink) => `drink: ${drink}`)
  ].slice(0, 5);
"""
text = text.replace(old_tags, new_tags)

path.write_text(text)
print("Patched frontend RecommendationsPage.tsx")
PY

cat > "$FRONTEND_DIR/src/pages/RestaurantDetailPage.tsx" <<'EOF'
import { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { MenuItem, RestaurantDetail, VenueEvent } from "../types";

function formatEventTiming(event: VenueEvent): string {
  const parts: string[] = [];

  if (event.day_of_week) {
    parts.push(event.day_of_week);
  }

  if (event.event_date) {
    parts.push(event.event_date);
  }

  if (event.start_time || event.end_time) {
    parts.push([event.start_time, event.end_time].filter(Boolean).join(" - "));
  }

  if (event.recurrence) {
    parts.push(event.recurrence);
  }

  return parts.join(" • ");
}

export default function RestaurantDetailPage() {
  const { restaurantId } = useParams<{ restaurantId: string }>();

  const [restaurant, setRestaurant] = useState<RestaurantDetail | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurant() {
      if (!restaurantId) {
        setError("No restaurant was selected.");
        setLoading(false);
        return;
      }

      try {
        setError("");
        setLoading(true);
        const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
        if (!cancelled) {
          setRestaurant(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load this venue.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadRestaurant();

    return () => {
      cancelled = true;
    };
  }, [restaurantId]);

  const summaryText = useMemo(() => {
    if (!restaurant) {
      return "Open a venue from the restaurant catalog to inspect its menu, tags, atmosphere, and recommendation signals.";
    }

    return restaurant.description || "No summary is available for this venue yet.";
  }, [restaurant]);

  const highlightedMenuItems = useMemo<MenuItem[]>(
    () =>
      restaurant?.menu_items.filter(
        (item) => item.is_dish_highlight || item.is_signature || Boolean(item.recommendation_hint)
      ) || [],
    [restaurant]
  );

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Restaurant detail</p>
        <h1 className="page-title">{restaurant?.name || "Venue overview"}</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Dedicated venue pages make it easier to inspect a restaurant without crowding the full restaurant listing page.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Link to="/restaurants">
          <Button variant="ghost">Back to restaurants</Button>
        </Link>
        <Link to="/recommendations">
          <Button variant="secondary">Go to recommendations</Button>
        </Link>
      </div>

      <Card
        title={restaurant?.name || "Venue detail"}
        subtitle={summaryText}
        actions={restaurant ? <Badge tone="accent">{restaurant.price_tier}</Badge> : <Badge>Preview</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading venue detail</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling restaurant information from the backend.
            </p>
          </div>
        ) : !restaurant ? (
          <div className="item">
            <strong>No venue selected</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Return to the restaurant list and choose a venue.
            </p>
          </div>
        ) : (
          <div className="list">
            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Venue profile</p>
              <strong>Atmosphere and positioning</strong>
              <p className="muted">
                {restaurant.city} • {restaurant.price_tier} • {restaurant.atmosphere || "No atmosphere"} • {restaurant.pace || "No pace"} • {restaurant.social_style || "No social style"}
              </p>
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                {restaurant.is_fast_food ? <Badge tone="warning">Fast food</Badge> : null}
                {restaurant.has_live_music ? <Badge tone="accent">Live music</Badge> : null}
                {restaurant.has_trivia_night ? <Badge tone="accent">Trivia</Badge> : null}
                {restaurant.tags.map((tag) => (
                  <Badge key={`${tag.category}-${tag.name}`}>{tag.category}: {tag.name}</Badge>
                ))}
              </div>
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Venue events</p>
              <strong>Current and recurring event signals</strong>
              {restaurant.events.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No structured venue events are currently saved for this restaurant.
                </p>
              ) : (
                <div className="event-card-grid" style={{ marginTop: "0.8rem" }}>
                  {restaurant.events.map((event) => (
                    <div key={event.id} className="event-detail-card">
                      <div style={{ display: "flex", justifyContent: "space-between", gap: "0.6rem", flexWrap: "wrap" }}>
                        <strong>{event.name}</strong>
                        <Badge tone={event.is_active ? "success" : "default"}>
                          {event.is_active ? "Active" : "Inactive"}
                        </Badge>
                      </div>
                      <p className="muted" style={{ margin: "0.45rem 0" }}>
                        {event.description || "No event description available."}
                      </p>
                      <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                        <Badge tone="accent">{event.event_type}</Badge>
                        {formatEventTiming(event) ? <Badge>{formatEventTiming(event)}</Badge> : null}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Recommended menu signals</p>
              <strong>Highlighted dishes and strong order candidates</strong>
              {highlightedMenuItems.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No highlighted dish metadata was returned for this venue.
                </p>
              ) : (
                <div className="list" style={{ marginTop: "0.8rem" }}>
                  {highlightedMenuItems.map((item) => (
                    <div className="item" key={`highlight-${item.id}`}>
                      <div style={{ display: "flex", justifyContent: "space-between", gap: "0.75rem", flexWrap: "wrap" }}>
                        <strong>{item.name}</strong>
                        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                          {item.is_signature ? <Badge tone="success">Signature</Badge> : null}
                          {item.is_dish_highlight ? <Badge tone="accent">Recommended</Badge> : null}
                        </div>
                      </div>
                      <p className="muted" style={{ margin: "0.45rem 0" }}>
                        {item.category} • Price: {item.price ?? "-"}
                      </p>
                      <p style={{ marginBottom: item.recommendation_hint ? "0.45rem" : 0 }}>
                        {item.description || "No description"}
                      </p>
                      {item.recommendation_hint ? (
                        <p className="muted" style={{ marginBottom: 0 }}>
                          Why it stands out: {item.recommendation_hint}
                        </p>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Full menu</p>
              <strong>Menu items</strong>
              {restaurant.menu_items.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No menu items were returned for this venue.
                </p>
              ) : (
                <div className="list" style={{ marginTop: "0.8rem" }}>
                  {restaurant.menu_items.map((item) => (
                    <div className="item" key={item.id}>
                      <strong>{item.name}</strong>
                      <p className="muted">
                        {item.category} • Price: {item.price ?? "-"} • {item.is_signature ? "Signature item" : "Standard item"}
                      </p>
                      <p style={{ marginBottom: item.tags.length > 0 ? "0.8rem" : 0 }}>
                        {item.description || "No description"}
                      </p>
                      {item.tags.length > 0 ? (
                        <div>
                          {item.tags.map((tag) => (
                            <Badge key={`${item.id}-${tag.id}`} tone="accent">
                              {tag.name}
                            </Badge>
                          ))}
                        </div>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" <<'EOF'
import { Link, NavLink, type NavLinkRenderProps } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "DB" },
  { to: "/profile", label: "Profile", short: "PF" },
  { to: "/recommendations", label: "Recommendations", short: "RC" },
  { to: "/restaurants", label: "Restaurants", short: "RS" },
  { to: "/experiences", label: "Experiences", short: "EX" }
];

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">SV</div>

        <div>
          <p className="sidebar-eyebrow">Personal dining guide</p>
          <h1 className="sidebar-brand">SAVR</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Current user</p>
          <span className="sidebar-online-pill">Online</span>
        </div>

        <strong className="sidebar-user-name">{userName || "Guest user"}</strong>

        <p className="muted">
          Explore restaurants, update your profile, reuse saved presets, and discover dining experiences that fit your style.
        </p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }: NavLinkRenderProps) =>
              ["sidebar-link", isActive ? "sidebar-link--active" : ""]
                .filter(Boolean)
                .join(" ")
            }
          >
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-quick-actions">
        <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/profile/preferences">
          Edit preferences
        </Link>
        <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/recommendations">
          Manage presets
        </Link>
        <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/experiences/new">
          Log an experience
        </Link>
      </div>

      <div className="sidebar-footer">
        <button
          className="ui-button ui-button--ghost ui-button--md ui-button--full sidebar-logout"
          type="button"
          onClick={onLogout}
        >
          Logout
        </button>
      </div>
    </aside>
  );
}
EOF

python3 - <<'PY'
from pathlib import Path

styles_path = Path("frontend/src/styles.css")
content = styles_path.read_text()
marker = "/* PATCH5_EVENTS_AND_ENRICHMENT_START */"

if marker not in content:
    content += """

/* PATCH5_EVENTS_AND_ENRICHMENT_START */
.event-card-grid {
  display: grid;
  gap: 0.85rem;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
}

.event-detail-card {
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 1rem;
  padding: 0.9rem;
  background: rgba(15, 23, 42, 0.32);
}

.sidebar-quick-actions {
  display: grid;
  gap: 0.65rem;
}

.compact-run-card,
.event-detail-card {
  box-shadow: 0 10px 24px rgba(2, 6, 23, 0.12);
}
/* PATCH5_EVENTS_AND_ENRICHMENT_END */
"""
    styles_path.write_text(content)
    print("Patch 5 styles appended.")
else:
    print("Patch 5 styles already present.")
PY

echo "Running backend syntax verification..."
cd "$BACKEND_DIR"
python3 -m compileall app

echo "Running frontend TypeScript verification..."
cd "$FRONTEND_DIR"
npx tsc --noEmit

echo "Patch 5 applied successfully."
echo "Modified backend and frontend files for event-aware recommendations, fast-food surfacing, dish enrichment, and account navigation polish."
