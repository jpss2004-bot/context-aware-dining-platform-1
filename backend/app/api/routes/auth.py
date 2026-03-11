from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.auth import AuthUserResponse, LoginRequest, RegisterRequest, TokenResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/register", response_model=AuthUserResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    return AuthService(db).register(payload)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    return AuthService(db).login(payload)


@router.post("/token", response_model=TokenResponse)
def token_login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    payload = LoginRequest(
        email=form_data.username,
        password=form_data.password,
    )
    return AuthService(db).login(payload)


@router.get("/me", response_model=AuthUserResponse)
def get_me(current_user=Depends(get_current_user)):
    return current_user
