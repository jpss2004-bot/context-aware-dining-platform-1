from fastapi import HTTPException, status

from app.repositories.preset_repository import PresetRepository
from app.schemas.preset import (
    CreateUserPresetRequest,
    PresetApplyResponse,
    PresetDeleteResponse,
    PresetResponse,
    PresetSelectionPayload,
    UpdateUserPresetRequest,
)
from app.services.preset_catalog import get_system_preset_by_id, list_system_presets


class PresetService:
    def __init__(self, db):
        self.repository = PresetRepository(db)

    def _parse_user_preset_id(self, preset_id: str) -> int:
        if not preset_id.startswith("user:"):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )
        try:
            return int(preset_id.split(":", 1)[1])
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid preset id format",
            ) from exc

    def _ensure_payload_is_recommendation_ready(self, payload: PresetSelectionPayload) -> None:
        if not payload.outing_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Preset selection_payload.outing_type is required",
            )

    def _user_preset_to_response(self, preset) -> PresetResponse:
        return PresetResponse(
            preset_id=f"user:{preset.id}",
            owner_type="user",
            owner_user_id=preset.user_id,
            is_editable=True,
            name=preset.name,
            description=preset.description,
            selection_payload=PresetSelectionPayload(**(preset.selection_payload or {})),
            created_at=preset.created_at,
            updated_at=preset.updated_at,
        )

    def list_presets_for_user(self, user) -> list[PresetResponse]:
        system_presets = list_system_presets()
        user_presets = [
            self._user_preset_to_response(item)
            for item in self.repository.list_user_presets(user.id)
        ]
        return system_presets + user_presets

    def get_preset_for_user(self, user, preset_id: str) -> PresetResponse:
        system_preset = get_system_preset_by_id(preset_id)
        if system_preset is not None:
            return system_preset

        numeric_id = self._parse_user_preset_id(preset_id)
        preset = self.repository.get_user_preset(user.id, numeric_id)
        if preset is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )
        return self._user_preset_to_response(preset)

    def create_user_preset(self, user, payload: CreateUserPresetRequest) -> PresetResponse:
        self._ensure_payload_is_recommendation_ready(payload.selection_payload)

        preset = self.repository.create_user_preset(
            user_id=user.id,
            name=payload.name,
            description=payload.description,
            selection_payload=payload.selection_payload.model_dump(exclude_none=True),
        )
        return self._user_preset_to_response(preset)

    def update_user_preset(self, user, preset_id: str, payload: UpdateUserPresetRequest) -> PresetResponse:
        numeric_id = self._parse_user_preset_id(preset_id)
        preset = self.repository.get_user_preset(user.id, numeric_id)
        if preset is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )

        selection_payload = None
        if payload.selection_payload is not None:
            self._ensure_payload_is_recommendation_ready(payload.selection_payload)
            selection_payload = payload.selection_payload.model_dump(exclude_none=True)

        updated = self.repository.update_user_preset(
            preset=preset,
            name=payload.name,
            description=payload.description,
            selection_payload=selection_payload,
        )
        return self._user_preset_to_response(updated)

    def delete_user_preset(self, user, preset_id: str) -> PresetDeleteResponse:
        numeric_id = self._parse_user_preset_id(preset_id)
        preset = self.repository.get_user_preset(user.id, numeric_id)
        if preset is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Preset not found",
            )

        self.repository.delete_user_preset(preset)
        return PresetDeleteResponse(
            message="Preset deleted successfully",
            deleted_preset_id=preset_id,
        )

    def apply_preset_for_user(self, user, preset_id: str) -> PresetApplyResponse:
        preset = self.get_preset_for_user(user, preset_id)
        builder_payload = preset.selection_payload

        return PresetApplyResponse(
            preset=preset,
            builder_payload=builder_payload,
            banner_message=f'Preset "{preset.name}" applied. You can customize any field before generating recommendations.',
            can_customize=True,
        )
