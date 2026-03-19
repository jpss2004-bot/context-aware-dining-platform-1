from __future__ import annotations

from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine


RESTAURANT_COLUMN_DEFINITIONS = {
    "town": "VARCHAR(100)",
    "region": "VARCHAR(100)",
    "address": "VARCHAR(255)",
    "category": "VARCHAR(100)",
    "subcategory": "VARCHAR(100)",
    "price_min_per_person": "FLOAT",
    "price_max_per_person": "FLOAT",
    "offers_dine_in": "BOOLEAN",
    "offers_takeout": "BOOLEAN",
    "offers_delivery": "BOOLEAN",
    "accepts_reservations": "BOOLEAN",
    "supports_brunch": "BOOLEAN",
    "supports_lunch": "BOOLEAN",
    "supports_dinner": "BOOLEAN",
    "supports_dessert": "BOOLEAN",
    "supports_coffee": "BOOLEAN",
    "is_fast_food": "BOOLEAN",
    "is_family_friendly": "BOOLEAN",
    "is_date_night": "BOOLEAN",
    "is_student_friendly": "BOOLEAN",
    "is_quick_bite": "BOOLEAN",
    "has_live_music": "BOOLEAN",
    "has_trivia_night": "BOOLEAN",
    "event_notes": "TEXT",
    "source_url": "VARCHAR(500)",
    "source_notes": "TEXT",
}

MENU_ITEM_COLUMN_DEFINITIONS = {
    "meal_period": "VARCHAR(50)",
    "recommendation_hint": "TEXT",
    "is_dish_highlight": "BOOLEAN NOT NULL DEFAULT 0",
}

PREFERENCE_COLUMN_DEFINITIONS = {
    "budget_min_per_person": "FLOAT",
    "budget_max_per_person": "FLOAT",
    "onboarding_version": "VARCHAR(50)",
}


def _existing_columns(engine: Engine, table_name: str) -> set[str]:
    inspector = inspect(engine)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _add_missing_columns(engine: Engine, table_name: str, definitions: dict[str, str]) -> list[str]:
    existing = _existing_columns(engine, table_name)
    added: list[str] = []

    with engine.begin() as connection:
      for column_name, ddl in definitions.items():
            if column_name in existing:
                continue
            connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {ddl}"))
            added.append(column_name)

    return added


def _create_venue_events_table(engine: Engine) -> list[str]:
    inspector = inspect(engine)
    if "venue_events" in inspector.get_table_names():
        return []

    create_sql = """
    CREATE TABLE venue_events (
        id INTEGER PRIMARY KEY,
        restaurant_id INTEGER NOT NULL,
        name VARCHAR(200) NOT NULL,
        event_type VARCHAR(100) NOT NULL,
        description TEXT,
        day_of_week VARCHAR(20),
        event_date DATE,
        recurrence VARCHAR(50),
        start_time TIME,
        end_time TIME,
        is_active BOOLEAN NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    )
    """
    create_index_sql = """
    CREATE INDEX IF NOT EXISTS ix_venue_events_restaurant_id ON venue_events (restaurant_id)
    """

    with engine.begin() as connection:
        connection.execute(text(create_sql))
        connection.execute(text(create_index_sql))

    return ["venue_events"]


def apply_patch1_schema_upgrades(engine: Engine) -> dict[str, list[str]]:
    return {
        "restaurants": _add_missing_columns(engine, "restaurants", RESTAURANT_COLUMN_DEFINITIONS),
        "menu_items": _add_missing_columns(engine, "menu_items", MENU_ITEM_COLUMN_DEFINITIONS),
        "preferences": _add_missing_columns(engine, "preferences", PREFERENCE_COLUMN_DEFINITIONS),
    }


def apply_patch5_event_schema(engine: Engine) -> dict[str, list[str]]:
    return {
        "tables": _create_venue_events_table(engine),
    }
