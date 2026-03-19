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
