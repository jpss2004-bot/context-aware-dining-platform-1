#!/bin/bash
set -euo pipefail

PATCH_NAME="patch4_presets_compatibility_hardening"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Creating backup at: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

FILES_TO_BACKUP=(
  "app/repositories/preset_repository.py"
  "app/services/preset_catalog.py"
  "app/services/preset_service.py"
)

for file in "${FILES_TO_BACKUP[@]}"; do
  if [ -f "$file" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$file")"
    cp "$file" "${BACKUP_DIR}/$file"
  fi
done

cat > app/repositories/preset_repository.py <<'PY'
from typing import Optional

from sqlalchemy.orm import Session

from app.models.preset import UserPreset


class PresetRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_user_presets(self, user_id: int) -> list[UserPreset]:
        return (
            self.db.query(UserPreset)
            .filter(UserPreset.user_id == user_id)
            .order_by(UserPreset.updated_at.desc(), UserPreset.id.desc())
            .all()
        )

    def get_user_preset(self, user_id: int, preset_id: int):
        return (
            self.db.query(UserPreset)
            .filter(UserPreset.user_id == user_id, UserPreset.id == preset_id)
            .first()
        )

    def create_user_preset(
        self,
        user_id: int,
        name: str,
        description: Optional[str],
        selection_payload: dict,
    ) -> UserPreset:
        preset = UserPreset(
            user_id=user_id,
            name=name.strip(),
            description=description.strip() if description else None,
            selection_payload=selection_payload,
        )
        self.db.add(preset)
        self.db.commit()
        self.db.refresh(preset)
        return preset

    def update_user_preset(
        self,
        preset: UserPreset,
        name: Optional[str] = None,
        description: Optional[str] = None,
        selection_payload: Optional[dict] = None,
    ) -> UserPreset:
        if name is not None:
            preset.name = name.strip()
        if description is not None:
            preset.description = description.strip() if description else None
        if selection_payload is not None:
            preset.selection_payload = selection_payload

        self.db.commit()
        self.db.refresh(preset)
        return preset

    def delete_user_preset(self, preset: UserPreset) -> None:
        self.db.delete(preset)
        self.db.commit()
PY

cat > app/services/preset_catalog.py <<'PY'
from typing import Optional

from app.schemas.preset import PresetResponse, PresetSelectionPayload


SYSTEM_PRESETS: list[PresetResponse] = [
    PresetResponse(
        preset_id="system:student-quick-bite",
        owner_type="system",
        is_editable=False,
        name="Student Quick Bite",
        description="Fast, casual, budget-conscious preset built for quick meals and takeout-friendly options.",
        selection_payload=PresetSelectionPayload(
            outing_type="quick-bite",
            budget="$",
            pace="fast",
            social_context="friends",
            preferred_cuisines=["pizza", "fast food"],
            atmosphere=["casual"],
            student_friendly=True,
            quick_bite=True,
            requires_takeout=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:date-night",
        owner_type="system",
        is_editable=False,
        name="Date Night",
        description="Preset for slower, more polished dining with stronger date-night signals.",
        selection_payload=PresetSelectionPayload(
            outing_type="date-night",
            budget="$$$",
            pace="leisurely",
            social_context="date",
            atmosphere=["cozy", "refined", "scenic"],
            date_night=True,
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:group-drinks",
        owner_type="system",
        is_editable=False,
        name="Group Drinks",
        description="Preset for breweries, pubs, and social venues suited to a drinks-forward group outing.",
        selection_payload=PresetSelectionPayload(
            outing_type="drinks-night",
            budget="$$",
            social_context="group",
            preferred_cuisines=["beer", "wine", "cider", "pub"],
            drinks_focus=True,
            atmosphere=["lively", "casual"],
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:coffee-catchup",
        owner_type="system",
        is_editable=False,
        name="Coffee Catch-Up",
        description="Preset for cafés, coffeehouses, and relaxed daytime stops.",
        selection_payload=PresetSelectionPayload(
            outing_type="coffee-stop",
            budget="$",
            pace="slow",
            social_context="friends",
            preferred_cuisines=["coffee", "bakery", "dessert"],
            atmosphere=["cozy", "casual"],
            include_tags=["coffee"],
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:family-dinner",
        owner_type="system",
        is_editable=False,
        name="Family Dinner",
        description="Preset for family-friendly restaurants with broader appeal and easier logistics.",
        selection_payload=PresetSelectionPayload(
            outing_type="family-dining",
            budget="$$",
            pace="moderate",
            social_context="family",
            atmosphere=["casual", "family friendly"],
            family_friendly=True,
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
    PresetResponse(
        preset_id="system:scenic-special-occasion",
        owner_type="system",
        is_editable=False,
        name="Scenic Special Occasion",
        description="Preset for more premium, reservation-friendly outings with scenic or refined qualities.",
        selection_payload=PresetSelectionPayload(
            outing_type="special-occasion",
            budget="$$$",
            pace="leisurely",
            social_context="date",
            atmosphere=["scenic", "refined", "upscale"],
            date_night=True,
            requires_reservations=True,
            requires_dine_in=True,
            include_dish_hints=True,
        ),
    ),
]


def list_system_presets() -> list[PresetResponse]:
    return SYSTEM_PRESETS


def get_system_preset_by_id(preset_id: str) -> Optional[PresetResponse]:
    for preset in SYSTEM_PRESETS:
        if preset.preset_id == preset_id:
            return preset
    return None
PY

cat > app/services/preset_service.py <<'PY'
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
PY

PYTHON_BIN="python3"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi

echo "Using Python: ${PYTHON_BIN}"
PYTHONPATH=. "${PYTHON_BIN}" -m compileall app

echo "Running full preset-layer import smoke tests..."
PYTHONPATH=. "${PYTHON_BIN}" - <<'PY'
from app.repositories.preset_repository import PresetRepository
from app.services.preset_catalog import list_system_presets, get_system_preset_by_id
from app.services.preset_service import PresetService
from app.api.routes.presets import router as presets_router

print("PresetRepository import OK")
print("preset catalog import OK")
print("PresetService import OK")
print("presets router import OK")
print("system presets count =", len(list_system_presets()))
print("student preset exists =", get_system_preset_by_id("system:student-quick-bite") is not None)
PY

echo "Patch 4.2 compatibility hardening complete."
echo "Backup saved at: ${BACKUP_DIR}"
