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


def get_system_preset_by_id(preset_id: str) -> PresetResponse | None:
    for preset in SYSTEM_PRESETS:
        if preset.preset_id == preset_id:
            return preset
    return None
