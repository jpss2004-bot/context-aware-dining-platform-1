from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.experience_repository import ExperienceRepository
from app.repositories.restaurant_repository import RestaurantRepository
from app.schemas.experience import ExperienceCreateRequest


class ExperienceService:
    def __init__(self, db: Session):
        self.db = db
        self.experience_repository = ExperienceRepository(db)
        self.restaurant_repository = RestaurantRepository(db)

    def create_experience(self, user: User, payload: ExperienceCreateRequest):
        if payload.restaurant_id is not None:
            restaurant = self.restaurant_repository.get_restaurant_by_id(payload.restaurant_id)
            if restaurant is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Restaurant not found",
                )

        menu_items = self.restaurant_repository.get_menu_items_by_ids(payload.menu_item_ids)

        return self.experience_repository.create_experience(
            user_id=user.id,
            restaurant_id=payload.restaurant_id,
            title=payload.title,
            occasion=payload.occasion,
            social_context=payload.social_context,
            notes=payload.notes,
            overall_rating=payload.overall_rating,
            menu_items=menu_items,
            ratings=[rating.model_dump() for rating in payload.ratings],
        )

    def list_user_experiences(self, user: User):
        return self.experience_repository.list_by_user_id(user.id)
