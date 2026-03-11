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
