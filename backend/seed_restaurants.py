from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.restaurant import Restaurant
from app.models.restaurant import MenuItem


restaurants = [
    {
        "name": "The Noodle Guy",
        "description": "Casual Asian noodle bar with ramen and stir fry.",
        "city": "Wolfville",
        "price_tier": "$$",
        "atmosphere": "casual",
        "pace": "fast",
        "social_style": "friends",
        "serves_alcohol": True,
        "menu": [
            ("Tonkotsu Ramen", "ramen", 16),
            ("Spicy Miso Ramen", "ramen", 17),
            ("Pork Gyoza", "appetizer", 8),
        ],
    },
    {
        "name": "Troy Restaurant",
        "description": "Mediterranean street food and donairs.",
        "city": "Wolfville",
        "price_tier": "$",
        "atmosphere": "casual",
        "pace": "fast",
        "social_style": "friends",
        "serves_alcohol": False,
        "menu": [
            ("Chicken Shawarma", "wrap", 12),
            ("Donair Plate", "plate", 15),
        ],
    },
    {
        "name": "Juniper Food + Wine",
        "description": "Fine dining with seasonal ingredients.",
        "city": "Wolfville",
        "price_tier": "$$$",
        "atmosphere": "romantic",
        "pace": "slow",
        "social_style": "date",
        "serves_alcohol": True,
        "menu": [
            ("Scallops", "seafood", 24),
            ("Duck Breast", "entree", 32),
        ],
    },
    {
        "name": "Paddy's Pub",
        "description": "Lively pub with beer and comfort food.",
        "city": "Wolfville",
        "price_tier": "$$",
        "atmosphere": "lively",
        "pace": "medium",
        "social_style": "friends",
        "serves_alcohol": True,
        "menu": [
            ("Fish and Chips", "pub", 18),
            ("Burger", "pub", 16),
        ],
    },
]


def seed():
    db: Session = SessionLocal()

    existing = db.query(Restaurant).count()

    if existing > 0:
        print("restaurants already exist")
        return

    for r in restaurants:
        restaurant = Restaurant(
            name=r["name"],
            description=r["description"],
            city=r["city"],
            price_tier=r["price_tier"],
            atmosphere=r["atmosphere"],
            pace=r["pace"],
            social_style=r["social_style"],
            serves_alcohol=r["serves_alcohol"],
        )

        db.add(restaurant)
        db.flush()

        for item in r["menu"]:
            menu_item = MenuItem(
                restaurant_id=restaurant.id,
                name=item[0],
                category=item[1],
                price=item[2],
                description=None,
                is_signature=False,
            )
            db.add(menu_item)

    db.commit()

    print("restaurants seeded")


if __name__ == "__main__":
    seed()
