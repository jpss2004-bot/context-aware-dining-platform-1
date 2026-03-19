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


class RecommendationResponse(BaseModel):
    mode: str
    engine_version: str = "phase4-presets-v1"
    generated_at: str
    request_summary: RecommendationRequestSummary
    results: list[RecommendationItem]
