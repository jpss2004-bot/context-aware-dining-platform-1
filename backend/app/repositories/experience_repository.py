from sqlalchemy.orm import Session, joinedload

from app.models.experience import Experience, ExperienceRating
from app.models.restaurant import MenuItem


class ExperienceRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_experience(
        self,
        user_id: int,
        restaurant_id: int = None,
        title: str = None,
        occasion: str = None,
        social_context: str = None,
        notes: str = None,
        overall_rating: float = None,
        menu_items: list[MenuItem] = None,
        ratings: list[dict] = None,
    ):
        experience = Experience(
            user_id=user_id,
            restaurant_id=restaurant_id,
            title=title,
            occasion=occasion,
            social_context=social_context,
            notes=notes,
            overall_rating=overall_rating,
        )

        experience.menu_items = menu_items or []

        self.db.add(experience)
        self.db.flush()

        for rating in ratings or []:
            self.db.add(
                ExperienceRating(
                    experience_id=experience.id,
                    category=rating["category"],
                    score=rating["score"],
                )
            )

        self.db.commit()
        self.db.refresh(experience)
        return self.get_by_id(experience.id)

    def get_by_id(self, experience_id: int):
        return (
            self.db.query(Experience)
            .options(joinedload(Experience.ratings), joinedload(Experience.menu_items))
            .filter(Experience.id == experience_id)
            .first()
        )

    def list_by_user_id(self, user_id: int):
        return (
            self.db.query(Experience)
            .options(joinedload(Experience.ratings), joinedload(Experience.menu_items))
            .filter(Experience.user_id == user_id)
            .order_by(Experience.created_at.desc())
            .all()
        )
