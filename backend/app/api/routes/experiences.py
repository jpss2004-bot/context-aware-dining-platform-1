from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.experience import ExperienceCreateRequest, ExperienceResponse
from app.services.experience_service import ExperienceService

router = APIRouter()


@router.post("", response_model=ExperienceResponse)
def create_experience(
    payload: ExperienceCreateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return ExperienceService(db).create_experience(current_user, payload)


@router.get("", response_model=list[ExperienceResponse])
def list_my_experiences(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return ExperienceService(db).list_user_experiences(current_user)
