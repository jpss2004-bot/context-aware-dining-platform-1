from datetime import date, time
from typing import Optional

from pydantic import BaseModel, Field


class TagResponse(BaseModel):
    id: int
    name: str
    category: str

    model_config = {"from_attributes": True}


class VenueEventResponse(BaseModel):
    id: int
    restaurant_id: int
    name: str
    event_type: str
    description: Optional[str] = None
    day_of_week: Optional[str] = None
    event_date: Optional[date] = None
    recurrence: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    is_active: bool

    model_config = {"from_attributes": True}


class MenuItemResponse(BaseModel):
    id: int
    restaurant_id: int
    name: str
    category: str
    price: Optional[float]
    description: Optional[str]
    is_signature: bool
    meal_period: Optional[str] = None
    recommendation_hint: Optional[str] = None
    is_dish_highlight: bool = False
    tags: list[TagResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    city: str
    town: Optional[str] = None
    region: Optional[str] = None
    address: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    price_tier: str
    price_min_per_person: Optional[float] = None
    price_max_per_person: Optional[float] = None
    atmosphere: Optional[str]
    pace: Optional[str]
    social_style: Optional[str]
    serves_alcohol: bool
    offers_dine_in: Optional[bool] = None
    offers_takeout: Optional[bool] = None
    offers_delivery: Optional[bool] = None
    accepts_reservations: Optional[bool] = None
    supports_brunch: Optional[bool] = None
    supports_lunch: Optional[bool] = None
    supports_dinner: Optional[bool] = None
    supports_dessert: Optional[bool] = None
    supports_coffee: Optional[bool] = None
    is_fast_food: Optional[bool] = None
    is_family_friendly: Optional[bool] = None
    is_date_night: Optional[bool] = None
    is_student_friendly: Optional[bool] = None
    is_quick_bite: Optional[bool] = None
    has_live_music: Optional[bool] = None
    has_trivia_night: Optional[bool] = None
    event_notes: Optional[str] = None
    source_url: Optional[str] = None
    source_notes: Optional[str] = None

    model_config = {"from_attributes": True}


class RestaurantDetailResponse(RestaurantListResponse):
    tags: list[TagResponse] = Field(default_factory=list)
    menu_items: list[MenuItemResponse] = Field(default_factory=list)
    events: list[VenueEventResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}
