from app.db.base import Base
from app.db.schema_upgrade import apply_patch1_schema_upgrades, apply_patch5_event_schema
from app.db.session import engine
from app.models import experience, preset, restaurant, user  # noqa: F401


def init_db() -> None:
    Base.metadata.create_all(bind=engine)
    apply_patch1_schema_upgrades(engine)
    apply_patch5_event_schema(engine)


if __name__ == "__main__":
    init_db()
    print("database tables created successfully")
