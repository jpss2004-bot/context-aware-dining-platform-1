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
