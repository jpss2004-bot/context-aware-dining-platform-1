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
