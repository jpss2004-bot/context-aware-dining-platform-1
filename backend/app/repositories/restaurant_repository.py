from sqlalchemy.orm import Session, joinedload

from app.models.restaurant import MenuItem, Restaurant, Tag, VenueEvent


class RestaurantRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_restaurants(self):
        return (
            self.db.query(Restaurant)
            .options(joinedload(Restaurant.events))
            .order_by(Restaurant.name.asc())
            .all()
        )

    def get_restaurant_by_id(self, restaurant_id: int):
        return (
            self.db.query(Restaurant)
            .options(
                joinedload(Restaurant.tags),
                joinedload(Restaurant.events),
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
                joinedload(Restaurant.events),
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

    def list_events(self):
        return self.db.query(VenueEvent).order_by(VenueEvent.name.asc()).all()
