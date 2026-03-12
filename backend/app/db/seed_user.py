from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.user import User
from app.core.security import hash_password

def seed():
    db: Session = SessionLocal()

    existing = db.query(User).filter(User.email=="jp@example.com").first()

    if existing:
        print("User already exists.")
        return

    user = User(
        first_name="JP",
        last_name="Samano",
        email="jp@example.com",
        hashed_password=hash_password("StrongPass123"),
        is_active=True,
        onboarding_completed=False
    )

    db.add(user)
    db.commit()
    print("Default user created.")

if __name__ == "__main__":
    seed()
