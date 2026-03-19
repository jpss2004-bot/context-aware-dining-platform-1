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
