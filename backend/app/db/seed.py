from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.restaurant import MenuItem, Restaurant, Tag


def seed_db() -> None:
    db: Session = SessionLocal()

    try:
        existing = db.query(Restaurant).first()
        if existing:
            print("seed skipped: restaurants already exist")
            return

        cozy = Tag(name="cozy", category="atmosphere")
        lively = Tag(name="lively", category="atmosphere")
        romantic = Tag(name="romantic", category="occasion")
        cocktails = Tag(name="cocktails", category="drinks")
        pasta = Tag(name="pasta", category="cuisine")
        comfort = Tag(name="comfort-food", category="style")
        quick = Tag(name="quick-bite", category="style")
        group_friendly = Tag(name="group-friendly", category="social")
        quiet = Tag(name="quiet", category="social")

        db.add_all([cozy, lively, romantic, cocktails, pasta, comfort, quick, group_friendly, quiet])
        db.flush()

        restaurants = [
            Restaurant(
                name="Luna Trattoria",
                description="Warm Italian spot with handmade pasta and a relaxed romantic mood.",
                city="Wolfville",
                price_tier="$$",
                atmosphere="cozy",
                pace="leisurely",
                social_style="romantic",
                serves_alcohol=True,
                tags=[cozy, romantic, pasta, comfort],
            ),
            Restaurant(
                name="North End Social",
                description="Energetic small-plates venue with cocktails and a lively evening crowd.",
                city="Wolfville",
                price_tier="$$$",
                atmosphere="lively",
                pace="moderate",
                social_style="group",
                serves_alcohol=True,
                tags=[lively, cocktails, group_friendly],
            ),
            Restaurant(
                name="Campus Quick Bowl",
                description="Fast casual bowls and wraps for quick solo meals or easy takeout.",
                city="Wolfville",
                price_tier="$",
                atmosphere="casual",
                pace="fast",
                social_style="solo",
                serves_alcohol=False,
                tags=[quick, quiet],
            ),
        ]

        db.add_all(restaurants)
        db.flush()

        menu_items = [
            MenuItem(
                restaurant_id=restaurants[0].id,
                name="Truffle Mushroom Tagliatelle",
                category="dish",
                price=21.50,
                description="Rich pasta with mushrooms and parmesan.",
                is_signature=True,
                tags=[pasta, comfort],
            ),
            MenuItem(
                restaurant_id=restaurants[0].id,
                name="House Red Wine",
                category="drink",
                price=10.00,
                description="Medium-bodied red wine by the glass.",
                is_signature=False,
                tags=[romantic],
            ),
            MenuItem(
                restaurant_id=restaurants[1].id,
                name="Smoked Chili Sliders",
                category="dish",
                price=16.00,
                description="Shareable sliders with smoky chili sauce.",
                is_signature=True,
                tags=[group_friendly],
            ),
            MenuItem(
                restaurant_id=restaurants[1].id,
                name="Citrus Gin Fizz",
                category="drink",
                price=14.00,
                description="Bright gin cocktail with citrus and herbs.",
                is_signature=True,
                tags=[cocktails, lively],
            ),
            MenuItem(
                restaurant_id=restaurants[2].id,
                name="Chicken Rice Bowl",
                category="dish",
                price=12.50,
                description="Fast, filling rice bowl with grilled chicken.",
                is_signature=True,
                tags=[quick],
            ),
            MenuItem(
                restaurant_id=restaurants[2].id,
                name="Iced Matcha",
                category="drink",
                price=5.50,
                description="Cold matcha with milk over ice.",
                is_signature=False,
                tags=[quiet],
            ),
        ]

        db.add_all(menu_items)
        db.commit()
        print("database seeded successfully")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_db()
