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
