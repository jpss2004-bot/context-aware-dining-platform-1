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
