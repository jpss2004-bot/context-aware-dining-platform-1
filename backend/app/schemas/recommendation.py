from pydantic import BaseModel, Field


class BuildYourNightRequest(BaseModel):
    outing_type: str = Field(min_length=1, max_length=100)
    mood: str = None
    budget: str = None
    pace: str = None
    social_context: str = None
    preferred_cuisines: list[str] = Field(default_factory=list)
    drinks_focus: bool = False
    atmosphere: list[str] = Field(default_factory=list)


class DescribeYourNightRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=1000)


class SurpriseMeRequest(BaseModel):
    include_drinks: bool = False


class RecommendationItem(BaseModel):
    restaurant_id: int
    restaurant_name: str
    score: float
    reasons: list[str]
    suggested_dishes: list[str] = Field(default_factory=list)
    suggested_drinks: list[str] = Field(default_factory=list)


class RecommendationResponse(BaseModel):
    mode: str
    results: list[RecommendationItem]
    
