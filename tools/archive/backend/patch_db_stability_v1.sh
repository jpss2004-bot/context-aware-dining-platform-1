#!/bin/bash
set -euo pipefail

echo "applying database stability patch v1..."

if [ ! -d "app" ]; then
  echo "error: run this from inside the backend folder"
  exit 1
fi

mkdir -p backups

timestamp="$(date +%Y%m%d_%H%M%S)"
cp app/db/session.py "backups/session.py.${timestamp}.bak"
cp app/main.py "backups/main.py.${timestamp}.bak"

cat > app/db/session.py <<'PY'
from collections.abc import Generator

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

database_url = settings.database_url
is_sqlite = database_url.startswith("sqlite")

engine_kwargs = {
    "pool_pre_ping": True,
}

if is_sqlite:
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(
    database_url,
    **engine_kwargs,
)


@event.listens_for(Engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record) -> None:
    try:
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()
    except Exception:
        pass


SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    class_=Session,
)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
PY

cat > app/main.py <<'PY'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import settings
from app.db.init_db import init_db

app = FastAPI(
    title="Context-Aware Dining Experience Recommendation Platform",
    version="1.0.0",
    description="API for authentication, onboarding, recommendations, and dining experience logging.",
)


@app.on_event("startup")
def startup_event() -> None:
    init_db()


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

echo "patch applied successfully"
echo "backups saved in ./backups"
