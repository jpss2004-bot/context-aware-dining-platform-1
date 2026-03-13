#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" && -d "$ROOT_DIR/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
  BACKEND_DIR="$ROOT_DIR/backend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" && -d "$ROOT_DIR/backend/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
  BACKEND_DIR="$ROOT_DIR/backend/backend"
else
  echo "Error: could not find frontend/src and backend/app from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

python3 - <<PY
from pathlib import Path
import sys

def replace_or_fail(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Failed to patch {label}: target block not found.")
    return text.replace(old, new, 1)

# --------------------------
# BACKEND: schemas/recommendation.py
# --------------------------
schema_path = Path(r"$BACKEND_DIR/app/schemas/recommendation.py")
schema_text = schema_path.read_text()

old_schema = '''class SurpriseMeRequest(BaseModel):
    include_drinks: bool = False
'''

new_schema = '''class SurpriseMeRequest(BaseModel):
    include_drinks: bool = False
    exclude_restaurant_ids: list[int] = Field(default_factory=list)
    count: int = Field(default=5, ge=1, le=5)
'''

schema_text = replace_or_fail(
    schema_text,
    old_schema,
    new_schema,
    "backend surprise request schema"
)
schema_path.write_text(schema_text)

# --------------------------
# BACKEND: services/recommendation_service.py
# --------------------------
service_path = Path(r"$BACKEND_DIR/app/services/recommendation_service.py")
service_text = service_path.read_text()

old_surprise_method = '''    def surprise_me(self, user: User, payload: SurpriseMeRequest) -> RecommendationResponse:
        restaurants = self.restaurant_repository.list_restaurants_with_details()
        preference = user.preference

        preferred_atmosphere = preference.atmosphere_preferences if preference else []
        preferred_cuisines = preference.cuisine_preferences if preference else []
        preferred_social = preference.social_preferences if preference else []

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
        )
        return RecommendationResponse(
            mode="surprise-me",
            engine_version=self.ENGINE_VERSION,
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type="surprise",
                budget=preference.price_sensitivity if preference else None,
                pace=None,
                social_context=preferred_social[0] if preferred_social else None,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=payload.include_drinks,
                atmosphere=preferred_atmosphere,
            ),
            results=ranked,
        )
'''

new_surprise_method = '''    def surprise_me(self, user: User, payload: SurpriseMeRequest) -> RecommendationResponse:
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
            engine_version=self.ENGINE_VERSION,
            generated_at=self._timestamp(),
            request_summary=self._build_request_summary(
                outing_type="surprise",
                budget=preference.price_sensitivity if preference else None,
                pace=None,
                social_context=preferred_social[0] if preferred_social else None,
                preferred_cuisines=preferred_cuisines,
                drinks_focus=payload.include_drinks,
                atmosphere=preferred_atmosphere,
            ),
            results=final_results,
        )
'''

service_text = replace_or_fail(
    service_text,
    old_surprise_method,
    new_surprise_method,
    "backend surprise_me method"
)

helper_anchor = '''    def _timestamp(self) -> str:
        return datetime.now(timezone.utc).isoformat()
'''

helper_block = '''    def _apply_surprise_novelty(
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
'''

service_text = replace_or_fail(
    service_text,
    helper_anchor,
    helper_block,
    "backend surprise helper insertion"
)

service_path.write_text(service_text)

# --------------------------
# FRONTEND: src/pages/RecommendationsPage.tsx
# --------------------------
rec_path = Path(r"$FRONTEND_DIR/src/pages/RecommendationsPage.tsx")
rec_text = rec_path.read_text()

old_mode_meta = '''  surprise: {
    eyebrow: "Discovery mode",
    title: "Let SAVR Surprise You",
    subtitle: "Get recommendationes quickly with minimal friction.",
    bullets: [
      "Fastest path to discovery.",
      "Uses your saved preferences when available.",
      "Good for novelty and low-effort browsing."
    ]
  }
'''

new_mode_meta = '''  surprise: {
    eyebrow: "Discovery mode",
    title: "Let SAVR Surprise You",
    subtitle:
      "Get five personalized recommendations that refresh each time while still respecting your profile, history, and saved preferences.",
    bullets: [
      "Generates a fresh five-option set each time when possible.",
      "Uses your profile, favorites, and experience history to stay personal.",
      "Lets you decide whether drink-friendly places should be prioritized."
    ]
  }
'''

rec_text = replace_or_fail(
    rec_text,
    old_mode_meta,
    new_mode_meta,
    "frontend surprise mode meta"
)

old_state_line = '''  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);
'''

new_state_line = '''  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);
  const [lastSurpriseRestaurantIds, setLastSurpriseRestaurantIds] = useState<number[]>([]);
'''

rec_text = replace_or_fail(
    rec_text,
    old_state_line,
    new_state_line,
    "frontend surprise state"
)

old_handle_surprise = '''  async function handleSurprise() {
    await runRequest("/recommendations/surprise-me", {
      include_drinks: includeDrinks
    });
  }
'''

new_handle_surprise = '''  async function handleSurprise() {
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = await apiRequest<RecommendationResponse>("/recommendations/surprise-me", {
        method: "POST",
        body: {
          include_drinks: includeDrinks,
          exclude_restaurant_ids: lastSurpriseRestaurantIds,
          count: 5
        }
      });

      const recs = Array.isArray(data.results) ? data.results : [];

      setResults(recs);
      setLastResponse(data);
      setLastSurpriseRestaurantIds(recs.map((item) => item.restaurant_id));

      setSuccess(
        recs.length > 0
          ? `Generated ${recs.length} personalized surprise recommendation${recs.length === 1 ? "" : "s"}.`
          : "Request completed, but no surprise recommendations were returned."
      );
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Failed to generate surprise recommendations.";
      setError(message);
      setResults([]);
      setLastResponse(null);
    } finally {
      setLoading(false);
    }
  }
'''

rec_text = replace_or_fail(
    rec_text,
    old_handle_surprise,
    new_handle_surprise,
    "frontend surprise handler"
)

old_surprise_ui = '''          {mode === "surprise" ? (
            <div className="form">
              <div className="item">
                <strong>Low-friction discovery</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  This mode sends a minimal valid backend payload and uses your saved
                  onboarding preferences when available.
                </p>
              </div>

              <div className="form-row">
                <label htmlFor="include_drinks">Include drinks</label>
                <input
                  id="include_drinks"
                  type="checkbox"
                  checked={includeDrinks}
                  onChange={(e) => setIncludeDrinks(e.target.checked)}
                />
              </div>

              <div className="button-row">
                <Button onClick={handleSurprise} disabled={loading}>
                  {loading ? "Finding a surprise..." : "Surprise me"}
                </Button>
              </div>
            </div>
          ) : null}
'''

new_surprise_ui = '''          {mode === "surprise" ? (
            <div className="form">
              <div className="item">
                <strong>Personalized surprise mode</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  SAVR uses your saved profile, favorite restaurants, and dining history to
                  choose five recommendations that feel personal instead of purely random.
                </p>
              </div>

              <div className="build-section">
                <div className="build-section__copy">
                  <strong>Should drinks matter in this surprise run?</strong>
                  <p className="muted">
                    Turn this on when you want bars, wine-forward spaces, breweries, or drink-friendly venues to matter more.
                  </p>
                </div>
                <div className="build-block-grid build-block-grid--compact">
                  {yesNoOptions.map((option) => {
                    const active = includeDrinks === (option.value === "yes");
                    return (
                      <button
                        key={option.value}
                        type="button"
                        className={active ? "build-block active" : "build-block"}
                        onClick={() => setIncludeDrinks(option.value === "yes")}
                      >
                        <span className="build-block__label">{option.label}</span>
                        {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="item">
                <strong>Fresh results each time</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Each new surprise request excludes the last five surprise results when possible, so the next run feels fresh while staying aligned with your profile.
                </p>
              </div>

              <div className="button-row">
                <Button onClick={handleSurprise} disabled={loading}>
                  {loading ? "Finding a new surprise..." : "Let SAVR surprise me"}
                </Button>
              </div>
            </div>
          ) : null}
'''

rec_text = replace_or_fail(
    rec_text,
    old_surprise_ui,
    new_surprise_ui,
    "frontend surprise UI"
)

rec_path.write_text(rec_text)

print("Phase 10 surprise mode rework applied successfully.")
PY

echo "Updated backend files:"
echo " - app/schemas/recommendation.py"
echo " - app/services/recommendation_service.py"
echo
echo "Updated frontend files:"
echo " - src/pages/RecommendationsPage.tsx"
