from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.onboarding import (
    OnboardingOptionsResponse,
    OnboardingRequest,
    OnboardingResponse,
    OnboardingStateResponse,
)
from app.services.onboarding_service import OnboardingService

router = APIRouter()


@router.get("", response_model=OnboardingStateResponse)
def get_onboarding(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return OnboardingService(db).get_onboarding_state(current_user)


@router.get("/options", response_model=OnboardingOptionsResponse)
def get_onboarding_options(
    db: Session = Depends(get_db),
):
    return OnboardingService(db).get_onboarding_options()


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
