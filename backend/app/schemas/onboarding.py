from typing import Optional

from pydantic import BaseModel, Field, field_validator, model_validator


def _normalize_string_list(values: list[str]) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()

    for value in values or []:
        normalized = " ".join(str(value).strip().split())
        lowered = normalized.lower()
        if not normalized or lowered in seen:
            continue
        cleaned.append(normalized)
        seen.add(lowered)

    return cleaned


class OnboardingOptionValue(BaseModel):
    value: str
    label: str
    description: Optional[str] = None


class OnboardingFieldDefinition(BaseModel):
    key: str
    label: str
    description: str
    help_text: Optional[str] = None
    select_mode: str
    optional: bool
    allow_skip: bool
    ui_control: str
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

    @field_validator(
        "dietary_restrictions",
        "cuisine_preferences",
        "texture_preferences",
        "dining_pace_preferences",
        "social_preferences",
        "drink_preferences",
        "atmosphere_preferences",
        "favorite_dining_experiences",
        "favorite_restaurants",
        mode="before",
    )
    @classmethod
    def normalize_list_fields(cls, value):
        if value is None:
            return []
        if not isinstance(value, list):
            return []
        return _normalize_string_list(value)

    @field_validator("bio", "spice_tolerance", "price_sensitivity", "onboarding_version", mode="before")
    @classmethod
    def normalize_optional_strings(cls, value):
        if value is None:
            return None
        normalized = " ".join(str(value).strip().split())
        return normalized or None

    @model_validator(mode="after")
    def validate_budget_range(self):
        if self.budget_min_per_person is not None and self.budget_min_per_person < 0:
            raise ValueError("budget_min_per_person cannot be negative")
        if self.budget_max_per_person is not None and self.budget_max_per_person < 0:
            raise ValueError("budget_max_per_person cannot be negative")
        if (
            self.budget_min_per_person is not None
            and self.budget_max_per_person is not None
            and self.budget_min_per_person > self.budget_max_per_person
        ):
            raise ValueError("budget_min_per_person cannot be greater than budget_max_per_person")
        return self


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
