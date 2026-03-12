from datetime import datetime
from pydantic import EmailStr
from .base_schema import ORMModel

class UserResponse(ORMModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    is_active: bool
    onboarding_completed: bool
    created_at: datetime


class AuthUserResponse(ORMModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    onboarding_completed: bool
