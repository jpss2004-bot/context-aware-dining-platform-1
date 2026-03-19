from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class PresetSelectionPayload(BaseModel):
    outing_type: Optional[str] = None
    mood: Optional[str] = None
    budget: Optional[str] = None
    pace: Optional[str] = None
    social_context: Optional[str] = None
    preferred_cuisines: list[str] = Field(default_factory=list)
    drinks_focus: Optional[bool] = None
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
    include_dish_hints: Optional[bool] = None


class PresetResponse(BaseModel):
    preset_id: str
    owner_type: str
    owner_user_id: Optional[int] = None
    is_editable: bool
    name: str
    description: Optional[str] = None
    selection_payload: PresetSelectionPayload
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class CreateUserPresetRequest(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    description: Optional[str] = Field(default=None, max_length=500)
    selection_payload: PresetSelectionPayload


class UpdateUserPresetRequest(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=150)
    description: Optional[str] = Field(default=None, max_length=500)
    selection_payload: Optional[PresetSelectionPayload] = None


class PresetApplyResponse(BaseModel):
    preset: PresetResponse
    builder_payload: PresetSelectionPayload
    banner_message: str
    can_customize: bool = True


class PresetDeleteResponse(BaseModel):
    message: str
    deleted_preset_id: str
