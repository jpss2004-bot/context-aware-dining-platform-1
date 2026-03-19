from sqlalchemy import delete, func
from sqlalchemy.orm import Session

from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models.restaurant import (
    MenuItem,
    Restaurant,
    Tag,
    experience_menu_items,
    menu_item_tags,
    restaurant_tags,
)
from app.db.seed_real_wolfville import RESTAURANTS, upsert_restaurant


def reset_and_seed() -> None:
    init_db()
    db: Session = SessionLocal()

    try:
        print("clearing restaurant-related tables...")

        db.execute(delete(experience_menu_items))
        db.execute(delete(menu_item_tags))
        db.execute(delete(restaurant_tags))

        db.query(MenuItem).delete(synchronize_session=False)
        db.query(Restaurant).delete(synchronize_session=False)
        db.query(Tag).delete(synchronize_session=False)

        db.commit()

        print("seeding canonical wolfville catalog...")
        for item in RESTAURANTS:
            upsert_restaurant(db, item)

        db.commit()

        restaurant_count = db.query(Restaurant).count()
        menu_count = db.query(MenuItem).count()
        tag_count = db.query(Tag).count()

        duplicate_names = (
            db.query(Restaurant.name, func.count(Restaurant.id))
            .group_by(Restaurant.name)
            .having(func.count(Restaurant.id) > 1)
            .all()
        )

        print(f"seed complete: {restaurant_count} restaurants, {menu_count} menu items, {tag_count} tags")

        if duplicate_names:
            print("duplicate restaurant names still detected:")
            for name, count in duplicate_names:
                print(f" - {name}: {count}")
            raise RuntimeError("duplicate restaurant names remain after reseed")

        print("catalog is clean: no duplicate restaurant names found")
        print("patch 1 foundation columns are available for richer restaurant metadata and onboarding budget fields")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    reset_and_seed()
