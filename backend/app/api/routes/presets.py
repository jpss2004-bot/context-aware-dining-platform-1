from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.preset import (
    CreateUserPresetRequest,
    PresetApplyResponse,
    PresetDeleteResponse,
    PresetResponse,
    UpdateUserPresetRequest,
)
from app.services.preset_service import PresetService

router = APIRouter()


@router.get("", response_model=list[PresetResponse])
def list_presets(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).list_presets_for_user(current_user)


@router.get("/{preset_id}", response_model=PresetResponse)
def get_preset(
    preset_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).get_preset_for_user(current_user, preset_id)


@router.post("", response_model=PresetResponse)
def create_user_preset(
    payload: CreateUserPresetRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).create_user_preset(current_user, payload)


@router.put("/{preset_id}", response_model=PresetResponse)
def update_user_preset(
    preset_id: str,
    payload: UpdateUserPresetRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).update_user_preset(current_user, preset_id, payload)


@router.delete("/{preset_id}", response_model=PresetDeleteResponse)
def delete_user_preset(
    preset_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).delete_user_preset(current_user, preset_id)


@router.post("/{preset_id}/apply", response_model=PresetApplyResponse)
def apply_preset(
    preset_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return PresetService(db).apply_preset_for_user(current_user, preset_id)
