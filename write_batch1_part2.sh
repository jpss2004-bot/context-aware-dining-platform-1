#!/bin/bash

set -e

# make sure you are in the project root
if [ ! -d "backend/app" ]; then
  echo "error: run this from inside the context-aware-dining-platform folder"
  exit 1
fi

cat > backend/app/main.py <<'PY'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import settings

app = FastAPI(
    title="Context-Aware Dining Experience Recommendation Platform",
    version="1.0.0",
    description="API for authentication, onboarding, recommendations, and dining experience logging.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.backend_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", summary="Root health message")
def root() -> dict[str, str]:
    return {"message": "Context-Aware Dining API is running"}


@app.get("/health", summary="Simple health check")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(api_router, prefix="/api")
PY

cat > backend/app/api/__init__.py <<'PY'
# api package
PY

cat > backend/app/api/router.py <<'PY'
from fastapi import APIRouter

from app.api.routes import auth, experiences, onboarding, recommendations, restaurants, users

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
api_router.include_router(experiences.router, prefix="/experiences", tags=["experiences"])
api_router.include_router(restaurants.router, prefix="/restaurants", tags=["restaurants"])
PY

cat > backend/app/api/deps.py <<'PY'
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.security import decode_token
from app.db.session import get_db
from app.repositories.user_repository import UserRepository

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    payload = decode_token(token)

    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )

    user = UserRepository(db).get_by_email(payload["sub"])

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    return user
PY

cat > backend/app/api/routes/__init__.py <<'PY'
# api routes package
PY

cat > backend/app/core/__init__.py <<'PY'
# core package
PY

cat > backend/app/core/config.py <<'PY'
from functools import lru_cache
from typing import Any

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file="../.env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = Field(..., alias="DATABASE_URL")
    jwt_secret_key: str = Field(..., alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_access_token_expire_minutes: int = Field(
        default=120,
        alias="JWT_ACCESS_TOKEN_EXPIRE_MINUTES",
    )
    backend_cors_origins: list[str] = Field(
        default=["http://localhost:5173", "http://127.0.0.1:5173"],
        alias="BACKEND_CORS_ORIGINS",
    )

    @field_validator("backend_cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: Any) -> list[str]:
        if isinstance(value, list):
            return value
        if isinstance(value, str):
            cleaned = value.strip()
            if cleaned.startswith("[") and cleaned.endswith("]"):
                import json
                return json.loads(cleaned)
            return [item.strip() for item in cleaned.split(",") if item.strip()]
        raise ValueError("Invalid BACKEND_CORS_ORIGINS format")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
PY

cat > backend/app/core/security.py <<'PY'
from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return password_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return password_context.verify(plain_password, hashed_password)


def create_access_token(
    subject: str,
    expires_delta: timedelta | None = None,
) -> str:
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.jwt_access_token_expire_minutes)
    )

    payload: dict[str, Any] = {
        "sub": subject,
        "exp": expire,
    }

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_token(token: str) -> dict[str, Any] | None:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        return payload
    except JWTError:
        return None
PY

echo "batch 1 part 2 files written successfully"
