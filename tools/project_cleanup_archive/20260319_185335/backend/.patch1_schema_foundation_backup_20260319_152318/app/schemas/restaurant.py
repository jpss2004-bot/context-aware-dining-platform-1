from typing import Optional

from pydantic import BaseModel, Field


class TagResponse(BaseModel):
    id: int
    name: str
    category: str

    model_config = {"from_attributes": True}


class MenuItemResponse(BaseModel):
    id: int
    restaurant_id: int
    name: str
    category: str
    price: Optional[float]
    description: Optional[str]
    is_signature: bool
    tags: list[TagResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    city: str
    price_tier: str
    atmosphere: Optional[str]
    pace: Optional[str]
    social_style: Optional[str]
    serves_alcohol: bool

    model_config = {"from_attributes": True}


class RestaurantDetailResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    city: str
    price_tier: str
    atmosphere: Optional[str]
    pace: Optional[str]
    social_style: Optional[str]
    serves_alcohol: bool
    tags: list[TagResponse] = Field(default_factory=list)
    menu_items: list[MenuItemResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}
