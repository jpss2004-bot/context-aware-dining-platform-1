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
