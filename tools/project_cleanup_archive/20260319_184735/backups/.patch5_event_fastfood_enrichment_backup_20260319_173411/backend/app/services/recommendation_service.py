from datetime import datetime, timezone
from typing import Optional

from app.models.restaurant import MenuItem, Restaurant
from app.models.user import User
from app.repositories.experience_repository import ExperienceRepository
from app.repositories.restaurant_repository import RestaurantRepository
from app.schemas.recommendation import (
    BuildYourNightRequest,
    DescribeYourNightRequest,
    RecommendationItem,
    RecommendationRequestSummary,
    RecommendationResponse,
    ScoreBreakdownItem,
    SurpriseMeRequest,
)
from app.services.preset_service import PresetService


class RecommendationService:
    ENGINE_VERSION = "phase3-intelligence-v1"

    def __init__(self, db):
        self.restaurant_repository = RestaurantRepository(db)
        self.experience_repository = ExperienceRepository(db)
        self.preset_service = PresetService(db)

    def _resolve_build_payload(self, user: User, payload: BuildYourNightRequest):
        if not payload.preset_id or payload.use_preset_defaults is False:
            return payload, None

        preset = self.preset_service.get_preset_for_user(user, payload.preset_id)
        base_payload = preset.selection_payload.model_dump(exclude_none=True)
        explicitly_provided = set(getattr(payload, "model_fields_set", set())) - {"preset_id", "use_preset_defaults"}

        for field_name in explicitly_provided:
            base_payload[field_name] = getattr(payload, field_name)

        base_payload["preset_id"] = payload.preset_id
        base_payload["use_preset_defaults"] = payload.use_preset_defaults

        resolved_payload = BuildYourNightRequest(**base_payload)
        return resolved_payload, preset

    def build_your_night(self, user: User, payload: BuildYourNightRequest) -> RecommendationResponse:
        resolved_payload, _preset = self._resolve_build_payload(user, payload)

        restaurants = self.restaurant_repository.list_restaurants_with_details()
        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="build",
            outing_type=resolved_payload.outing_type,
            mood=resolved_payload.mood,
            budget=resolved_payload.budget,
            pace=resolved_payload.pace,
            social_context=resolved_payload.social_context,
            preferred_cuisines=resolved_payload.preferred_cuisines,
            drinks_focus=resolved_payload.drinks_focus,
            atmosphere=resolved_payload.atmosphere,
            towns=resolved_payload.towns,
            include_tags=resolved_payload.include_tags,
            exclude_tags=resolved_payload.exclude_tags,
            family_friendly=resolved_payload.family_friendly,
            student_friendly=resolved_payload.student_friendly,
            date_night=resolved_payload.date_night,
            quick_bite=resolved_payload.quick_bite,
            fast_food=resolved_payload.fast_food,
            requires_dine_in=resolved_payload.requires_dine_in,
            requires_takeout=resolved_payload.requires_takeout,
            requires_delivery=resolved_payload.requires_delivery,
            requires_reservations=resolved_payload.requires_reservations,
            requires_live_music=resolved_payload.requires_live_music,
            requires_trivia=resolved_payload.requires_trivia,
            include_dish_hints=resolved_payload.include_dish_hints,
        )
        return RecommendationResponse(
            mode="build-your-night",
            engine_version="phase4-presets-v1",
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type=resolved_payload.outing_type,
                budget=resolved_payload.budget,
                pace=resolved_payload.pace,
                social_context=resolved_payload.social_context,
                preferred_cuisines=resolved_payload.preferred_cuisines,
                drinks_focus=resolved_payload.drinks_focus,
                atmosphere=resolved_payload.atmosphere,
                towns=resolved_payload.towns,
                include_tags=resolved_payload.include_tags,
                exclude_tags=resolved_payload.exclude_tags,
                family_friendly=resolved_payload.family_friendly,
                student_friendly=resolved_payload.student_friendly,
                date_night=resolved_payload.date_night,
                quick_bite=resolved_payload.quick_bite,
                fast_food=resolved_payload.fast_food,
                requires_dine_in=resolved_payload.requires_dine_in,
                requires_takeout=resolved_payload.requires_takeout,
                requires_delivery=resolved_payload.requires_delivery,
                requires_reservations=resolved_payload.requires_reservations,
                requires_live_music=resolved_payload.requires_live_music,
                requires_trivia=resolved_payload.requires_trivia,
                preset_id=resolved_payload.preset_id,
            ),
            results=ranked,
        )

    def describe_your_night(self, user: User, payload: DescribeYourNightRequest) -> RecommendationResponse:
        parsed = self._parse_prompt(payload.prompt)
        restaurants = self.restaurant_repository.list_restaurants_with_details()
        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="describe",
            outing_type=parsed["outing_type"],
            mood=parsed["mood"],
            budget=parsed["budget"],
            pace=parsed["pace"],
            social_context=parsed["social_context"],
            preferred_cuisines=parsed["preferred_cuisines"],
            drinks_focus=parsed["drinks_focus"],
            atmosphere=parsed["atmosphere"],
            towns=parsed["towns"],
            include_tags=parsed["include_tags"],
            exclude_tags=parsed["exclude_tags"],
            family_friendly=parsed["family_friendly"],
            student_friendly=parsed["student_friendly"],
            date_night=parsed["date_night"],
            quick_bite=parsed["quick_bite"],
            fast_food=parsed["fast_food"],
            requires_dine_in=parsed["requires_dine_in"],
            requires_takeout=parsed["requires_takeout"],
            requires_delivery=parsed["requires_delivery"],
            requires_reservations=parsed["requires_reservations"],
            requires_live_music=parsed["requires_live_music"],
            requires_trivia=parsed["requires_trivia"],
            include_dish_hints=True,
        )
        return RecommendationResponse(
            mode="describe-your-night",
            engine_version="phase4-presets-v1",
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type=parsed["outing_type"],
                budget=parsed["budget"],
                pace=parsed["pace"],
                social_context=parsed["social_context"],
                preferred_cuisines=parsed["preferred_cuisines"],
                drinks_focus=parsed["drinks_focus"],
                atmosphere=parsed["atmosphere"],
                towns=parsed["towns"],
                include_tags=parsed["include_tags"],
                exclude_tags=parsed["exclude_tags"],
                family_friendly=parsed["family_friendly"],
                student_friendly=parsed["student_friendly"],
                date_night=parsed["date_night"],
                quick_bite=parsed["quick_bite"],
                fast_food=parsed["fast_food"],
                requires_dine_in=parsed["requires_dine_in"],
                requires_takeout=parsed["requires_takeout"],
                requires_delivery=parsed["requires_delivery"],
                requires_reservations=parsed["requires_reservations"],
                requires_live_music=parsed["requires_live_music"],
                requires_trivia=parsed["requires_trivia"],
                preset_id=None,
            ),
            results=ranked,
        )

    def surprise_me(self, user: User, payload: SurpriseMeRequest) -> RecommendationResponse:
        restaurants = self.restaurant_repository.list_restaurants_with_details()
        preference = user.preference
        profile = user.profile

        preferred_atmosphere = preference.atmosphere_preferences if preference else []
        preferred_cuisines = preference.cuisine_preferences if preference else []
        preferred_social = preference.social_preferences if preference else []
        favorite_restaurant_names = set(profile.favorite_restaurants if profile else [])

        experiences = self.experience_repository.list_by_user_id(user.id)
        experienced_restaurant_ids = {
            experience.restaurant_id
            for experience in experiences
            if experience.restaurant_id is not None
        }

        ranked = self._score_restaurants(
            user=user,
            restaurants=restaurants,
            mode="surprise",
            outing_type="surprise",
            mood=None,
            budget=preference.price_sensitivity if preference else None,
            pace=None,
            social_context=preferred_social[0] if preferred_social else None,
            preferred_cuisines=preferred_cuisines,
            drinks_focus=payload.include_drinks,
            atmosphere=preferred_atmosphere,
            towns=[],
            include_tags=[],
            exclude_tags=[],
            family_friendly=None,
            student_friendly=None,
            date_night=None,
            quick_bite=None,
            fast_food=None,
            requires_dine_in=None,
            requires_takeout=None,
            requires_delivery=None,
            requires_reservations=None,
            requires_live_music=None,
            requires_trivia=None,
            include_dish_hints=True,
        )

        adjusted = self._apply_surprise_novelty(
            ranked=ranked,
            experienced_restaurant_ids=experienced_restaurant_ids,
            favorite_restaurant_names=favorite_restaurant_names,
        )

        excluded_ids = set(payload.exclude_restaurant_ids or [])
        filtered = [item for item in adjusted if item.restaurant_id not in excluded_ids]

        if len(filtered) < payload.count:
            filtered = adjusted

        final_results = filtered[: payload.count]

        return RecommendationResponse(
            mode="surprise-me",
            engine_version="phase4-presets-v1",
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type="surprise",
                budget=preference.price_sensitivity if preference else None,
                pace=None,
                social_context=preferred_social[0] if preferred_social else None,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=payload.include_drinks,
                atmosphere=preferred_atmosphere,
                towns=[],
                include_tags=[],
                exclude_tags=[],
                family_friendly=None,
                student_friendly=None,
                date_night=None,
                quick_bite=None,
                fast_food=None,
                requires_dine_in=None,
                requires_takeout=None,
                requires_delivery=None,
                requires_reservations=None,
                requires_live_music=None,
                requires_trivia=None,
                preset_id=None,
            ),
            results=final_results,
        )

    def _apply_surprise_novelty(
        self,
        ranked: list[RecommendationItem],
        experienced_restaurant_ids: set[int],
        favorite_restaurant_names: set[str],
    ) -> list[RecommendationItem]:
        def sort_key(item: RecommendationItem):
            unseen_bonus = 1 if item.restaurant_id not in experienced_restaurant_ids else 0
            favorite_bonus = 1 if item.restaurant_name in favorite_restaurant_names else 0
            return (
                unseen_bonus,
                favorite_bonus,
                item.score,
                -item.restaurant_id,
            )

        return sorted(ranked, key=sort_key, reverse=True)

    def _timestamp(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def _build_request_summary(
        self,
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
        towns: list[str],
        include_tags: list[str],
        exclude_tags: list[str],
        family_friendly: Optional[bool],
        student_friendly: Optional[bool],
        date_night: Optional[bool],
        quick_bite: Optional[bool],
        fast_food: Optional[bool],
        requires_dine_in: Optional[bool],
        requires_takeout: Optional[bool],
        requires_delivery: Optional[bool],
        requires_reservations: Optional[bool],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        preset_id: Optional[str],
    ) -> RecommendationRequestSummary:
        return RecommendationRequestSummary(
            outing_type=outing_type,
            budget=budget,
            pace=pace,
            social_context=social_context,
            preferred_cuisines=preferred_cuisines,
            drinks_focus=drinks_focus,
            atmosphere=atmosphere,
            towns=towns,
            include_tags=include_tags,
            exclude_tags=exclude_tags,
            family_friendly=family_friendly,
            student_friendly=student_friendly,
            date_night=date_night,
            quick_bite=quick_bite,
            fast_food=fast_food,
            requires_dine_in=requires_dine_in,
            requires_takeout=requires_takeout,
            requires_delivery=requires_delivery,
            requires_reservations=requires_reservations,
            requires_live_music=requires_live_music,
            requires_trivia=requires_trivia,
            preset_id=preset_id,
        )

    def _parse_prompt(self, prompt: str) -> dict:
        text = self._normalize_text(prompt)

        budget = None
        if any(word in text for word in ["cheap", "budget", "affordable", "inexpensive"]):
            budget = "$"
        elif any(word in text for word in ["fancy", "upscale", "premium", "special occasion"]):
            budget = "$$$"
        elif any(word in text for word in ["mid-range", "moderate", "balanced"]):
            budget = "$$"

        pace = None
        if any(word in text for word in ["quick", "fast", "late night", "bite", "grab and go"]):
            pace = "fast"
        elif any(word in text for word in ["slow", "relaxed"]):
            pace = "slow"
        elif any(word in text for word in ["leisurely", "romantic", "drawn out"]):
            pace = "leisurely"
        elif "moderate" in text:
            pace = "moderate"

        social_context = None
        if any(word in text for word in ["friends", "crew"]):
            social_context = "friends"
        elif any(word in text for word in ["group", "crowd", "party"]):
            social_context = "group"
        elif any(word in text for word in ["solo", "alone"]):
            social_context = "solo"
        elif any(word in text for word in ["date", "romantic"]):
            social_context = "date"
        elif any(word in text for word in ["family", "kids", "children"]):
            social_context = "family"

        outing_type = "natural-language"
        if any(word in text for word in ["date", "romantic"]):
            outing_type = "date-night"
        elif any(word in text for word in ["drinks", "cocktails", "bar", "brewery", "wine", "cider"]):
            outing_type = "drinks-night"
        elif any(word in text for word in ["coffee", "cafe", "espresso", "study"]):
            outing_type = "coffee-stop"
        elif any(word in text for word in ["quick", "fast", "grab and go"]):
            outing_type = "quick-bite"
        elif any(word in text for word in ["special occasion", "anniversary", "celebrate"]):
            outing_type = "special-occasion"
        elif any(word in text for word in ["group dinner", "large table", "shared plates"]):
            outing_type = "group-dinner"
        elif any(word in text for word in ["casual", "easy", "simple bite"]):
            outing_type = "casual-bite"
        elif any(word in text for word in ["family", "kids", "children"]):
            outing_type = "family-dining"

        atmosphere = []
        for word in [
            "cozy", "lively", "quiet", "casual", "scenic", "historic", "refined",
            "upscale", "rustic", "romantic", "family friendly", "live music"
        ]:
            if word in text:
                atmosphere.append(word)

        preferred_cuisines = []
        for word in [
            "pizza", "mediterranean", "asian", "bakery", "dessert", "seasonal", "turkish",
            "coffee", "beer", "wine", "cider", "pasta", "cocktail", "cocktails", "indian",
            "mexican", "sushi", "pub", "burger", "burgers", "seafood", "brunch", "fast food"
        ]:
            if word in text:
                preferred_cuisines.append(word)

        drinks_focus = any(
            word in text
            for word in ["drink", "drinks", "cocktail", "cocktails", "bar", "beer", "wine", "cider"]
        )

        towns = []
        for town in [
            "wolfville", "new minas", "kentville", "canning", "windsor",
            "grand-pré", "grand pre", "port williams", "sheffield mills",
            "hantsport", "berwick"
        ]:
            if town in text:
                towns.append(town)

        include_tags = []
        if "live music" in text:
            include_tags.append("live music")
        if "trivia" in text:
            include_tags.append("trivia")
        if "brunch" in text:
            include_tags.append("brunch")
        if "student budget" in text or "student friendly" in text:
            include_tags.append("student friendly")
        if "family friendly" in text:
            include_tags.append("family friendly")
        if "quick bite" in text:
            include_tags.append("quick bite")
        if "date night" in text:
            include_tags.append("date night")
        if "fast food" in text:
            include_tags.append("fast food")

        exclude_tags = []
        if "no alcohol" in text or "non alcoholic" in text:
            exclude_tags.append("alcohol")
        if "not fancy" in text:
            exclude_tags.append("upscale")

        family_friendly = True if any(word in text for word in ["family", "kids", "children"]) else None
        student_friendly = True if any(word in text for word in ["student", "cheap", "budget"]) else None
        date_night = True if any(word in text for word in ["date", "romantic"]) else None
        quick_bite = True if any(word in text for word in ["quick", "fast", "grab and go", "quick bite"]) else None
        fast_food = True if "fast food" in text else None
        requires_dine_in = True if "dine in" in text else None
        requires_takeout = True if "takeout" in text else None
        requires_delivery = True if "delivery" in text else None
        requires_reservations = True if "reservation" in text or "book" in text else None
        requires_live_music = True if "live music" in text else None
        requires_trivia = True if "trivia" in text else None

        return {
            "outing_type": outing_type,
            "mood": None,
            "budget": budget,
            "pace": pace,
            "social_context": social_context,
            "preferred_cuisines": preferred_cuisines,
            "drinks_focus": drinks_focus,
            "atmosphere": atmosphere,
            "towns": towns,
            "include_tags": include_tags,
            "exclude_tags": exclude_tags,
            "family_friendly": family_friendly,
            "student_friendly": student_friendly,
            "date_night": date_night,
            "quick_bite": quick_bite,
            "fast_food": fast_food,
            "requires_dine_in": requires_dine_in,
            "requires_takeout": requires_takeout,
            "requires_delivery": requires_delivery,
            "requires_reservations": requires_reservations,
            "requires_live_music": requires_live_music,
            "requires_trivia": requires_trivia,
        }

    def _normalize_text(self, value: Optional[str]) -> str:
        return (value or "").strip().lower()

    def _normalize_list(self, values: Optional[list[str]]) -> list[str]:
        return [self._normalize_text(value) for value in (values or []) if self._normalize_text(value)]

    def _text_blob(self, *parts: Optional[str]) -> str:
        return " ".join(self._normalize_text(part) for part in parts if part).strip()

    def _has_tag(self, tag_names: list[str], candidate: str) -> bool:
        target = self._normalize_text(candidate)
        return any(target == tag or target in tag for tag in tag_names)

    def _append_reason(self, reasons: list[str], message: str) -> None:
        if message not in reasons:
            reasons.append(message)

    def _append_signal(self, signals: list[str], message: str) -> None:
        if message not in signals:
            signals.append(message)

    def _add_breakdown(self, breakdown: dict[str, float], label: str, points: float) -> None:
        breakdown[label] = round(breakdown.get(label, 0.0) + points, 2)

    def _fit_label(self, score: float, confidence_level: str) -> str:
        if confidence_level == "high" and score >= 12:
            return "excellent fit"
        if confidence_level in {"high", "medium"} and score >= 8:
            return "strong fit"
        if score >= 4:
            return "possible fit"
        return "explore"

    def _effective_budget_symbol(self, budget: Optional[str], user: User) -> Optional[str]:
        budget_value = self._normalize_text(budget)
        if budget_value in {"$", "$$", "$$$"}:
            return budget_value

        pref = getattr(user, "preference", None)
        if pref and pref.budget_max_per_person is not None:
            max_budget = float(pref.budget_max_per_person)
            if max_budget <= 15:
                return "$"
            if max_budget <= 35:
                return "$$"
            return "$$$"

        if budget_value in {"budget", "budget-conscious"}:
            return "$"
        if budget_value in {"balanced", "moderate"}:
            return "$$"
        if budget_value in {"premium", "upscale"}:
            return "$$$"

        if pref and pref.price_sensitivity in {"$", "$$", "$$$"}:
            return pref.price_sensitivity

        return None

    def _apply_outing_type_score(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int]:
        if not outing_type:
            return 0.0, 0

        score = 0.0
        strong_matches = 0
        value = self._normalize_text(outing_type)
        atmosphere_text = self._normalize_text(restaurant.atmosphere)
        social_style = self._normalize_text(restaurant.social_style)
        pace = self._normalize_text(restaurant.pace)

        if value == "date-night":
            if restaurant.is_date_night:
                score += 3.2
                strong_matches += 1
                self._append_reason(reasons, "Explicitly marked as a date-night venue")
                self._append_signal(matched_signals, "date-night venue")
            if social_style == "date":
                score += 2.2
            for term in ["quiet", "cozy", "scenic", "refined", "upscale", "historic", "romantic"]:
                if term in atmosphere_text:
                    score += 0.6

        elif value == "group-dinner":
            if social_style == "group":
                score += 2.6
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for group dining")
                self._append_signal(matched_signals, "group dining fit")
            if self._has_tag(restaurant_tag_names, "group friendly") or self._has_tag(restaurant_tag_names, "shared plates"):
                score += 1.8

        elif value == "drinks-night":
            if restaurant.serves_alcohol:
                score += 2.4
                strong_matches += 1
                self._append_reason(reasons, "Strong fit for a drinks-forward outing")
                self._append_signal(matched_signals, "alcohol service")
            for term in ["beer", "wine", "cider", "brewery", "pub", "brewpub", "winery", "cidery"]:
                if self._has_tag(restaurant_tag_names, term):
                    score += 0.8

        elif value == "quick-bite":
            if restaurant.is_quick_bite:
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Explicitly marked as a quick-bite venue")
                self._append_signal(matched_signals, "quick-bite venue")
            if pace == "fast":
                score += 2.0
            if restaurant.offers_takeout:
                score += 1.2

        elif value == "coffee-stop":
            if restaurant.supports_coffee:
                score += 3.0
                strong_matches += 1
                self._append_reason(reasons, "Explicitly supports coffee-focused visits")
                self._append_signal(matched_signals, "coffee support")
            for term in ["coffee", "coffeehouse", "cafe", "espresso"]:
                if self._has_tag(restaurant_tag_names, term):
                    score += 0.9
            if "quiet" in atmosphere_text or "cozy" in atmosphere_text:
                score += 0.8

        elif value == "special-occasion":
            if restaurant.is_date_night:
                score += 1.4
            if restaurant.accepts_reservations:
                score += 1.4
            if restaurant.price_tier == "$$$":
                score += 2.4
                strong_matches += 1
            for term in ["refined", "scenic", "historic", "upscale"]:
                if term in atmosphere_text:
                    score += 0.8

        elif value == "casual-bite":
            if "casual" in atmosphere_text:
                score += 2.0
            if pace in {"fast", "moderate"}:
                score += 1.4
            if restaurant.price_tier in {"$", "$$"}:
                score += 1.0

        elif value == "family-dining":
            if restaurant.is_family_friendly:
                score += 3.2
                strong_matches += 1
                self._append_reason(reasons, "Explicitly marked as family friendly")
                self._append_signal(matched_signals, "family-friendly venue")
            if social_style == "family":
                score += 2.0
            if restaurant.supports_lunch or restaurant.supports_dinner:
                score += 0.8

        if score != 0:
            self._add_breakdown(breakdown, "outing type", score)

        return score, strong_matches

    def _apply_structured_filter_scoring(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        towns: list[str],
        include_tags: list[str],
        exclude_tags: list[str],
        family_friendly: Optional[bool],
        student_friendly: Optional[bool],
        date_night: Optional[bool],
        quick_bite: Optional[bool],
        fast_food: Optional[bool],
        requires_dine_in: Optional[bool],
        requires_takeout: Optional[bool],
        requires_delivery: Optional[bool],
        requires_reservations: Optional[bool],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        reasons: list[str],
        matched_signals: list[str],
        penalized_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int, int]:
        score = 0.0
        strong_matches = 0
        contradictions = 0

        normalized_towns = {value.replace("é", "e") for value in self._normalize_list(towns)}
        restaurant_town = self._normalize_text(restaurant.town).replace("é", "e")

        if normalized_towns:
            if restaurant_town in normalized_towns:
                score += 2.2
                strong_matches += 1
                self._append_reason(reasons, f"Located in a requested town ({restaurant.town})")
                self._append_signal(matched_signals, f"town match ({restaurant.town})")
                self._add_breakdown(breakdown, "town", 2.2)
            else:
                score -= 0.9
                contradictions += 1
                self._append_signal(penalized_signals, "outside requested towns")
                self._add_breakdown(breakdown, "town", -0.9)

        for tag in self._normalize_list(include_tags):
            if self._has_tag(restaurant_tag_names, tag):
                score += 1.9
                strong_matches += 1
                self._append_reason(reasons, f"Matches requested feature ({tag})")
                self._append_signal(matched_signals, f"requested feature ({tag})")
                self._add_breakdown(breakdown, "include tags", 1.9)

        for tag in self._normalize_list(exclude_tags):
            if self._has_tag(restaurant_tag_names, tag):
                score -= 2.2
                contradictions += 1
                self._append_reason(reasons, f"Penalized because it includes an avoided feature ({tag})")
                self._append_signal(penalized_signals, f"avoided feature present ({tag})")
                self._add_breakdown(breakdown, "exclude tags", -2.2)

        def apply_bool_preference(requested: Optional[bool], actual: Optional[bool], label: str, positive_points: float, penalty_points: float):
            nonlocal score, strong_matches, contradictions
            if requested is True:
                if actual is True:
                    score += positive_points
                    strong_matches += 1
                    self._append_reason(reasons, f"Matches requested requirement ({label})")
                    self._append_signal(matched_signals, f"{label} match")
                    self._add_breakdown(breakdown, label, positive_points)
                elif actual is False:
                    score -= penalty_points
                    contradictions += 1
                    self._append_reason(reasons, f"Penalized because it misses a required feature ({label})")
                    self._append_signal(penalized_signals, f"missing {label}")
                    self._add_breakdown(breakdown, label, -penalty_points)

        apply_bool_preference(family_friendly, restaurant.is_family_friendly, "family friendly", 2.4, 2.1)
        apply_bool_preference(student_friendly, restaurant.is_student_friendly, "student friendly", 2.2, 2.0)
        apply_bool_preference(date_night, restaurant.is_date_night, "date night", 2.5, 2.2)
        apply_bool_preference(quick_bite, restaurant.is_quick_bite, "quick bite", 2.4, 2.1)
        apply_bool_preference(fast_food, restaurant.is_fast_food, "fast food", 2.3, 2.1)
        apply_bool_preference(requires_dine_in, restaurant.offers_dine_in, "dine-in", 1.8, 2.0)
        apply_bool_preference(requires_takeout, restaurant.offers_takeout, "takeout", 1.8, 2.0)
        apply_bool_preference(requires_delivery, restaurant.offers_delivery, "delivery", 1.8, 2.0)
        apply_bool_preference(requires_reservations, restaurant.accepts_reservations, "reservations", 1.8, 2.0)
        apply_bool_preference(requires_live_music, restaurant.has_live_music, "live music", 2.0, 2.2)
        apply_bool_preference(requires_trivia, restaurant.has_trivia_night, "trivia", 2.0, 2.2)

        return score, strong_matches, contradictions

    def _apply_contradiction_penalties(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        drinks_focus: bool,
        atmosphere: list[str],
        reasons: list[str],
        penalized_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int]:
        penalty = 0.0
        contradictions = 0

        outing = self._normalize_text(outing_type)
        budget_value = self._normalize_text(budget)
        pace_value = self._normalize_text(pace)
        social_value = self._normalize_text(social_context)
        restaurant_pace = self._normalize_text(restaurant.pace)
        restaurant_social = self._normalize_text(restaurant.social_style)
        atmosphere_text = self._normalize_text(restaurant.atmosphere)
        atmosphere_values = [self._normalize_text(value) for value in atmosphere]

        if budget_value == "$" and restaurant.price_tier == "$$$":
            penalty -= 1.75
            contradictions += 1
            self._append_reason(reasons, "Penalized because it conflicts with a budget-first plan")
            self._append_signal(penalized_signals, "too expensive for budget-first plan")

        if outing == "quick-bite" and restaurant_pace in {"slow", "leisurely"}:
            penalty -= 2.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because the pace is too slow for a quick bite")
            self._append_signal(penalized_signals, "pace too slow for quick bite")

        if outing == "quick-bite" and restaurant.price_tier == "$$$":
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because it feels too premium for a quick bite")
            self._append_signal(penalized_signals, "too premium for quick bite")

        if outing == "coffee-stop" and not restaurant.supports_coffee:
            penalty -= 1.8
            contradictions += 1
            self._append_reason(reasons, "Penalized because it is not clearly coffee-oriented")
            self._append_signal(penalized_signals, "not clearly coffee-oriented")

        if social_value == "solo" and restaurant_social == "group":
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because it skews too group-oriented for a solo outing")
            self._append_signal(penalized_signals, "too group-oriented for solo outing")

        if social_value == "date" and restaurant_social == "group":
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because it skews too group-oriented for a date")
            self._append_signal(penalized_signals, "too group-oriented for date outing")

        if "quiet" in atmosphere_values and "lively" in atmosphere_text:
            penalty -= 1.5
            contradictions += 1
            self._append_reason(reasons, "Penalized because the atmosphere is livelier than requested")
            self._append_signal(penalized_signals, "more lively than requested")

        if "lively" in atmosphere_values and "quiet" in atmosphere_text:
            penalty -= 1.0
            contradictions += 1
            self._append_reason(reasons, "Penalized because the atmosphere is quieter than requested")
            self._append_signal(penalized_signals, "quieter than requested")

        if pace_value == "fast" and restaurant_pace in {"slow", "leisurely"}:
            penalty -= 1.75
            contradictions += 1
            self._append_reason(reasons, "Penalized because the restaurant pace is too slow")
            self._append_signal(penalized_signals, "restaurant pace too slow")

        if pace_value == "leisurely" and restaurant_pace == "fast":
            penalty -= 1.25
            contradictions += 1
            self._append_reason(reasons, "Penalized because the restaurant pace is too rushed")
            self._append_signal(penalized_signals, "restaurant pace too rushed")

        if not drinks_focus and restaurant.serves_alcohol:
            if any(self._has_tag(restaurant_tag_names, tag) for tag in ["pub", "brewery", "brewpub", "winery", "cidery"]):
                penalty -= 0.85
                contradictions += 1
                self._append_reason(reasons, "Penalized because the venue is more drinks-led than requested")
                self._append_signal(penalized_signals, "too drinks-led for current build")

        if penalty != 0:
            self._add_breakdown(breakdown, "penalties", penalty)

        return penalty, contradictions

    def _apply_combination_bonus(
        self,
        restaurant: Restaurant,
        restaurant_tag_names: list[str],
        outing_type: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int]:
        bonus = 0.0
        strong_matches = 0

        outing = self._normalize_text(outing_type)
        budget_value = self._normalize_text(budget)
        pace_value = self._normalize_text(pace)
        social_value = self._normalize_text(social_context)
        atmosphere_values = {self._normalize_text(value) for value in atmosphere}
        cuisine_values = {self._normalize_text(value) for value in preferred_cuisines}
        atmosphere_text = self._normalize_text(restaurant.atmosphere)

        if outing == "date-night":
            if (restaurant.is_date_night or social_value == "date") and budget_value == "$$$" and atmosphere_values.intersection({"scenic", "refined", "quiet", "cozy", "romantic"}):
                bonus += 2.25
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a premium date-night combination")
                self._append_signal(matched_signals, "premium date-night combination")

        if outing == "drinks-night":
            if drinks_focus and cuisine_values.intersection({"beer", "wine", "cider", "cocktail", "cocktails"}) and (
                self._has_tag(restaurant_tag_names, "brewery")
                or self._has_tag(restaurant_tag_names, "pub")
                or self._has_tag(restaurant_tag_names, "winery")
                or self._has_tag(restaurant_tag_names, "cidery")
            ):
                bonus += 2.25
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a drinks-night build with strong beverage alignment")
                self._append_signal(matched_signals, "strong drinks-night combination")

        if outing == "coffee-stop":
            if restaurant.supports_coffee and social_value == "solo" and atmosphere_values.intersection({"quiet", "cozy"}):
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a quiet solo coffee-stop combination")
                self._append_signal(matched_signals, "quiet solo coffee combination")

        if outing == "quick-bite":
            if (restaurant.is_quick_bite or restaurant.offers_takeout) and budget_value == "$" and pace_value == "fast":
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a fast and budget-friendly quick-bite build")
                self._append_signal(matched_signals, "fast budget quick-bite combination")

        if outing == "special-occasion":
            if restaurant.accepts_reservations and budget_value == "$$$" and atmosphere_values.intersection({"refined", "scenic", "upscale"}):
                bonus += 2.0
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a premium special-occasion combination")
                self._append_signal(matched_signals, "premium special-occasion combination")

        if outing == "group-dinner":
            if social_value == "group" and ("lively" in atmosphere_values or self._has_tag(restaurant_tag_names, "group friendly")):
                bonus += 1.8
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a social group-dinner combination")
                self._append_signal(matched_signals, "social group-dinner combination")

        if outing == "casual-bite":
            if social_value in {"friends", "group"} and "casual" in atmosphere_values and budget_value in {"$", "$$"}:
                bonus += 1.6
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a casual shared-night combination")
                self._append_signal(matched_signals, "casual shared-night combination")

        if outing == "family-dining":
            if restaurant.is_family_friendly and social_value == "family" and budget_value in {"$", "$$"}:
                bonus += 1.8
                strong_matches += 1
                self._append_reason(reasons, "Bonus for a family-dining combination")
                self._append_signal(matched_signals, "family dining combination")

        if "refined" in atmosphere_values and "casual" in atmosphere_text:
            bonus -= 0.65

        if bonus != 0:
            self._add_breakdown(breakdown, "combination bonus", bonus)

        return bonus, strong_matches

    def _select_menu_items(
        self,
        restaurant: Restaurant,
        preferred_cuisines: list[str],
        drinks_focus: bool,
        outing_type: Optional[str],
        include_dish_hints: bool,
    ) -> tuple[list[str], list[str]]:
        cuisine_values = {self._normalize_text(value) for value in preferred_cuisines}
        outing = self._normalize_text(outing_type)

        dish_candidates: list[tuple[float, str]] = []
        drink_candidates: list[tuple[float, str]] = []

        for item in restaurant.menu_items:
            item_text = self._text_blob(item.name, item.description, getattr(item, "recommendation_hint", None), getattr(item, "meal_period", None))
            item_tag_names = [self._normalize_text(tag.name) for tag in item.tags]
            item_score = 0.0

            if item.is_signature:
                item_score += 1.1
            if getattr(item, "is_dish_highlight", False):
                item_score += 1.2
            if include_dish_hints and getattr(item, "recommendation_hint", None):
                item_score += 0.8

            for value in cuisine_values:
                if value in item_text or any(value == tag or value in tag for tag in item_tag_names):
                    item_score += 2.0

            meal_period = self._normalize_text(getattr(item, "meal_period", None))

            if item.category == "dish":
                if outing in {"date-night", "special-occasion"} and item.is_signature:
                    item_score += 0.8
                if outing == "quick-bite" and (item.price is None or item.price <= 18):
                    item_score += 0.8
                if outing == "quick-bite" and meal_period in {"lunch", "dinner"}:
                    item_score += 0.4
                if outing == "coffee-stop" and self._text_blob(item.name, item.description).find("espresso") >= 0:
                    item_score += 1.2
                if outing == "family-dining" and any(term in item_text for term in ["share", "fries", "pizza", "burger", "wrap"]):
                    item_score += 0.7
                dish_candidates.append((item_score, item.name))

            elif item.category == "drink":
                if drinks_focus:
                    item_score += 1.3
                if outing == "coffee-stop" and any(term in item_text for term in ["coffee", "espresso", "latte", "cappuccino"]):
                    item_score += 2.2
                if outing == "drinks-night" and any(term in item_text for term in ["beer", "wine", "cider", "cocktail", "flight"]):
                    item_score += 2.2
                drink_candidates.append((item_score, item.name))

        dish_candidates.sort(key=lambda entry: (-entry[0], entry[1].lower()))
        drink_candidates.sort(key=lambda entry: (-entry[0], entry[1].lower()))

        suggested_dishes = [name for _, name in dish_candidates[:2]]
        suggested_drinks = [name for _, name in drink_candidates[:2]]

        return suggested_dishes, suggested_drinks

    def _determine_confidence(
        self,
        score: float,
        strong_matches: int,
        soft_matches: int,
        contradictions: int,
    ) -> str:
        if score >= 12 and strong_matches >= 4 and contradictions <= 1:
            return "high"
        if score >= 8 and strong_matches >= 2 and contradictions <= 2:
            return "medium"
        if strong_matches + soft_matches >= 3 and contradictions <= 2:
            return "medium"
        return "exploratory"

    def _build_explanation(
        self,
        outing_type: Optional[str],
        confidence_level: str,
        matched_signals: list[str],
        penalized_signals: list[str],
    ) -> str:
        outing = self._normalize_text(outing_type).replace("-", " ")
        prefix_map = {
            "high": "High-confidence match.",
            "medium": "Solid fit.",
            "exploratory": "Exploratory fit.",
        }
        prefix = prefix_map.get(confidence_level, "Recommendation ready.")

        if outing and outing not in {"surprise", "natural language"}:
            if matched_signals:
                sentence = f"{prefix} Good alignment for {outing}, driven by {matched_signals[0]}."
            else:
                sentence = f"{prefix} Good alignment for {outing}."
        elif matched_signals:
            sentence = f"{prefix} Driven by {matched_signals[0]}."
        else:
            sentence = prefix

        if penalized_signals:
            sentence += f" Watch-out: {penalized_signals[0]}."

        return sentence

    def _score_restaurants(
        self,
        user: User,
        restaurants: list[Restaurant],
        mode: str,
        outing_type: Optional[str],
        mood: Optional[str],
        budget: Optional[str],
        pace: Optional[str],
        social_context: Optional[str],
        preferred_cuisines: list[str],
        drinks_focus: bool,
        atmosphere: list[str],
        towns: list[str],
        include_tags: list[str],
        exclude_tags: list[str],
        family_friendly: Optional[bool],
        student_friendly: Optional[bool],
        date_night: Optional[bool],
        quick_bite: Optional[bool],
        fast_food: Optional[bool],
        requires_dine_in: Optional[bool],
        requires_takeout: Optional[bool],
        requires_delivery: Optional[bool],
        requires_reservations: Optional[bool],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        include_dish_hints: bool,
    ) -> list[RecommendationItem]:
        preference = user.preference
        experiences = self.experience_repository.list_by_user_id(user.id)

        positively_rated_restaurant_ids = {
            experience.restaurant_id
            for experience in experiences
            if experience.restaurant_id is not None
            and experience.overall_rating is not None
            and float(experience.overall_rating) >= 4
        }

        negatively_rated_restaurant_ids = {
            experience.restaurant_id
            for experience in experiences
            if experience.restaurant_id is not None
            and experience.overall_rating is not None
            and float(experience.overall_rating) <= 2.5
        }

        results: list[RecommendationItem] = []
        effective_budget = self._effective_budget_symbol(budget, user)

        for restaurant in restaurants:
            score = 0.0
            reasons: list[str] = []
            matched_signals: list[str] = []
            penalized_signals: list[str] = []
            breakdown: dict[str, float] = {}
            strong_matches = 0
            soft_matches = 0
            contradictions = 0

            restaurant_tag_names = [self._normalize_text(tag.name) for tag in restaurant.tags]
            description_text = self._normalize_text(restaurant.description)
            atmosphere_text = self._normalize_text(restaurant.atmosphere)
            social_style = self._normalize_text(restaurant.social_style)
            pace_value = self._normalize_text(restaurant.pace)

            outing_score, outing_strong = self._apply_outing_type_score(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                reasons=reasons,
                matched_signals=matched_signals,
                breakdown=breakdown,
            )
            score += outing_score
            strong_matches += outing_strong

            structured_score, structured_strong, structured_contradictions = self._apply_structured_filter_scoring(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                towns=towns,
                include_tags=include_tags,
                exclude_tags=exclude_tags,
                family_friendly=family_friendly,
                student_friendly=student_friendly,
                date_night=date_night,
                quick_bite=quick_bite,
                fast_food=fast_food,
                requires_dine_in=requires_dine_in,
                requires_takeout=requires_takeout,
                requires_delivery=requires_delivery,
                requires_reservations=requires_reservations,
                requires_live_music=requires_live_music,
                requires_trivia=requires_trivia,
                reasons=reasons,
                matched_signals=matched_signals,
                penalized_signals=penalized_signals,
                breakdown=breakdown,
            )
            score += structured_score
            strong_matches += structured_strong
            contradictions += structured_contradictions

            if effective_budget and restaurant.price_tier == effective_budget:
                score += 2.6
                strong_matches += 1
                self._append_reason(reasons, f"Matches your budget target ({effective_budget})")
                self._append_signal(matched_signals, f"budget fit ({effective_budget})")
                self._add_breakdown(breakdown, "budget", 2.6)
            elif effective_budget == "$$" and restaurant.price_tier in {"$", "$$$"}:
                score += 0.35
                soft_matches += 1
                self._add_breakdown(breakdown, "budget", 0.35)

            if pace and pace_value == self._normalize_text(pace):
                score += 2.3
                strong_matches += 1
                self._append_reason(reasons, f"Fits your preferred pace ({pace})")
                self._append_signal(matched_signals, f"pace fit ({pace})")
                self._add_breakdown(breakdown, "pace", 2.3)

            if social_context and social_style == self._normalize_text(social_context):
                score += 2.5
                strong_matches += 1
                self._append_reason(reasons, f"Works well for your social setting ({social_context})")
                self._append_signal(matched_signals, f"social fit ({social_context})")
                self._add_breakdown(breakdown, "social context", 2.5)

            for value in atmosphere:
                lowered = self._normalize_text(value)
                if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                    score += 1.6
                    soft_matches += 1
                    self._append_reason(reasons, f"Matches the atmosphere you asked for ({value})")
                    self._append_signal(matched_signals, f"atmosphere match ({value})")
                    self._add_breakdown(breakdown, "atmosphere", 1.6)

            for cuisine in preferred_cuisines:
                lowered = self._normalize_text(cuisine)
                if self._has_tag(restaurant_tag_names, lowered):
                    score += 1.85
                    soft_matches += 1
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")
                    self._append_signal(matched_signals, f"interest match ({cuisine})")
                    self._add_breakdown(breakdown, "interests", 1.85)
                elif lowered in description_text or lowered in atmosphere_text:
                    score += 1.0
                    soft_matches += 1
                    self._append_reason(reasons, f"Aligns with your food or drink interest ({cuisine})")
                    self._append_signal(matched_signals, f"interest match ({cuisine})")
                    self._add_breakdown(breakdown, "interests", 1.0)

            # Use Patch 1/2 operational metadata directly
            direct_meta_points = 0.0
            if drinks_focus and restaurant.serves_alcohol:
                direct_meta_points += 1.8
                self._append_reason(reasons, "Supports a drink-focused outing")
                self._append_signal(matched_signals, "drink-focused support")

            if restaurant.supports_brunch and self._has_tag(self._normalize_list(include_tags), "brunch"):
                direct_meta_points += 1.5

            if restaurant.supports_coffee and any(v in {"coffee", "espresso", "cafe"} for v in self._normalize_list(preferred_cuisines)):
                direct_meta_points += 1.3

            if restaurant.is_fast_food and (fast_food is True or self._normalize_text(outing_type) == "quick-bite"):
                direct_meta_points += 1.6

            if restaurant.is_student_friendly and student_friendly is True:
                direct_meta_points += 1.5

            if restaurant.is_family_friendly and family_friendly is True:
                direct_meta_points += 1.5

            if restaurant.has_live_music and requires_live_music is True:
                direct_meta_points += 1.7

            if restaurant.has_trivia_night and requires_trivia is True:
                direct_meta_points += 1.7

            if direct_meta_points:
                score += direct_meta_points
                soft_matches += 1
                self._add_breakdown(breakdown, "direct metadata", direct_meta_points)

            combination_bonus, combination_strong = self._apply_combination_bonus(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                budget=effective_budget,
                pace=pace,
                social_context=social_context,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=drinks_focus,
                atmosphere=atmosphere,
                reasons=reasons,
                matched_signals=matched_signals,
                breakdown=breakdown,
            )
            score += combination_bonus
            strong_matches += combination_strong

            contradiction_penalty, contradiction_count = self._apply_contradiction_penalties(
                restaurant=restaurant,
                restaurant_tag_names=restaurant_tag_names,
                outing_type=outing_type,
                budget=effective_budget,
                pace=pace,
                social_context=social_context,
                drinks_focus=drinks_focus,
                atmosphere=atmosphere,
                reasons=reasons,
                penalized_signals=penalized_signals,
                breakdown=breakdown,
            )
            score += contradiction_penalty
            contradictions += contradiction_count

            if preference is not None:
                preference_points = 0.0

                for value in preference.atmosphere_preferences:
                    lowered = self._normalize_text(value)
                    if lowered in atmosphere_text or self._has_tag(restaurant_tag_names, lowered):
                        score += 1.0
                        preference_points += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved atmosphere preference ({value})")
                        self._append_signal(matched_signals, f"saved atmosphere preference ({value})")

                for value in preference.social_preferences:
                    if social_style and self._normalize_text(value) in social_style:
                        score += 1.0
                        preference_points += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved social preference ({value})")
                        self._append_signal(matched_signals, f"saved social preference ({value})")

                for value in preference.cuisine_preferences:
                    lowered = self._normalize_text(value)
                    if self._has_tag(restaurant_tag_names, lowered) or lowered in description_text:
                        score += 1.0
                        preference_points += 1.0
                        soft_matches += 1
                        self._append_reason(reasons, f"Matches your saved cuisine preference ({value})")
                        self._append_signal(matched_signals, f"saved cuisine preference ({value})")

                if preference.price_sensitivity and restaurant.price_tier == preference.price_sensitivity:
                    score += 0.75
                    preference_points += 0.75
                    soft_matches += 1
                    self._append_reason(reasons, "Fits your saved budget preference")
                    self._append_signal(matched_signals, "saved budget preference")

                if preference.budget_max_per_person is not None and restaurant.price_tier == self._effective_budget_symbol(None, user):
                    score += 0.5
                    preference_points += 0.5
                    soft_matches += 1

                if preference_points != 0:
                    self._add_breakdown(breakdown, "saved preferences", preference_points)

            history_points = 0.0

            if restaurant.id in positively_rated_restaurant_ids:
                score += 1.5
                history_points += 1.5
                soft_matches += 1
                self._append_reason(reasons, "You rated this restaurant well before")
                self._append_signal(matched_signals, "positive rating history")

            if restaurant.id in negatively_rated_restaurant_ids:
                score -= 2.0
                history_points -= 2.0
                contradictions += 1
                self._append_reason(reasons, "Lowered because of a past low rating")
                self._append_signal(penalized_signals, "past low rating")

            if history_points != 0:
                self._add_breakdown(breakdown, "history", history_points)

            suggested_dishes, suggested_drinks = self._select_menu_items(
                restaurant=restaurant,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=drinks_focus,
                outing_type=outing_type,
                include_dish_hints=include_dish_hints,
            )

            if not reasons:
                reasons.append("General profile match")

            confidence_level = self._determine_confidence(
                score=score,
                strong_matches=strong_matches,
                soft_matches=soft_matches,
                contradictions=contradictions,
            )

            explanation = self._build_explanation(
                outing_type=outing_type,
                confidence_level=confidence_level,
                matched_signals=matched_signals,
                penalized_signals=penalized_signals,
            )

            fit_label = self._fit_label(score, confidence_level)

            score_breakdown = [
                ScoreBreakdownItem(label=label, points=round(points, 2))
                for label, points in sorted(
                    breakdown.items(),
                    key=lambda entry: (-abs(entry[1]), entry[0].lower())
                )
            ]

            results.append(
                RecommendationItem(
                    restaurant_id=restaurant.id,
                    restaurant_name=restaurant.name,
                    score=round(score, 2),
                    fit_label=fit_label,
                    reasons=reasons[:6],
                    explanation=explanation,
                    confidence_level=confidence_level,
                    matched_signals=matched_signals[:6],
                    penalized_signals=penalized_signals[:4],
                    score_breakdown=score_breakdown[:8],
                    suggested_dishes=suggested_dishes,
                    suggested_drinks=suggested_drinks,
                )
            )

        results.sort(key=lambda item: item.score, reverse=True)

        ranked_results: list[RecommendationItem] = []
        for index, item in enumerate(results[:5], start=1):
            ranked_results.append(
                RecommendationItem(
                    restaurant_id=item.restaurant_id,
                    restaurant_name=item.restaurant_name,
                    score=item.score,
                    rank=index,
                    fit_label=item.fit_label,
                    reasons=item.reasons,
                    explanation=item.explanation,
                    confidence_level=item.confidence_level,
                    matched_signals=item.matched_signals,
                    penalized_signals=item.penalized_signals,
                    score_breakdown=item.score_breakdown,
                    suggested_dishes=item.suggested_dishes,
                    suggested_drinks=item.suggested_drinks,
                )
            )

        return ranked_results
