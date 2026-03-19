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
