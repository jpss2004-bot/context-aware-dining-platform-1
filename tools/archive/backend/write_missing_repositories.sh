#!/bin/bash

set -e

if [ ! -d "app/repositories" ]; then
  mkdir -p app/repositories
fi

cat > app/repositories/__init__.py <<'PY'
# repositories package
PY

cat > app/repositories/user_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.user import User, UserPreference, UserProfile


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str):
        return (
            self.db.query(User)
            .options(joinedload(User.profile), joinedload(User.preference))
            .filter(User.email == email.lower())
            .first()
        )

    def get_by_id(self, user_id: int):
        return (
            self.db.query(User)
            .options(joinedload(User.profile), joinedload(User.preference))
            .filter(User.id == user_id)
            .first()
        )

    def create_user(self, first_name: str, last_name: str, email: str, hashed_password: str):
        user = User(
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            email=email.lower().strip(),
            hashed_password=hashed_password,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def upsert_preferences(
        self,
        user_id: int,
        dietary_restrictions: list[str],
        cuisine_preferences: list[str],
        texture_preferences: list[str],
        dining_pace_preferences: list[str],
        social_preferences: list[str],
        drink_preferences: list[str],
        atmosphere_preferences: list[str],
        spice_tolerance: str = None,
        price_sensitivity: str = None,
    ):
        preference = self.db.query(UserPreference).filter(UserPreference.user_id == user_id).first()

        if preference is None:
            preference = UserPreference(user_id=user_id)
            self.db.add(preference)

        preference.dietary_restrictions = dietary_restrictions
        preference.cuisine_preferences = cuisine_preferences
        preference.texture_preferences = texture_preferences
        preference.dining_pace_preferences = dining_pace_preferences
        preference.social_preferences = social_preferences
        preference.drink_preferences = drink_preferences
        preference.atmosphere_preferences = atmosphere_preferences
        preference.spice_tolerance = spice_tolerance
        preference.price_sensitivity = price_sensitivity

        self.db.commit()
        self.db.refresh(preference)
        return preference

    def upsert_profile(
        self,
        user_id: int,
        bio: str = None,
        favorite_dining_experiences: list[str] = None,
        favorite_restaurants: list[str] = None,
    ):
        profile = self.db.query(UserProfile).filter(UserProfile.user_id == user_id).first()

        if profile is None:
            profile = UserProfile(user_id=user_id)
            self.db.add(profile)

        profile.bio = bio
        profile.favorite_dining_experiences = favorite_dining_experiences or []
        profile.favorite_restaurants = favorite_restaurants or []

        self.db.commit()
        self.db.refresh(profile)
        return profile

    def mark_onboarding_complete(self, user_id: int):
        user = self.db.query(User).filter(User.id == user_id).first()
        if user is None:
            return None

        user.onboarding_completed = True
        self.db.commit()
        self.db.refresh(user)
        return user
PY

cat > app/repositories/restaurant_repository.py <<'PY'
from sqlalchemy.orm import Session, joinedload

from app.models.restaurant import MenuItem, Restaurant, Tag


class RestaurantRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_restaurants(self):
        return self.db.query(Restaurant).order_by(Restaurant.name.asc()).all()

    def get_restaurant_by_id(self, restaurant_id: int):
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.menu_items).joinedload(MenuItem.tags),
            )
            .filter(Restaurant.id == restaurant_id)
            .first()
        )

    def list_restaurants_with_details(self):
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.menu_items).joinedload(MenuItem.tags),
            )
            .order_by(Restaurant.name.asc())
            .all()
        )

    def get_menu_items_by_ids(self, menu_item_ids: list[int]):
        if not menu_item_ids:
            return []

        return (
            self.db.query(MenuItem)
            .options(joinedload(MenuItem.tags))
            .filter(MenuItem.id.in_(menu_item_ids))
            .all()
        )

    def list_tags(self):
        return self.db.query(Tag).order_by(Tag.category.asc(), Tag.name.asc()).all()
PY

cat > app/repositories/experience_repository.py <<'PY'
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
PY

echo "missing repositories written successfully"
