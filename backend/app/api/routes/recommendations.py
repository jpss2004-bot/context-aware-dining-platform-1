from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.recommendation import (
    BuildYourNightRequest,
    DescribeYourNightRequest,
    RecommendationResponse,
    SurpriseMeRequest,
)
from app.services.recommendation_service import RecommendationService

router = APIRouter()


@router.post("/build-your-night", response_model=RecommendationResponse)
def build_your_night(
    payload: BuildYourNightRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return RecommendationService(db).build_your_night(current_user, payload)


@router.post("/describe-your-night", response_model=RecommendationResponse)
def describe_your_night(
    payload: DescribeYourNightRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return RecommendationService(db).describe_your_night(current_user, payload)


@router.post("/surprise-me", response_model=RecommendationResponse)
def surprise_me(
    payload: SurpriseMeRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return RecommendationService(db).surprise_me(current_user, payload)
