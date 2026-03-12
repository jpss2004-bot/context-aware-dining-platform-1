#!/bin/bash

set -e

if [ ! -d "backend/app" ]; then
  echo "error: run this from inside the context-aware-dining-platform folder"
  exit 1
fi

cat > backend/app/api/routes/restaurants.py <<'PY'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.restaurant_repository import RestaurantRepository
from app.schemas.restaurant import RestaurantDetailResponse, RestaurantListResponse

router = APIRouter()


@router.get("", response_model=list[RestaurantListResponse])
def list_restaurants(db: Session = Depends(get_db)):
    return RestaurantRepository(db).list_restaurants()


@router.get("/{restaurant_id}", response_model=RestaurantDetailResponse)
def get_restaurant(restaurant_id: int, db: Session = Depends(get_db)):
    restaurant = RestaurantRepository(db).get_restaurant_by_id(restaurant_id)
    if restaurant is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restaurant not found",
        )
    return restaurant
PY

cat > backend/app/api/routes/experiences.py <<'PY'
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
PY

cat > backend/app/api/routes/recommendations.py <<'PY'
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
PY

echo "batch 5 files written successfully"
