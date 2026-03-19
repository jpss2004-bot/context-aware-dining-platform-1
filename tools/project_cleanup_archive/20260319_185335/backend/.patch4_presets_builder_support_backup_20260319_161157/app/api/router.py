from fastapi import APIRouter

from app.api.routes import auth, experiences, onboarding, recommendations, restaurants, users

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
api_router.include_router(experiences.router, prefix="/experiences", tags=["experiences"])
api_router.include_router(restaurants.router, prefix="/restaurants", tags=["restaurants"])
