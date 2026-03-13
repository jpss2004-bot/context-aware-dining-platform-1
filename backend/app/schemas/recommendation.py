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
    engine_version: str = "phase45"
    generated_at: str
    request_summary: RecommendationRequestSummary
    results: list[RecommendationItem]
