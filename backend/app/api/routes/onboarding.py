from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.onboarding import OnboardingRequest, OnboardingResponse
from app.services.onboarding_service import OnboardingService

router = APIRouter()


@router.post("", response_model=OnboardingResponse)
def submit_onboarding(
    payload: OnboardingRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    updated_user = OnboardingService(db).save_onboarding(current_user, payload)
    return OnboardingResponse(
        message="Onboarding saved successfully",
        onboarding_completed=updated_user.onboarding_completed,
    )
