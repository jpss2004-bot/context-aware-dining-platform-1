from sqlalchemy import text
from app.db.base import Base
from app.db.session import engine


def init_db() -> None:
    """
    Initialize database schema safely.

    This function:
    - resets any failed transaction state
    - creates all tables if they do not exist
    """

    with engine.connect() as connection:

        # reset failed transactions (important for postgres)
        try:
            connection.execute(text("ROLLBACK"))
        except Exception:
            pass

        # create tables
        Base.metadata.create_all(bind=engine)

    print("database tables created successfully")
