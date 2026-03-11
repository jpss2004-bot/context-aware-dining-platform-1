from datetime import datetime

from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    is_active: bool
    onboarding_completed: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserSummaryResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr

    model_config = {"from_attributes": True}
