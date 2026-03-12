from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.user import User
from app.core.security import hash_password


DEFAULT_EMAIL = "jp@example.com"
DEFAULT_PASSWORD = "StrongPass123"


def seed_default_user() -> None:
    db: Session = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == DEFAULT_EMAIL.lower()).first()

        if existing:
            print(f"default user already exists: {DEFAULT_EMAIL}")
            return

        user = User(
            first_name="JP",
            last_name="Samano",
            email=DEFAULT_EMAIL.lower(),
            hashed_password=hash_password(DEFAULT_PASSWORD),
            is_active=True,
            onboarding_completed=False,
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        print(f"default user created: {DEFAULT_EMAIL}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_default_user()
