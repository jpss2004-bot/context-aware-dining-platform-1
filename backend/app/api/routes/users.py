from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.account import SavedContentResponse, UserDashboardResponse
from app.schemas.user import UserResponse
from app.services.account_service import AccountService

router = APIRouter()


@router.get("/me/dashboard", response_model=UserDashboardResponse)
def get_current_user_dashboard(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return AccountService(db).get_dashboard(current_user)


@router.get("/me/saved-content", response_model=SavedContentResponse)
def get_current_user_saved_content(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return AccountService(db).get_saved_content(current_user)


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user=Depends(get_current_user)):
    return current_user
