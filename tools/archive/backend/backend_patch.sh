#!/bin/bash

echo "Applying backend stabilization patch..."

############################################
# Fix Pydantic ORM serialization
############################################

cat > app/schemas/base_schema.py << 'EOF'
from pydantic import BaseModel, ConfigDict

class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
EOF


############################################
# Fix User Schema
############################################

cat > app/schemas/user_schema.py << 'EOF'
from datetime import datetime
from pydantic import EmailStr
from .base_schema import ORMModel

class UserResponse(ORMModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    is_active: bool
    onboarding_completed: bool
    created_at: datetime


class AuthUserResponse(ORMModel):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    onboarding_completed: bool
EOF


############################################
# Seed default user script
############################################

cat > app/db/seed_user.py << 'EOF'
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
EOF


############################################
# Fix auth dependency safety
############################################

cat > app/dependencies/auth_dependencies.py << 'EOF'
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import decode_token
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):

    payload = decode_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token"
        )

    user_id = payload.get("sub")

    user = db.query(User).filter(User.id == user_id).first()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user
EOF


############################################
# Clear cache
############################################

echo "Clearing __pycache__"
find . -name "__pycache__" -type d -exec rm -r {} +


############################################
# Run seed script
############################################

echo "Seeding default user..."
python3 -m app.db.seed_user


echo "Patch complete."
echo ""
echo "You can now restart the backend:"
echo "uvicorn app.main:app --reload"
