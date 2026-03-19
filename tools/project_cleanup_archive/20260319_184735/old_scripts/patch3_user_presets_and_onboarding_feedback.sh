#!/bin/bash
set -e

PROJECT_ROOT="$(pwd)"

if [ ! -d "$PROJECT_ROOT/frontend/src" ]; then
  echo "Required frontend directory not found: $PROJECT_ROOT/frontend/src"
  exit 1
fi

FRONTEND_DIR="$PROJECT_ROOT/frontend"
RECOMMENDATIONS_PAGE="$FRONTEND_DIR/src/pages/RecommendationsPage.tsx"
PROFILE_PAGE="$FRONTEND_DIR/src/pages/ProfilePage.tsx"
ONBOARDING_PAGE="$FRONTEND_DIR/src/pages/OnboardingPage.tsx"
STYLES_FILE="$FRONTEND_DIR/src/styles.css"

for path in \
  "$FRONTEND_DIR/package.json" \
  "$RECOMMENDATIONS_PAGE" \
  "$PROFILE_PAGE" \
  "$ONBOARDING_PAGE" \
  "$STYLES_FILE"
do
  if [ ! -f "$path" ]; then
    echo "Required file missing: $path"
    exit 1
  fi
done

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.patch3_user_presets_and_onboarding_feedback_backup_$STAMP"
mkdir -p "$BACKUP_DIR/frontend/src/pages" "$BACKUP_DIR/frontend/src"

cp "$RECOMMENDATIONS_PAGE" "$BACKUP_DIR/frontend/src/pages/RecommendationsPage.tsx"
cp "$PROFILE_PAGE" "$BACKUP_DIR/frontend/src/pages/ProfilePage.tsx"
cp "$ONBOARDING_PAGE" "$BACKUP_DIR/frontend/src/pages/OnboardingPage.tsx"
cp "$STYLES_FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Backup created at: $BACKUP_DIR"

cat > "$RECOMMENDATIONS_PAGE" <<'EOF'
import { FormEvent, useEffect, useMemo, useState } from "react";

import RecommendationCard from "../components/dining/RecommendationCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";

type Mode = "build" | "describe" | "surprise";
type BuildFlowStage = "builder" | "preset-review";
type SingleBuildField = "outing_type" | "budget" | "pace" | "social_context";
type MultiBuildField = "preferred_cuisines" | "atmosphere";

type BuildFormState = {
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
};

type BlockOption = {
  label: string;
  value: string;
  hint?: string;
};

type SavedRun = {
  id: string;
  createdAt: string;
  engineVersion: string;
  requestSummary: BuildFormState;
  resultCount: number;
  topResultName: string | null;
};

type ScoreBreakdownItem = {
  label: string;
  points: number;
};

type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  rank?: number;
  fit_label?: string;
  reasons: string[];
  explanation?: string | null;
  confidence_level?: "high" | "medium" | "exploratory" | string;
  matched_signals?: string[];
  penalized_signals?: string[];
  score_breakdown?: ScoreBreakdownItem[];
  suggested_dishes: string[];
  suggested_drinks: string[];
};

type RecommendationRequestSummary = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus: boolean;
  atmosphere: string[];
};

type RecommendationResponse = {
  mode: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: RecommendationRequestSummary;
  results: RecommendationItem[];
};

type PresetSelectionPayload = {
  outing_type?: string | null;
  mood?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus?: boolean | null;
  atmosphere: string[];
  towns?: string[];
  include_tags?: string[];
  exclude_tags?: string[];
  family_friendly?: boolean | null;
  student_friendly?: boolean | null;
  date_night?: boolean | null;
  quick_bite?: boolean | null;
  fast_food?: boolean | null;
  requires_dine_in?: boolean | null;
  requires_takeout?: boolean | null;
  requires_delivery?: boolean | null;
  requires_reservations?: boolean | null;
  requires_live_music?: boolean | null;
  requires_trivia?: boolean | null;
  include_dish_hints?: boolean | null;
};

type PresetResponse = {
  preset_id: string;
  owner_type: "system" | "user" | string;
  owner_user_id?: number | null;
  is_editable: boolean;
  name: string;
  description?: string | null;
  selection_payload: PresetSelectionPayload;
  created_at?: string | null;
  updated_at?: string | null;
};

type PresetApplyResponse = {
  preset: PresetResponse;
  builder_payload: PresetSelectionPayload;
  banner_message: string;
  can_customize: boolean;
};

type PresetEditorState = {
  name: string;
  description: string;
  presetId: string | null;
  isEditing: boolean;
};

const RUN_STORAGE_KEY = "build-your-night-recent-runs-v1";

const modeMeta: Record<
  Mode,
  {
    eyebrow: string;
    title: string;
    subtitle: string;
    bullets: string[];
  }
> = {
  build: {
    eyebrow: "Guided mode",
    title: "Build Your SAVR Night",
    subtitle:
      "Choose clear experience blocks that map directly to the recommendation engine.",
    bullets: [
      "Uses canonical values shared with the backend scorer.",
      "Best for controlled demos and predictable comparisons.",
      "Supports backend presets, preset review, and user-created reusable presets."
    ]
  },
  describe: {
    eyebrow: "Describe mode",
    title: "Describe the Night",
    subtitle:
      "Describe the kind of night you want in natural language and let SAVR interpret it.",
    bullets: [
      "Best when the vibe matters more than rigid form fields.",
      "Feels closer to a personal dining assistant.",
      "Useful for testing natural-language intent parsing."
    ]
  },
  surprise: {
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
};

const outingOptions: BlockOption[] = [
  { label: "Casual bite", value: "casual-bite", hint: "easy, flexible, low-pressure" },
  { label: "Date night", value: "date-night", hint: "romantic, polished, slower" },
  { label: "Group dinner", value: "group-dinner", hint: "social, shareable, energetic" },
  { label: "Drinks night", value: "drinks-night", hint: "beer, wine, pub, brewery" },
  { label: "Quick bite", value: "quick-bite", hint: "fast, convenient, affordable" },
  { label: "Coffee stop", value: "coffee-stop", hint: "café, coffeehouse, study-friendly" },
  { label: "Special occasion", value: "special-occasion", hint: "refined, scenic, memorable" }
];

const budgetOptions: BlockOption[] = [
  { label: "$", value: "$", hint: "budget-friendly" },
  { label: "$$", value: "$$", hint: "mid-range" },
  { label: "$$$", value: "$$$", hint: "premium" }
];

const paceOptions: BlockOption[] = [
  { label: "Fast", value: "fast" },
  { label: "Moderate", value: "moderate" },
  { label: "Slow", value: "slow" },
  { label: "Leisurely", value: "leisurely" }
];

const socialOptions: BlockOption[] = [
  { label: "Solo", value: "solo" },
  { label: "Friends", value: "friends" },
  { label: "Group", value: "group" },
  { label: "Date", value: "date" }
];

const cuisineOptions: BlockOption[] = [
  { label: "Pizza", value: "pizza" },
  { label: "Mediterranean", value: "mediterranean" },
  { label: "Asian", value: "asian" },
  { label: "Bakery", value: "bakery" },
  { label: "Dessert", value: "dessert" },
  { label: "Seasonal", value: "seasonal" },
  { label: "Turkish", value: "turkish" },
  { label: "Coffee", value: "coffee" },
  { label: "Beer", value: "beer" },
  { label: "Wine", value: "wine" },
  { label: "Cider", value: "cider" }
];

const atmosphereOptions: BlockOption[] = [
  { label: "Cozy", value: "cozy" },
  { label: "Lively", value: "lively" },
  { label: "Quiet", value: "quiet" },
  { label: "Casual", value: "casual" },
  { label: "Scenic", value: "scenic" },
  { label: "Historic", value: "historic" },
  { label: "Refined", value: "refined" },
  { label: "Upscale", value: "upscale" },
  { label: "Rustic", value: "rustic" }
];

const yesNoOptions: BlockOption[] = [
  { label: "Yes", value: "yes", hint: "drinks should matter" },
  { label: "No", value: "no", hint: "food and setting first" }
];

const initialBuildForm: BuildFormState = {
  outing_type: "casual-bite",
  budget: "",
  pace: "",
  social_context: "",
  preferred_cuisines: [],
  atmosphere: [],
  drinks_focus: false
};

const emptyPresetEditor: PresetEditorState = {
  name: "",
  description: "",
  presetId: null,
  isEditing: false
};

function normalizeScore(score?: number): number | undefined {
  if (typeof score !== "number" || Number.isNaN(score)) {
    return undefined;
  }

  return Math.max(0, Math.min(score / 14, 1));
}

function normalizeRecommendation(item: RecommendationItem, index: number) {
  const reasons = item.reasons ?? [];
  const suggestedDishes = item.suggested_dishes ?? [];
  const suggestedDrinks = item.suggested_drinks ?? [];

  const tagValues = [
    ...suggestedDishes.map((dish) => `dish: ${dish}`),
    ...suggestedDrinks.map((drink) => `drink: ${drink}`)
  ].slice(0, 4);

  return {
    id: item.restaurant_id ?? index,
    title: item.restaurant_name ?? `Recommendation ${index + 1}`,
    restaurantName: item.restaurant_name,
    rank: item.rank,
    fitLabel: item.fit_label,
    explanation:
      item.explanation ||
      (reasons.length > 0
        ? reasons.join(" • ")
        : "This restaurant matched your current dining request."),
    score: normalizeScore(item.score),
    confidenceLevel: item.confidence_level,
    matchedSignals: item.matched_signals ?? [],
    penalizedSignals: item.penalized_signals ?? [],
    scoreBreakdown: item.score_breakdown ?? [],
    tags: tagValues
  };
}

function toggleArrayValue(values: string[], value: string): string[] {
  if (values.includes(value)) {
    return values.filter((entry) => entry !== value);
  }

  return [...values, value];
}

function formatRunSummary(run: SavedRun): string {
  const parts: string[] = [];
  if (run.requestSummary.outing_type) parts.push(run.requestSummary.outing_type);
  if (run.requestSummary.budget) parts.push(run.requestSummary.budget);
  if (run.requestSummary.pace) parts.push(run.requestSummary.pace);
  if (run.requestSummary.social_context) parts.push(run.requestSummary.social_context);
  return parts.join(" • ");
}

function formatLabel(value: string) {
  return value
    .replace(/[_-]/g, " ")
    .split(" ")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function buildFormFromPresetPayload(payload: PresetSelectionPayload): BuildFormState {
  return {
    outing_type: payload.outing_type || initialBuildForm.outing_type,
    budget: payload.budget || "",
    pace: payload.pace || "",
    social_context: payload.social_context || "",
    preferred_cuisines: Array.isArray(payload.preferred_cuisines)
      ? payload.preferred_cuisines
      : [],
    atmosphere: Array.isArray(payload.atmosphere) ? payload.atmosphere : [],
    drinks_focus: Boolean(payload.drinks_focus)
  };
}

function buildSelectionPayload(form: BuildFormState): PresetSelectionPayload {
  return {
    outing_type: form.outing_type || null,
    budget: form.budget || null,
    pace: form.pace || null,
    social_context: form.social_context || null,
    preferred_cuisines: form.preferred_cuisines,
    drinks_focus: form.drinks_focus,
    atmosphere: form.atmosphere
  };
}

function summarizePresetPayload(payload: PresetSelectionPayload): string[] {
  const chips: string[] = [];

  if (payload.outing_type) chips.push(`outing: ${formatLabel(payload.outing_type)}`);
  if (payload.budget) chips.push(`budget: ${payload.budget}`);
  if (payload.pace) chips.push(`pace: ${formatLabel(payload.pace)}`);
  if (payload.social_context) chips.push(`social: ${formatLabel(payload.social_context)}`);
  if (payload.drinks_focus !== undefined && payload.drinks_focus !== null) {
    chips.push(`drinks focus: ${payload.drinks_focus ? "Yes" : "No"}`);
  }

  (payload.preferred_cuisines || []).forEach((value) =>
    chips.push(`cuisine: ${formatLabel(value)}`)
  );
  (payload.atmosphere || []).forEach((value) =>
    chips.push(`atmosphere: ${formatLabel(value)}`)
  );

  if (payload.fast_food) chips.push("fast food");
  if (payload.requires_live_music) chips.push("live music");
  if (payload.requires_trivia) chips.push("trivia");

  return chips;
}

function BlockSection({
  title,
  subtitle,
  options,
  selectedValue,
  onSelect
}: {
  title: string;
  subtitle: string;
  options: BlockOption[];
  selectedValue: string;
  onSelect: (value: string) => void;
}) {
  return (
    <div className="build-section">
      <div className="build-section__copy">
        <strong>{title}</strong>
        <p className="muted">{subtitle}</p>
      </div>
      <div className="build-block-grid">
        {options.map((option) => {
          const active = selectedValue === option.value;
          return (
            <button
              key={option.value}
              type="button"
              className={active ? "build-block active" : "build-block"}
              onClick={() => onSelect(option.value)}
            >
              <span className="build-block__label">{option.label}</span>
              {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function MultiBlockSection({
  title,
  subtitle,
  options,
  selectedValues,
  onToggle
}: {
  title: string;
  subtitle: string;
  options: BlockOption[];
  selectedValues: string[];
  onToggle: (value: string) => void;
}) {
  return (
    <div className="build-section">
      <div className="build-section__copy">
        <strong>{title}</strong>
        <p className="muted">{subtitle}</p>
      </div>
      <div className="build-block-grid">
        {options.map((option) => {
          const active = selectedValues.includes(option.value);
          return (
            <button
              key={option.value}
              type="button"
              className={active ? "build-block active" : "build-block"}
              onClick={() => onToggle(option.value)}
            >
              <span className="build-block__label">{option.label}</span>
              {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [buildFlowStage, setBuildFlowStage] = useState<BuildFlowStage>("builder");
  const [loading, setLoading] = useState(false);
  const [presetLoading, setPresetLoading] = useState(false);
  const [presetListLoading, setPresetListLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [presetBanner, setPresetBanner] = useState("");
  const [results, setResults] = useState<RecommendationItem[]>([]);
  const [lastResponse, setLastResponse] = useState<RecommendationResponse | null>(null);
  const [savedRuns, setSavedRuns] = useState<SavedRun[]>([]);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [activePreset, setActivePreset] = useState<PresetApplyResponse | null>(null);
  const [presetEditor, setPresetEditor] = useState<PresetEditorState>(emptyPresetEditor);
  const [showPresetEditor, setShowPresetEditor] = useState(false);

  const [buildForm, setBuildForm] = useState<BuildFormState>(initialBuildForm);
  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);
  const [lastSurpriseRestaurantIds, setLastSurpriseRestaurantIds] = useState<number[]>([]);

  const activeMeta = modeMeta[mode];

  useEffect(() => {
    try {
      const raw = localStorage.getItem(RUN_STORAGE_KEY);
      if (!raw) return;
      const parsed = JSON.parse(raw) as SavedRun[];
      if (Array.isArray(parsed)) {
        setSavedRuns(parsed);
      }
    } catch {
      setSavedRuns([]);
    }
  }, []);

  async function fetchPresets() {
    setPresetListLoading(true);
    try {
      const data = await apiRequest<PresetResponse[]>("/presets");
      setPresets(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load presets.");
    } finally {
      setPresetListLoading(false);
    }
  }

  useEffect(() => {
    void fetchPresets();
  }, []);

  const normalizedResults = useMemo(
    () => results.map((item, index) => normalizeRecommendation(item, index)),
    [results]
  );

  const buildSummary = useMemo(() => {
    const parts: string[] = [];

    if (buildForm.outing_type) parts.push(`outing: ${buildForm.outing_type}`);
    if (buildForm.budget) parts.push(`budget: ${buildForm.budget}`);
    if (buildForm.pace) parts.push(`pace: ${buildForm.pace}`);
    if (buildForm.social_context) parts.push(`social: ${buildForm.social_context}`);
    if (buildForm.preferred_cuisines.length > 0) {
      parts.push(`interests: ${buildForm.preferred_cuisines.join(", ")}`);
    }
    if (buildForm.atmosphere.length > 0) {
      parts.push(`atmosphere: ${buildForm.atmosphere.join(", ")}`);
    }
    parts.push(`drinks focus: ${buildForm.drinks_focus ? "yes" : "no"}`);

    return parts;
  }, [buildForm]);

  const activePresetChips = useMemo(
    () => (activePreset ? summarizePresetPayload(activePreset.builder_payload) : []),
    [activePreset]
  );

  const userPresets = useMemo(
    () => presets.filter((preset) => preset.owner_type === "user"),
    [presets]
  );

  function persistRun(data: RecommendationResponse, requestSummary: BuildFormState) {
    const nextRun: SavedRun = {
      id: `${Date.now()}`,
      createdAt: data.generated_at || new Date().toISOString(),
      engineVersion: data.engine_version || "unknown",
      requestSummary,
      resultCount: data.results.length,
      topResultName: data.results[0]?.restaurant_name || null
    };

    const nextRuns = [nextRun, ...savedRuns].slice(0, 8);
    setSavedRuns(nextRuns);
    localStorage.setItem(RUN_STORAGE_KEY, JSON.stringify(nextRuns));
  }

  async function runRequest(
    endpoint: string,
    payload: Record<string, unknown>,
    options?: { saveBuildRun?: boolean; buildState?: BuildFormState }
  ) {
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = await apiRequest<RecommendationResponse>(endpoint, {
        method: "POST",
        body: payload
      });

      const recs = Array.isArray(data.results) ? data.results : [];

      setResults(recs);
      setLastResponse(data);

      if (options?.saveBuildRun && options.buildState) {
        persistRun(data, options.buildState);
      }

      setSuccess(
        recs.length > 0
          ? `Generated ${recs.length} recommendation${recs.length === 1 ? "" : "s"}.`
          : "Request completed, but no recommendations were returned."
      );
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Failed to generate recommendations.";
      setError(message);
      setResults([]);
      setLastResponse(null);
    } finally {
      setLoading(false);
    }
  }

  async function handleBuildSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest(
      "/recommendations/build-your-night",
      {
        outing_type: buildForm.outing_type,
        budget: buildForm.budget || null,
        pace: buildForm.pace || null,
        social_context: buildForm.social_context || null,
        preferred_cuisines: buildForm.preferred_cuisines,
        drinks_focus: buildForm.drinks_focus,
        atmosphere: buildForm.atmosphere
      },
      {
        saveBuildRun: true,
        buildState: buildForm
      }
    );
  }

  async function handleDescribeSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest("/recommendations/describe-your-night", {
      prompt: describeText.trim()
    });
  }

  async function handleSurprise() {
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
          ? `Generated ${recs.length} surprise recommendation${recs.length === 1 ? "" : "s"}.`
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

  function selectSingle(field: SingleBuildField, value: string) {
    setBuildForm((prev) => ({ ...prev, [field]: prev[field] === value ? "" : value }));
  }

  function toggleMulti(field: MultiBuildField, value: string) {
    setBuildForm((prev) => ({
      ...prev,
      [field]: toggleArrayValue(prev[field], value)
    }));
  }

  function resetPresetEditor() {
    setPresetEditor(emptyPresetEditor);
    setShowPresetEditor(false);
  }

  function resetBuildForm() {
    setBuildForm(initialBuildForm);
    setActivePreset(null);
    setPresetBanner("");
    setBuildFlowStage("builder");
    resetPresetEditor();
    setSuccess("Builder reset to a clean state.");
    setError("");
  }

  async function applyPresetById(presetId: string) {
    setPresetLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = await apiRequest<PresetApplyResponse>(`/presets/${presetId}/apply`, {
        method: "POST"
      });

      setMode("build");
      setActivePreset(data);
      setBuildForm(buildFormFromPresetPayload(data.builder_payload));
      setPresetBanner(data.banner_message);
      setBuildFlowStage("preset-review");
      setSuccess(data.banner_message);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to apply preset.");
    } finally {
      setPresetLoading(false);
    }
  }

  function continueToCustomize() {
    setBuildFlowStage("builder");
    setSuccess(
      activePreset
        ? `Preset "${activePreset.preset.name}" loaded into the builder. You can now customize any field.`
        : "Builder ready for customization."
    );
  }

  async function generateFromAppliedPreset() {
    await runRequest(
      "/recommendations/build-your-night",
      {
        outing_type: buildForm.outing_type,
        budget: buildForm.budget || null,
        pace: buildForm.pace || null,
        social_context: buildForm.social_context || null,
        preferred_cuisines: buildForm.preferred_cuisines,
        drinks_focus: buildForm.drinks_focus,
        atmosphere: buildForm.atmosphere
      },
      {
        saveBuildRun: true,
        buildState: buildForm
      }
    );

    setBuildFlowStage("builder");
  }

  function applySavedRun(run: SavedRun) {
    setMode("build");
    setBuildForm(run.requestSummary);
    setActivePreset(null);
    setPresetBanner("A previous builder run was loaded back into the builder.");
    setBuildFlowStage("builder");
    setSuccess("Saved build reapplied.");
    setError("");
  }

  function clearSavedRuns() {
    setSavedRuns([]);
    localStorage.removeItem(RUN_STORAGE_KEY);
  }

  function exportDiagnostics() {
    if (!lastResponse) {
      setError("No diagnostics available to export yet.");
      return;
    }

    const blob = new Blob([JSON.stringify(lastResponse, null, 2)], {
      type: "application/json"
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    anchor.href = url;
    anchor.download = `recommendation-diagnostics-${stamp}.json`;
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
  }

  function openCreatePreset() {
    setPresetEditor({
      name: "",
      description: "",
      presetId: null,
      isEditing: false
    });
    setShowPresetEditor(true);
    setSuccess("");
    setError("");
  }

  function openEditPreset(preset: PresetResponse) {
    setPresetEditor({
      name: preset.name,
      description: preset.description || "",
      presetId: preset.preset_id,
      isEditing: true
    });
    setShowPresetEditor(true);
    setSuccess("");
    setError("");
  }

  async function saveCurrentBuilderAsPreset(event: FormEvent) {
    event.preventDefault();

    if (!buildForm.outing_type) {
      setError("An outing type is required before saving a preset.");
      return;
    }

    if (!presetEditor.name.trim()) {
      setError("Preset name is required.");
      return;
    }

    setPresetLoading(true);
    setError("");
    setSuccess("");

    const payload = {
      name: presetEditor.name.trim(),
      description: presetEditor.description.trim() || null,
      selection_payload: buildSelectionPayload(buildForm)
    };

    try {
      if (presetEditor.isEditing && presetEditor.presetId) {
        await apiRequest(`/presets/${presetEditor.presetId}`, {
          method: "PUT",
          body: payload
        });
        setSuccess(`Preset "${presetEditor.name.trim()}" updated successfully.`);
      } else {
        await apiRequest("/presets", {
          method: "POST",
          body: payload
        });
        setSuccess(`Preset "${presetEditor.name.trim()}" saved to your account.`);
      }

      resetPresetEditor();
      await fetchPresets();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save preset.");
    } finally {
      setPresetLoading(false);
    }
  }

  async function deleteUserPreset(preset: PresetResponse) {
    const confirmDelete = window.confirm(
      `Delete the preset "${preset.name}" from your account?`
    );

    if (!confirmDelete) {
      return;
    }

    setPresetLoading(true);
    setError("");
    setSuccess("");

    try {
      await apiRequest(`/presets/${preset.preset_id}`, {
        method: "DELETE"
      });
      setSuccess(`Preset "${preset.name}" deleted.`);
      if (presetEditor.presetId === preset.preset_id) {
        resetPresetEditor();
      }
      await fetchPresets();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete preset.");
    } finally {
      setPresetLoading(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendation studio</p>
        <h1 className="page-title">Generate a better dining fit</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Choose the mode that best matches your decision style. Structured inputs
          give you tighter control, prompt mode feels more conversational, and
          surprise mode is the fastest path to discovery.
        </p>
      </section>

      <section className="grid grid-3">
        <button
          type="button"
          className={mode === "build" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("build")}
        >
          <p className="navbar-eyebrow">Structured</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Build Your SAVR Night
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want more control over the recommendation signals.
          </p>
        </button>

        <button
          type="button"
          className={mode === "describe" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("describe")}
        >
          <p className="navbar-eyebrow">Natural language</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Describe the Night
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want to describe the vibe in your own words.
          </p>
        </button>

        <button
          type="button"
          className={mode === "surprise" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("surprise")}
        >
          <p className="navbar-eyebrow">Fast path</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Let SAVR Surprise You
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want novelty with almost no effort.
          </p>
        </button>
      </section>

      {mode === "build" ? (
        <>
          <section className="card">
            <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap", alignItems: "center" }}>
              <div>
                <p className="navbar-eyebrow">Preset library</p>
                <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>System presets and your custom presets</h3>
                <p className="muted" style={{ margin: 0 }}>
                  Apply backend presets instantly. Save your own builder configurations to your account and reuse them later.
                </p>
              </div>
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                <Badge tone="accent">
                  {presetListLoading ? "Loading presets" : `${presets.length} preset${presets.length === 1 ? "" : "s"}`}
                </Badge>
                <Badge tone="success">
                  {userPresets.length} your preset{userPresets.length === 1 ? "" : "s"}
                </Badge>
              </div>
            </div>

            <div className="button-row" style={{ marginTop: "1rem" }}>
              <Button variant="secondary" onClick={openCreatePreset}>
                Save current builder as preset
              </Button>
            </div>

            {showPresetEditor ? (
              <form className="preset-editor-panel" onSubmit={saveCurrentBuilderAsPreset}>
                <div className="form-row">
                  <label htmlFor="preset_name">Preset name</label>
                  <input
                    id="preset_name"
                    value={presetEditor.name}
                    onChange={(e) =>
                      setPresetEditor((prev) => ({ ...prev, name: e.target.value }))
                    }
                    placeholder="Example: Budget date night"
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="preset_description">Description</label>
                  <textarea
                    id="preset_description"
                    rows={3}
                    value={presetEditor.description}
                    onChange={(e) =>
                      setPresetEditor((prev) => ({ ...prev, description: e.target.value }))
                    }
                    placeholder="What is this preset good for?"
                  />
                </div>

                <div className="preset-chip-row">
                  {buildSummary.map((chip) => (
                    <span key={`editor-${chip}`} className="preset-chip">
                      {chip}
                    </span>
                  ))}
                </div>

                <div className="button-row">
                  <Button type="submit" disabled={presetLoading}>
                    {presetLoading
                      ? "Saving..."
                      : presetEditor.isEditing
                      ? "Update preset"
                      : "Save preset"}
                  </Button>
                  <Button type="button" variant="ghost" onClick={resetPresetEditor}>
                    Cancel
                  </Button>
                </div>
              </form>
            ) : null}

            {presetListLoading ? (
              <p className="muted" style={{ marginTop: "1rem", marginBottom: 0 }}>
                Loading preset library...
              </p>
            ) : presets.length === 0 ? (
              <p className="muted" style={{ marginTop: "1rem", marginBottom: 0 }}>
                No presets available yet.
              </p>
            ) : (
              <div className="preset-library-grid" style={{ marginTop: "1rem" }}>
                {presets.map((preset) => (
                  <div key={preset.preset_id} className="preset-card">
                    <div className="preset-card__header">
                      <strong>{preset.name}</strong>
                      <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                        <Badge tone={preset.owner_type === "user" ? "success" : "accent"}>
                          {preset.owner_type === "user" ? "Your preset" : "System preset"}
                        </Badge>
                        {preset.is_editable ? <Badge>Editable</Badge> : null}
                      </div>
                    </div>

                    <p className="muted" style={{ marginTop: "0.45rem", marginBottom: "0.75rem" }}>
                      {preset.description || "No preset description available."}
                    </p>

                    <div className="preset-chip-row">
                      {summarizePresetPayload(preset.selection_payload)
                        .slice(0, 6)
                        .map((chip) => (
                          <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                            {chip}
                          </span>
                        ))}
                    </div>

                    <div className="button-row" style={{ marginTop: "0.9rem" }}>
                      <Button
                        variant="secondary"
                        onClick={() => applyPresetById(preset.preset_id)}
                        disabled={presetLoading}
                      >
                        {presetLoading ? "Applying..." : "Apply preset"}
                      </Button>

                      {preset.owner_type === "user" ? (
                        <>
                          <Button variant="ghost" onClick={() => openEditPreset(preset)}>
                            Edit
                          </Button>
                          <Button variant="ghost" onClick={() => deleteUserPreset(preset)}>
                            Delete
                          </Button>
                        </>
                      ) : null}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>

          <section className="card">
            <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap", alignItems: "center" }}>
              <div>
                <p className="navbar-eyebrow">Saved runs</p>
                <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>Recent Build Your SAVR Night runs</h3>
                <p className="muted" style={{ margin: 0 }}>
                  Reapply earlier builds fast and export the latest diagnostics for QA.
                </p>
              </div>
              <div className="button-row">
                <Button variant="secondary" onClick={exportDiagnostics}>
                  Export latest diagnostics
                </Button>
                <Button variant="ghost" onClick={clearSavedRuns}>
                  Clear saved runs
                </Button>
              </div>
            </div>

            {savedRuns.length === 0 ? (
              <p className="muted" style={{ marginTop: "1rem", marginBottom: 0 }}>
                No saved runs yet. Generate a Build Your SAVR Night recommendation to populate this panel.
              </p>
            ) : (
              <div style={{ display: "grid", gap: "0.8rem", marginTop: "1rem" }}>
                {savedRuns.map((run) => (
                  <div
                    key={run.id}
                    style={{
                      border: "1px solid rgba(148, 163, 184, 0.18)",
                      borderRadius: "1rem",
                      padding: "0.9rem",
                      background: "rgba(15, 23, 42, 0.32)",
                      display: "grid",
                      gap: "0.45rem"
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
                      <strong>{formatRunSummary(run) || "Saved build"}</strong>
                      <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                        <Badge tone="accent">{run.engineVersion}</Badge>
                        <Badge>{run.resultCount} results</Badge>
                      </div>
                    </div>
                    <p className="muted" style={{ margin: 0 }}>
                      Top result: {run.topResultName || "none"} • {new Date(run.createdAt).toLocaleString()}
                    </p>
                    <div className="button-row">
                      <Button variant="secondary" onClick={() => applySavedRun(run)}>
                        Reapply build
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </>
      ) : null}

      <section className="grid grid-2">
        <Card
          title={activeMeta.title}
          subtitle={activeMeta.subtitle}
          actions={<Badge tone="accent">{activeMeta.eyebrow}</Badge>}
        >
          <div className="item">
            <strong>When to use this mode</strong>
            <ul className="muted" style={{ marginBottom: 0 }}>
              {activeMeta.bullets.map((bullet) => (
                <li key={bullet} style={{ marginBottom: "0.4rem" }}>
                  {bullet}
                </li>
              ))}
            </ul>
          </div>

          {error ? <div className="error">{error}</div> : null}
          {success ? <div className="success">{success}</div> : null}

          {mode === "build" && presetBanner ? (
            <div className="preset-applied-banner">
              <strong>Preset loaded</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {presetBanner}
              </p>
            </div>
          ) : null}

          {mode === "build" && activePreset && buildFlowStage === "preset-review" ? (
            <div className="preset-review-panel">
              <div className="item">
                <strong>{activePreset.preset.name}</strong>
                <p className="muted" style={{ marginTop: "0.35rem", marginBottom: 0 }}>
                  {activePreset.preset.description || "This preset has been applied to the builder."}
                </p>
              </div>

              <div className="item">
                <strong>Applied signals</strong>
                {activePresetChips.length === 0 ? (
                  <p className="muted" style={{ marginBottom: 0 }}>
                    This preset applied the current builder defaults.
                  </p>
                ) : (
                  <div className="preset-chip-row" style={{ marginTop: "0.75rem" }}>
                    {activePresetChips.map((chip) => (
                      <span key={`active-${chip}`} className="preset-chip">
                        {chip}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              <div className="item">
                <strong>Next step</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  You can generate recommendations immediately, or move into the builder to edit the applied values first.
                </p>
              </div>

              <div className="button-row">
                <Button variant="secondary" onClick={continueToCustomize} disabled={loading}>
                  Review and customize
                </Button>
                <Button onClick={generateFromAppliedPreset} disabled={loading}>
                  {loading ? "Generating..." : "Generate from preset"}
                </Button>
                <Button variant="ghost" onClick={resetBuildForm} disabled={loading}>
                  Clear preset
                </Button>
              </div>
            </div>
          ) : null}

          {mode === "build" && (buildFlowStage === "builder" || !activePreset) ? (
            <form className="form" onSubmit={handleBuildSubmit}>
              <div className="build-night-layout">
                <BlockSection
                  title="Pick the kind of night"
                  subtitle="Choose the primary intent first."
                  options={outingOptions}
                  selectedValue={buildForm.outing_type}
                  onSelect={(value) => selectSingle("outing_type", value)}
                />

                <BlockSection
                  title="Choose your budget"
                  subtitle="Match the spend level you actually want."
                  options={budgetOptions}
                  selectedValue={buildForm.budget}
                  onSelect={(value) => selectSingle("budget", value)}
                />

                <BlockSection
                  title="Set the pace"
                  subtitle="Control how fast or relaxed the outing should feel."
                  options={paceOptions}
                  selectedValue={buildForm.pace}
                  onSelect={(value) => selectSingle("pace", value)}
                />

                <BlockSection
                  title="Who is this for"
                  subtitle="Tell the engine the social setup."
                  options={socialOptions}
                  selectedValue={buildForm.social_context}
                  onSelect={(value) => selectSingle("social_context", value)}
                />

                <MultiBlockSection
                  title="Pick food and drink interests"
                  subtitle="Select as many cuisine or drink signals as you want."
                  options={cuisineOptions}
                  selectedValues={buildForm.preferred_cuisines}
                  onToggle={(value) => toggleMulti("preferred_cuisines", value)}
                />

                <MultiBlockSection
                  title="Choose the atmosphere"
                  subtitle="These values directly influence the scorer."
                  options={atmosphereOptions}
                  selectedValues={buildForm.atmosphere}
                  onToggle={(value) => toggleMulti("atmosphere", value)}
                />

                <div className="build-section">
                  <div className="build-section__copy">
                    <strong>Should drinks matter</strong>
                    <p className="muted">Toggle whether the engine should actively prefer drink-friendly venues.</p>
                  </div>
                  <div className="build-block-grid build-block-grid--compact">
                    {yesNoOptions.map((option) => {
                      const active = buildForm.drinks_focus === (option.value === "yes");
                      return (
                        <button
                          key={option.value}
                          type="button"
                          className={active ? "build-block active" : "build-block"}
                          onClick={() =>
                            setBuildForm((prev) => ({
                              ...prev,
                              drinks_focus: option.value === "yes"
                            }))
                          }
                        >
                          <span className="build-block__label">{option.label}</span>
                          {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>

              <div className="build-summary">
                <strong>Current build</strong>
                <div className="build-summary__chips">
                  {buildSummary.map((value) => (
                    <span key={value} className="build-summary__chip">
                      {value}
                    </span>
                  ))}
                </div>
              </div>

              <div className="button-row">
                <Button type="button" variant="secondary" onClick={resetBuildForm} disabled={loading}>
                  Reset selections
                </Button>
                <Button type="submit" disabled={loading}>
                  {loading ? "Generating..." : "Generate recommendations"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "describe" ? (
            <form className="form" onSubmit={handleDescribeSubmit}>
              <div className="form-row">
                <label htmlFor="describe_prompt">Describe the night you want</label>
                <textarea
                  id="describe_prompt"
                  value={describeText}
                  onChange={(e) => setDescribeText(e.target.value)}
                  placeholder="I want a cozy dinner spot with good drinks, relaxed pacing, and food that feels memorable without being too formal..."
                />
              </div>

              <div className="button-row">
                <Button type="submit" disabled={loading || describeText.trim().length < 3}>
                  {loading ? "Interpreting..." : "Interpret and recommend"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "surprise" ? (
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
        </Card>

        <Card
          title="Recommendation output"
          subtitle="Curated results from the active mode"
          actions={
            normalizedResults.length > 0 ? (
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                <Badge tone="success">
                  {normalizedResults.length} result{normalizedResults.length === 1 ? "" : "s"}
                </Badge>
                {lastResponse?.engine_version ? <Badge tone="accent">{lastResponse.engine_version}</Badge> : null}
              </div>
            ) : (
              <Badge>Waiting</Badge>
            )
          }
        >
          {lastResponse?.generated_at ? (
            <div className="item" style={{ marginBottom: "0.9rem" }}>
              <strong>Last run metadata</strong>
              <p className="muted" style={{ margin: "0.35rem 0 0" }}>
                Generated: {new Date(lastResponse.generated_at).toLocaleString()}
              </p>
              {lastResponse.request_summary ? (
                <p className="muted" style={{ margin: "0.2rem 0 0" }}>
                  Request: {lastResponse.request_summary.outing_type || "n/a"}
                  {lastResponse.request_summary.budget ? ` • ${lastResponse.request_summary.budget}` : ""}
                  {lastResponse.request_summary.pace ? ` • ${lastResponse.request_summary.pace}` : ""}
                  {lastResponse.request_summary.social_context ? ` • ${lastResponse.request_summary.social_context}` : ""}
                </p>
              ) : null}
            </div>
          ) : null}

          {normalizedResults.length === 0 ? (
            <div className="list">
              <div className="item">
                <strong>No recommendations yet</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Run one of the recommendation modes to populate this panel with
                  curated dining suggestions.
                </p>
              </div>

              <div className="item">
                <strong>Best next move</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Apply a preset, review what it changed, customize if needed, then generate results.
                </p>
              </div>
            </div>
          ) : (
            <div className="list">
              {normalizedResults.map((item) => (
                <RecommendationCard
                  key={item.id}
                  title={item.title}
                  restaurantName={item.restaurantName}
                  rank={item.rank}
                  fitLabel={item.fitLabel}
                  score={item.score}
                  explanation={item.explanation}
                  confidenceLevel={item.confidenceLevel}
                  matchedSignals={item.matchedSignals}
                  penalizedSignals={item.penalizedSignals}
                  scoreBreakdown={item.scoreBreakdown}
                  tags={item.tags}
                />
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
EOF

cat > "$PROFILE_PAGE" <<'EOF'
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingState } from "../types";

type PresetSelectionPayload = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus?: boolean | null;
  atmosphere: string[];
};

type PresetResponse = {
  preset_id: string;
  owner_type: "system" | "user" | string;
  is_editable: boolean;
  name: string;
  description?: string | null;
  selection_payload: PresetSelectionPayload;
  created_at?: string | null;
  updated_at?: string | null;
};

function formatLabel(value: string) {
  return value
    .replace(/[_-]/g, " ")
    .split(" ")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function renderBadges(values: string[], tone: "default" | "accent" | "success" = "default") {
  if (values.length === 0) {
    return <p className="muted" style={{ marginBottom: 0 }}>Nothing saved yet.</p>;
  }

  return (
    <div>
      {values.map((value) => (
        <Badge key={value} tone={tone}>
          {formatLabel(value)}
        </Badge>
      ))}
    </div>
  );
}

function summarizePreset(preset: PresetResponse): string[] {
  const chips: string[] = [];
  if (preset.selection_payload.outing_type) chips.push(formatLabel(preset.selection_payload.outing_type));
  if (preset.selection_payload.budget) chips.push(preset.selection_payload.budget);
  if (preset.selection_payload.pace) chips.push(formatLabel(preset.selection_payload.pace));
  if (preset.selection_payload.social_context) chips.push(formatLabel(preset.selection_payload.social_context));
  preset.selection_payload.preferred_cuisines.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  return chips;
}

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [presetLoading, setPresetLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadProfile() {
      try {
        setError("");
        setLoading(true);
        const state = await apiRequest<OnboardingState>("/onboarding");
        if (!cancelled) {
          setProfileState(state);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your SAVR profile.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadProfile();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadPresets() {
      try {
        setPresetLoading(true);
        const data = await apiRequest<PresetResponse[]>("/presets");
        if (!cancelled) {
          setPresets(Array.isArray(data) ? data : []);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your presets.");
        }
      } finally {
        if (!cancelled) {
          setPresetLoading(false);
        }
      }
    }

    void loadPresets();

    return () => {
      cancelled = true;
    };
  }, []);

  const userPresets = useMemo(
    () => presets.filter((preset) => preset.owner_type === "user"),
    [presets]
  );

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile</p>
        <h1 className="page-title">Your SAVR profile</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page is your dedicated profile overview. Review what SAVR knows about your tastes,
          your saved reusable presets, and the quickest places to update those signals.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Account summary"
          subtitle="Your saved user identity and current profile readiness"
          actions={<Badge tone="accent">Account</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Name</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user ? `${user.first_name} ${user.last_name}`.trim() : "Guest user"}
              </p>
            </div>

            <div className="item">
              <strong>Email</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user?.email || "No email available"}
              </p>
            </div>

            <div className="item">
              <strong>Profile status</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user?.onboarding_completed ? "Ready" : "Incomplete"}
              </p>
            </div>

            <div className="button-row">
              <Link to="/profile/preferences">
                <Button>Edit profile</Button>
              </Link>
              <Link to="/recommendations">
                <Button variant="secondary">Manage presets</Button>
              </Link>
              <Link to="/dashboard">
                <Button variant="ghost">Back to dashboard</Button>
              </Link>
            </div>
          </div>
        </Card>

        <Card
          title="Preference overview"
          subtitle="A structured summary of the signals currently shaping your recommendations"
          actions={<Badge tone="success">Profile data</Badge>}
        >
          {loading ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your saved profile...</p>
          ) : !profileState ? (
            <div className="item">
              <strong>No profile data available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You can continue to the preference editor to create or update your profile.
              </p>
            </div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>Cuisine preferences</strong>
                {renderBadges(profileState.cuisine_preferences)}
              </div>

              <div className="item">
                <strong>Atmosphere preferences</strong>
                {renderBadges(profileState.atmosphere_preferences, "accent")}
              </div>

              <div className="item">
                <strong>Drink preferences</strong>
                {renderBadges(profileState.drink_preferences, "success")}
              </div>

              <div className="item">
                <strong>Favorite restaurants</strong>
                {renderBadges(profileState.favorite_restaurants)}
              </div>

              <div className="item">
                <strong>Dining note</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {profileState.bio?.trim() || "No dining note saved yet."}
                </p>
              </div>
            </div>
          )}
        </Card>
      </section>

      <section className="grid">
        <Card
          title="Your saved presets"
          subtitle="Reusable personal builders saved only to your account"
          actions={<Badge tone="accent">{presetLoading ? "Loading" : `${userPresets.length} saved`}</Badge>}
        >
          {presetLoading ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your presets...</p>
          ) : userPresets.length === 0 ? (
            <div className="item">
              <strong>No custom presets saved yet</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Go to recommendations, configure the builder, and save that configuration as a reusable preset.
              </p>
              <div className="button-row" style={{ marginTop: "0.9rem" }}>
                <Link to="/recommendations">
                  <Button>Open recommendations</Button>
                </Link>
              </div>
            </div>
          ) : (
            <div className="preset-library-grid">
              {userPresets.map((preset) => (
                <div key={preset.preset_id} className="preset-card">
                  <div className="preset-card__header">
                    <strong>{preset.name}</strong>
                    <Badge tone="success">Your preset</Badge>
                  </div>
                  <p className="muted" style={{ margin: 0 }}>
                    {preset.description || "No description saved for this preset."}
                  </p>
                  <div className="preset-chip-row">
                    {summarizePreset(preset).map((chip) => (
                      <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                        {chip}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
EOF

cat > "$ONBOARDING_PAGE" <<'EOF'
import { useEffect, useMemo, useState } from "react";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import {
  OnboardingPayload,
  OnboardingResponse,
  OnboardingState,
  RestaurantListItem
} from "../types";

type OnboardingOptionValue = {
  value: string;
  label: string;
  description?: string | null;
};

type OnboardingFieldDefinition = {
  key: string;
  label: string;
  description: string;
  help_text?: string | null;
  select_mode: "single" | "multi" | "range" | string;
  optional: boolean;
  allow_skip: boolean;
  ui_control: string;
  step_order: number;
  options: OnboardingOptionValue[];
};

type OnboardingOptionsResponse = {
  version: string;
  fields: OnboardingFieldDefinition[];
};

type OnboardingFormState = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string;
  spice_tolerance: string;
  price_sensitivity: string;
  budget_min_per_person: string;
  budget_max_per_person: string;
  onboarding_version: string;
};

type ChoiceFieldKey =
  | "dietary_restrictions"
  | "cuisine_preferences"
  | "texture_preferences"
  | "dining_pace_preferences"
  | "social_preferences"
  | "drink_preferences"
  | "atmosphere_preferences"
  | "favorite_dining_experiences"
  | "favorite_restaurants";

type CustomStepDefinition = {
  key: "favorite_dining_experiences" | "favorite_restaurants" | "bio";
  label: string;
  description: string;
  help_text?: string;
  select_mode: "multi" | "text";
  optional: boolean;
  allow_skip: boolean;
  step_order: number;
};

type WizardStep = OnboardingFieldDefinition | CustomStepDefinition;

const emptyForm: OnboardingFormState = {
  dietary_restrictions: [],
  cuisine_preferences: [],
  texture_preferences: [],
  dining_pace_preferences: [],
  social_preferences: [],
  drink_preferences: [],
  atmosphere_preferences: [],
  favorite_dining_experiences: [],
  favorite_restaurants: [],
  bio: "",
  spice_tolerance: "",
  price_sensitivity: "",
  budget_min_per_person: "",
  budget_max_per_person: "",
  onboarding_version: ""
};

const fallbackOnboardingOptions: OnboardingOptionsResponse = {
  version: "guided-v1",
  fields: [
    {
      key: "cuisine_preferences",
      label: "Cuisine preferences",
      description: "Choose the food styles you most want SAVR to prioritize.",
      help_text: "Choose one or more. Pick the cuisines that really matter to you.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 1,
      options: [
        { value: "italian", label: "Italian" },
        { value: "mexican", label: "Mexican" },
        { value: "japanese", label: "Japanese" },
        { value: "korean", label: "Korean" },
        { value: "thai", label: "Thai" },
        { value: "indian", label: "Indian" },
        { value: "mediterranean", label: "Mediterranean" },
        { value: "comfort food", label: "Comfort food" },
        { value: "seafood", label: "Seafood" },
        { value: "brunch", label: "Brunch" },
        { value: "dessert", label: "Dessert" },
        { value: "fast food", label: "Fast food" }
      ]
    },
    {
      key: "atmosphere_preferences",
      label: "Atmosphere preferences",
      description: "Choose the kinds of spaces you naturally enjoy.",
      help_text: "Choose one or more. These describe the vibe, not the food.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 2,
      options: [
        { value: "cozy", label: "Cozy" },
        { value: "romantic", label: "Romantic" },
        { value: "upscale", label: "Upscale" },
        { value: "lively", label: "Lively" },
        { value: "quiet", label: "Quiet" },
        { value: "casual", label: "Casual" },
        { value: "scenic", label: "Scenic" },
        { value: "family friendly", label: "Family friendly" },
        {
          value: "live music",
          label: "Live music",
          description: "Useful when performances matter to the outing."
        },
        {
          value: "trivia",
          label: "Trivia night",
          description: "Useful when recurring trivia events matter to the outing."
        }
      ]
    },
    {
      key: "dining_pace_preferences",
      label: "Dining pace",
      description: "Choose whether you usually want a quick stop, balanced meal, or slower experience.",
      help_text: "Choose one or more. This helps separate quick bites from slower sit-down meals.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 3,
      options: [
        { value: "quick", label: "Quick bite" },
        { value: "steady", label: "Balanced pace" },
        { value: "slow", label: "Slow experience" }
      ]
    },
    {
      key: "social_preferences",
      label: "Who you usually dine with",
      description: "This helps rank better for solo meals, dates, families, and group outings.",
      help_text: "Choose one or more. Select the social contexts that matter most often.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 4,
      options: [
        { value: "solo", label: "Solo" },
        { value: "date", label: "Date night" },
        { value: "friends", label: "Friends / group outing" },
        { value: "family", label: "Family" },
        { value: "students", label: "Students / budget-conscious" }
      ]
    },
    {
      key: "drink_preferences",
      label: "Drink preferences",
      description: "Choose drink categories that matter during recommendations.",
      help_text: "Choose one or more.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 5,
      options: [
        { value: "coffee", label: "Coffee" },
        { value: "mocktails", label: "Mocktails" },
        { value: "cocktails", label: "Cocktails" },
        { value: "wine", label: "Wine" },
        { value: "beer", label: "Beer" }
      ]
    },
    {
      key: "dietary_restrictions",
      label: "Dietary restrictions",
      description: "Only choose restrictions that should actively filter recommendations.",
      help_text: "Optional. Leave this empty if you have no dietary restrictions.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 6,
      options: [
        { value: "vegetarian", label: "Vegetarian" },
        { value: "vegan", label: "Vegan" },
        { value: "gluten free", label: "Gluten free" },
        { value: "dairy free", label: "Dairy free" },
        { value: "halal", label: "Halal" },
        { value: "nut aware", label: "Nut aware" }
      ]
    },
    {
      key: "price_sensitivity",
      label: "Budget comfort",
      description: "Pick the overall budget feel that suits you most often.",
      help_text: "Choose one. This is your general price comfort level.",
      select_mode: "single",
      optional: true,
      allow_skip: true,
      ui_control: "radio",
      step_order: 7,
      options: [
        {
          value: "budget",
          label: "Budget-conscious",
          description: "Usually looking for lower-cost options."
        },
        {
          value: "balanced",
          label: "Balanced",
          description: "Comfortable with moderate prices."
        },
        {
          value: "premium",
          label: "Premium",
          description: "Comfortable paying more for the right experience."
        }
      ]
    },
    {
      key: "budget_range",
      label: "Numeric budget range",
      description: "Set your typical spend per person in dollars.",
      help_text: "Optional. Use numbers if you want more precision.",
      select_mode: "range",
      optional: true,
      allow_skip: true,
      ui_control: "range",
      step_order: 8,
      options: []
    }
  ]
};

const favoriteExperienceOptions = [
  "brunch catch-up",
  "quick student bite",
  "date night dinner",
  "live music night",
  "trivia night",
  "coffee catch-up",
  "family dinner",
  "late-night comfort food",
  "patio evening",
  "celebration dinner"
];

function formatLabel(value: string) {
  return value
    .split(/[-_]/g)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function formatCountLabel(step: WizardStep): string {
  if (step.select_mode === "single") {
    return "Choose one";
  }

  if (step.select_mode === "multi") {
    return "Choose one or more";
  }

  if (step.select_mode === "range") {
    return "Optional numeric range";
  }

  return step.optional ? "Optional" : "Required";
}

function toFormState(source: OnboardingState | null | undefined): OnboardingFormState {
  return {
    dietary_restrictions: [...(source?.dietary_restrictions ?? [])],
    cuisine_preferences: [...(source?.cuisine_preferences ?? [])],
    texture_preferences: [...(source?.texture_preferences ?? [])],
    dining_pace_preferences: [...(source?.dining_pace_preferences ?? [])],
    social_preferences: [...(source?.social_preferences ?? [])],
    drink_preferences: [...(source?.drink_preferences ?? [])],
    atmosphere_preferences: [...(source?.atmosphere_preferences ?? [])],
    favorite_dining_experiences: [...(source?.favorite_dining_experiences ?? [])],
    favorite_restaurants: [...(source?.favorite_restaurants ?? [])],
    bio: source?.bio ?? "",
    spice_tolerance: source?.spice_tolerance ?? "",
    price_sensitivity: source?.price_sensitivity ?? "",
    budget_min_per_person:
      typeof (source as OnboardingState & { budget_min_per_person?: number | null })?.budget_min_per_person === "number"
        ? String((source as OnboardingState & { budget_min_per_person?: number | null }).budget_min_per_person)
        : "",
    budget_max_per_person:
      typeof (source as OnboardingState & { budget_max_per_person?: number | null })?.budget_max_per_person === "number"
        ? String((source as OnboardingState & { budget_max_per_person?: number | null }).budget_max_per_person)
        : "",
    onboarding_version:
      (source as OnboardingState & { onboarding_version?: string | null })?.onboarding_version || ""
  };
}

function cloneFormState(source: OnboardingFormState): OnboardingFormState {
  return {
    ...source,
    dietary_restrictions: [...source.dietary_restrictions],
    cuisine_preferences: [...source.cuisine_preferences],
    texture_preferences: [...source.texture_preferences],
    dining_pace_preferences: [...source.dining_pace_preferences],
    social_preferences: [...source.social_preferences],
    drink_preferences: [...source.drink_preferences],
    atmosphere_preferences: [...source.atmosphere_preferences],
    favorite_dining_experiences: [...source.favorite_dining_experiences],
    favorite_restaurants: [...source.favorite_restaurants]
  };
}

function parseNumberOrNull(value: string): number | null {
  if (!value.trim()) {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function buildSummaryText(step: WizardStep, form: OnboardingFormState): string {
  switch (step.key) {
    case "budget_range": {
      const min = form.budget_min_per_person.trim();
      const max = form.budget_max_per_person.trim();

      if (!min && !max) {
        return "No numeric budget set yet.";
      }

      if (min && max) {
        return `$${min} - $${max} per person`;
      }

      if (min) {
        return `From $${min} per person`;
      }

      return `Up to $${max} per person`;
    }
    case "price_sensitivity":
      return form.price_sensitivity ? formatLabel(form.price_sensitivity) : "Nothing selected yet.";
    case "bio":
      return form.bio.trim() ? "Dining note added." : "No note added yet.";
    case "favorite_dining_experiences":
      return form.favorite_dining_experiences.length > 0
        ? `${form.favorite_dining_experiences.length} experience preferences selected.`
        : "No favorite experience styles selected yet.";
    case "favorite_restaurants":
      return form.favorite_restaurants.length > 0
        ? `${form.favorite_restaurants.length} favorite restaurants selected.`
        : "No favorite restaurants selected yet.";
    default: {
      const values = form[step.key as keyof OnboardingFormState];
      if (Array.isArray(values)) {
        return values.length > 0
          ? `${values.length} selected.`
          : "Nothing selected yet.";
      }
      return "Nothing selected yet.";
    }
  }
}

function StepChoiceCard({
  active,
  label,
  description,
  onClick
}: {
  active: boolean;
  label: string;
  description?: string | null;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      className={active ? "wizard-choice-card wizard-choice-card--active" : "wizard-choice-card"}
      onClick={onClick}
      aria-pressed={active}
    >
      <span className="wizard-choice-card__label">{label}</span>
      {description ? <span className="wizard-choice-card__description">{description}</span> : null}
      <span className="wizard-choice-card__state">
        {active ? "Selected" : "Tap to select"}
      </span>
    </button>
  );
}

function ReviewGroup({
  title,
  values,
  emptyText
}: {
  title: string;
  values: string[];
  emptyText: string;
}) {
  return (
    <div className="wizard-review-group">
      <strong>{title}</strong>
      {values.length === 0 ? (
        <p className="muted" style={{ marginBottom: 0 }}>{emptyText}</p>
      ) : (
        <div className="wizard-review-chip-row">
          {values.map((value) => (
            <span key={value} className="wizard-review-chip">
              {formatLabel(value)}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

export default function OnboardingPage() {
  const { refreshUser } = useAuth();

  const [form, setForm] = useState<OnboardingFormState>(emptyForm);
  const [savedState, setSavedState] = useState<OnboardingFormState>(emptyForm);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [isHydrating, setIsHydrating] = useState(true);
  const [optionsResponse, setOptionsResponse] = useState<OnboardingOptionsResponse>(fallbackOnboardingOptions);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);

  useEffect(() => {
    let cancelled = false;

    async function hydrate() {
      try {
        setError("");

        const [restaurants, onboardingState, onboardingOptions] = await Promise.all([
          apiRequest<RestaurantListItem[]>("/restaurants"),
          apiRequest<OnboardingState>("/onboarding"),
          apiRequest<OnboardingOptionsResponse>("/onboarding/options")
        ]);

        if (cancelled) {
          return;
        }

        const restaurantNames = restaurants.map((restaurant) => restaurant.name);
        const nextForm = toFormState(onboardingState);

        setRestaurantOptions(restaurantNames);
        setSavedState(cloneFormState(nextForm));
        setForm(nextForm);
        setOptionsResponse(onboardingOptions);
      } catch (err) {
        if (!cancelled) {
          setRestaurantOptions([]);
          setOptionsResponse(fallbackOnboardingOptions);
          setError(
            err instanceof Error
              ? err.message
              : "We could not load your saved profile right now."
          );
        }
      } finally {
        if (!cancelled) {
          setIsHydrating(false);
        }
      }
    }

    void hydrate();

    return () => {
      cancelled = true;
    };
  }, []);

  const wizardSteps = useMemo<WizardStep[]>(() => {
    const backendSteps = [...optionsResponse.fields].sort((a, b) => a.step_order - b.step_order);

    const customSteps: CustomStepDefinition[] = [
      {
        key: "favorite_dining_experiences",
        label: "Favorite experience types",
        description: "Choose the dining moments you want SAVR to remember and prioritize.",
        help_text: "Choose one or more.",
        select_mode: "multi",
        optional: true,
        allow_skip: true,
        step_order: 90
      },
      {
        key: "favorite_restaurants",
        label: "Favorite restaurants",
        description: "Mark the places you already know you like.",
        help_text: "Optional. This helps SAVR learn your existing taste baseline.",
        select_mode: "multi",
        optional: true,
        allow_skip: true,
        step_order: 91
      },
      {
        key: "bio",
        label: "A short note about your ideal dining style",
        description: "Add a short note so SAVR understands your preferences in plain language too.",
        help_text: "Optional. Keep it short and practical.",
        select_mode: "text",
        optional: true,
        allow_skip: true,
        step_order: 92
      }
    ];

    return [...backendSteps, ...customSteps];
  }, [optionsResponse]);

  const totalScreens = wizardSteps.length + 1;
  const currentStep = wizardSteps[currentStepIndex];
  const isReviewStep = currentStepIndex >= wizardSteps.length;
  const progressPercent = Math.max(8, Math.round(((currentStepIndex + 1) / totalScreens) * 100));

  const completionStats = useMemo(
    () => [
      { label: "Cuisine", value: form.cuisine_preferences.length },
      { label: "Atmosphere", value: form.atmosphere_preferences.length },
      { label: "Drinks", value: form.drink_preferences.length },
      { label: "Favorites", value: form.favorite_restaurants.length }
    ],
    [form]
  );

  function toggleArrayField(field: ChoiceFieldKey, value: string) {
    setForm((current) => {
      const existing = current[field];
      const next = existing.includes(value)
        ? existing.filter((item) => item !== value)
        : [...existing, value];

      return {
        ...current,
        [field]: next
      };
    });
  }

  function setSingleField(field: "price_sensitivity", value: string) {
    setForm((current) => ({
      ...current,
      [field]: current[field] === value ? "" : value
    }));
  }

  function resetToSavedState() {
    const restored = cloneFormState(savedState);
    setForm(restored);
    setCurrentStepIndex(0);
    setMessage("Your onboarding form has been reset to the last saved version.");
    setError("");
  }

  function goNext() {
    setCurrentStepIndex((current) => Math.min(current + 1, wizardSteps.length));
  }

  function goBack() {
    setCurrentStepIndex((current) => Math.max(current - 1, 0));
  }

  async function handleSubmit() {
    setError("");
    setMessage("");
    setIsSubmitting(true);

    const payload = {
      dietary_restrictions: form.dietary_restrictions,
      cuisine_preferences: form.cuisine_preferences,
      texture_preferences: form.texture_preferences,
      dining_pace_preferences: form.dining_pace_preferences,
      social_preferences: form.social_preferences,
      drink_preferences: form.drink_preferences,
      atmosphere_preferences: form.atmosphere_preferences,
      favorite_dining_experiences: form.favorite_dining_experiences,
      favorite_restaurants: form.favorite_restaurants,
      bio: form.bio.trim() || null,
      spice_tolerance: form.spice_tolerance || null,
      price_sensitivity: form.price_sensitivity || null,
      budget_min_per_person: parseNumberOrNull(form.budget_min_per_person),
      budget_max_per_person: parseNumberOrNull(form.budget_max_per_person),
      onboarding_version: optionsResponse.version || "guided-v1"
    } as OnboardingPayload & {
      budget_min_per_person?: number | null;
      budget_max_per_person?: number | null;
      onboarding_version?: string | null;
    };

    try {
      const response = await apiRequest<OnboardingResponse>("/onboarding", {
        method: "POST",
        body: payload
      });

      const persisted = await apiRequest<OnboardingState>("/onboarding");
      const persistedForm = toFormState(persisted);

      setSavedState(cloneFormState(persistedForm));
      setForm(persistedForm);

      await refreshUser();
      setMessage(response.message || "Your SAVR profile has been updated.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "We could not save your profile.");
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isHydrating) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading your SAVR profile...</div>
      </div>
    );
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">SAVR profile</p>
        <h1 className="page-title">Build your taste profile step by step</h1>
        <p className="muted" style={{ maxWidth: "820px", marginBottom: 0 }}>
          One clear decision at a time. You can go back, skip optional steps, and
          nothing you choose here is lost as you move through the flow.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2 onboarding-grid">
        <Card
          title={
            isReviewStep
              ? "Review your SAVR profile"
              : currentStep.label
          }
          subtitle={
            isReviewStep
              ? "Check the signals SAVR will use, then save when everything looks right."
              : currentStep.description
          }
          actions={
            <Badge tone="accent">
              Step {Math.min(currentStepIndex + 1, totalScreens)} / {totalScreens}
            </Badge>
          }
        >
          <div className="wizard-progress-shell" aria-label="Onboarding progress">
            <div className="wizard-progress-meta">
              <span>{isReviewStep ? "Review and save" : "Guided onboarding"}</span>
              <strong>{progressPercent}%</strong>
            </div>
            <div className="wizard-progress-track" aria-hidden="true">
              <div className="wizard-progress-fill" style={{ width: `${progressPercent}%` }} />
            </div>
          </div>

          {!isReviewStep ? (
            <div className="wizard-step-hero wizard-step-hero--animated">
              <div className="wizard-step-badges">
                <span className="wizard-step-badge">{formatCountLabel(currentStep)}</span>
                {currentStep.optional ? (
                  <span className="wizard-step-badge wizard-step-badge--soft">Optional</span>
                ) : null}
              </div>

              {currentStep.help_text ? (
                <p className="muted wizard-step-help">{currentStep.help_text}</p>
              ) : null}

              {currentStep.key === "price_sensitivity" ? (
                <div className="wizard-choice-grid">
                  {currentStep.options.map((option) => {
                    const active = form.price_sensitivity === option.value;
                    return (
                      <StepChoiceCard
                        key={option.value}
                        active={active}
                        label={option.label}
                        description={option.description}
                        onClick={() => setSingleField("price_sensitivity", option.value)}
                      />
                    );
                  })}
                </div>
              ) : null}

              {currentStep.key === "budget_range" ? (
                <div className="wizard-range-grid">
                  <div className="form-row">
                    <label htmlFor="budget_min_per_person">Minimum per person</label>
                    <input
                      id="budget_min_per_person"
                      type="number"
                      min="0"
                      step="1"
                      inputMode="numeric"
                      value={form.budget_min_per_person}
                      placeholder="e.g. 15"
                      onChange={(e) =>
                        setForm((current) => ({
                          ...current,
                          budget_min_per_person: e.target.value
                        }))
                      }
                    />
                    <small className="muted">Leave blank if you do not want to set a minimum.</small>
                  </div>

                  <div className="form-row">
                    <label htmlFor="budget_max_per_person">Maximum per person</label>
                    <input
                      id="budget_max_per_person"
                      type="number"
                      min="0"
                      step="1"
                      inputMode="numeric"
                      value={form.budget_max_per_person}
                      placeholder="e.g. 40"
                      onChange={(e) =>
                        setForm((current) => ({
                          ...current,
                          budget_max_per_person: e.target.value
                        }))
                      }
                    />
                    <small className="muted">Use real dollar values instead of icons only.</small>
                  </div>
                </div>
              ) : null}

              {currentStep.key === "favorite_dining_experiences" ? (
                <div className="wizard-choice-grid">
                  {favoriteExperienceOptions.map((option) => (
                    <StepChoiceCard
                      key={option}
                      active={form.favorite_dining_experiences.includes(option)}
                      label={formatLabel(option)}
                      onClick={() => toggleArrayField("favorite_dining_experiences", option)}
                    />
                  ))}
                </div>
              ) : null}

              {currentStep.key === "favorite_restaurants" ? (
                <div className="wizard-choice-grid">
                  {restaurantOptions.length > 0 ? (
                    restaurantOptions.map((option) => (
                      <StepChoiceCard
                        key={option}
                        active={form.favorite_restaurants.includes(option)}
                        label={option}
                        onClick={() => toggleArrayField("favorite_restaurants", option)}
                      />
                    ))
                  ) : (
                    <div className="item">
                      <strong>No restaurants available yet</strong>
                      <p className="muted" style={{ marginBottom: 0 }}>
                        You can skip this step and still finish onboarding.
                      </p>
                    </div>
                  )}
                </div>
              ) : null}

              {currentStep.key === "bio" ? (
                <div className="form-row">
                  <label htmlFor="bio">Dining note</label>
                  <textarea
                    id="bio"
                    rows={5}
                    value={form.bio}
                    placeholder="Example: I usually want cozy places with a strong main dish, easy conversation, and a price that still feels reasonable for students."
                    onChange={(e) =>
                      setForm((current) => ({
                        ...current,
                        bio: e.target.value
                      }))
                    }
                  />
                  <small className="muted">
                    This is optional, but it helps SAVR understand your preferences in normal language.
                  </small>
                </div>
              ) : null}

              {[
                "dietary_restrictions",
                "cuisine_preferences",
                "texture_preferences",
                "dining_pace_preferences",
                "social_preferences",
                "drink_preferences",
                "atmosphere_preferences"
              ].includes(currentStep.key) ? (
                <div className="wizard-choice-grid">
                  {(currentStep as OnboardingFieldDefinition).options.map((option) => {
                    const values = form[currentStep.key as ChoiceFieldKey];
                    const active = values.includes(option.value);
                    return (
                      <StepChoiceCard
                        key={option.value}
                        active={active}
                        label={option.label}
                        description={option.description}
                        onClick={() => toggleArrayField(currentStep.key as ChoiceFieldKey, option.value)}
                      />
                    );
                  })}
                </div>
              ) : null}

              <div className="wizard-inline-summary">
                <strong>Current step summary</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {buildSummaryText(currentStep, form)}
                </p>
              </div>
            </div>
          ) : (
            <div className="wizard-step-hero wizard-step-hero--animated">
              <div className="wizard-review-grid">
                <ReviewGroup
                  title="Cuisine preferences"
                  values={form.cuisine_preferences}
                  emptyText="No cuisine preferences saved."
                />
                <ReviewGroup
                  title="Atmosphere preferences"
                  values={form.atmosphere_preferences}
                  emptyText="No atmosphere preferences saved."
                />
                <ReviewGroup
                  title="Dining pace"
                  values={form.dining_pace_preferences}
                  emptyText="No pace preferences saved."
                />
                <ReviewGroup
                  title="Social preferences"
                  values={form.social_preferences}
                  emptyText="No social preferences saved."
                />
                <ReviewGroup
                  title="Drink preferences"
                  values={form.drink_preferences}
                  emptyText="No drink preferences saved."
                />
                <ReviewGroup
                  title="Dietary restrictions"
                  values={form.dietary_restrictions}
                  emptyText="No dietary restrictions saved."
                />
                <ReviewGroup
                  title="Favorite experience types"
                  values={form.favorite_dining_experiences}
                  emptyText="No favorite experience types saved."
                />
                <ReviewGroup
                  title="Favorite restaurants"
                  values={form.favorite_restaurants}
                  emptyText="No favorite restaurants saved."
                />

                <div className="wizard-review-group">
                  <strong>Budget comfort</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {form.price_sensitivity ? formatLabel(form.price_sensitivity) : "No budget comfort selected."}
                  </p>
                </div>

                <div className="wizard-review-group">
                  <strong>Numeric budget range</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {buildSummaryText(
                      {
                        key: "budget_range",
                        label: "",
                        description: "",
                        help_text: "",
                        select_mode: "range",
                        optional: true,
                        allow_skip: true,
                        ui_control: "range",
                        step_order: 999,
                        options: []
                      },
                      form
                    )}
                  </p>
                </div>

                <div className="wizard-review-group wizard-review-group--full">
                  <strong>Dining note</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {form.bio.trim() || "No note added."}
                  </p>
                </div>
              </div>
            </div>
          )}

          <div className="wizard-actions">
            <Button
              type="button"
              variant="ghost"
              onClick={goBack}
              disabled={currentStepIndex === 0 || isSubmitting}
            >
              Back
            </Button>

            <div className="wizard-actions__right">
              {!isReviewStep && currentStep.optional ? (
                <Button
                  type="button"
                  variant="secondary"
                  onClick={goNext}
                  disabled={isSubmitting}
                >
                  Skip for now
                </Button>
              ) : null}

              {!isReviewStep ? (
                <Button type="button" onClick={goNext} disabled={isSubmitting}>
                  {currentStepIndex === wizardSteps.length - 1 ? "Review profile" : "Continue"}
                </Button>
              ) : (
                <Button type="button" onClick={handleSubmit} disabled={isSubmitting}>
                  {isSubmitting ? "Saving..." : "Save profile"}
                </Button>
              )}
            </div>
          </div>
        </Card>

        <div className="grid" style={{ gap: "1rem" }}>
          <Card
            title="Profile completeness"
            subtitle="A quick view of how much preference detail you have added"
            actions={<Badge tone="success">Summary</Badge>}
          >
            <div className="grid grid-2">
              {completionStats.map((stat) => (
                <div key={stat.label} className="item">
                  <p className="muted" style={{ marginBottom: "0.25rem" }}>
                    {stat.label}
                  </p>
                  <strong style={{ fontSize: "1.15rem" }}>{stat.value}</strong>
                </div>
              ))}
            </div>
          </Card>

          <Card
            title="How this onboarding works"
            subtitle="Clearer, lower-friction, and easier to understand"
            actions={<Badge>Guide</Badge>}
          >
            <div className="list">
              <div className="item">
                <strong>One major decision per screen</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Each step focuses on one topic so the flow feels lighter and easier to process.
                </p>
              </div>

              <div className="item">
                <strong>Clear selection rules</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Every step tells you whether it is optional and whether you can choose one or many options.
                </p>
              </div>

              <div className="item">
                <strong>Visible selection feedback</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Selected options are highlighted immediately and explicitly marked as selected.
                </p>
              </div>
            </div>
          </Card>

          <Card
            title="Quick actions"
            subtitle="Useful while testing the onboarding flow"
            actions={<Badge tone="accent">Tools</Badge>}
          >
            <div className="button-row">
              <Button type="button" variant="secondary" onClick={resetToSavedState}>
                Reset to saved
              </Button>
              <Button
                type="button"
                variant="ghost"
                onClick={() => setCurrentStepIndex(wizardSteps.length)}
              >
                Jump to review
              </Button>
            </div>
          </Card>
        </div>
      </section>
    </div>
  );
}
EOF

python3 - <<'PY'
from pathlib import Path

styles_path = Path("frontend/src/styles.css")
content = styles_path.read_text()

sections = []

if "/* PATCH3_PRESET_AND_ONBOARDING_START */" not in content:
    sections.append("""

/* PATCH3_PRESET_AND_ONBOARDING_START */
.preset-editor-panel {
  display: grid;
  gap: 1rem;
  margin-top: 1rem;
  padding: 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(15, 23, 42, 0.24);
}

.preset-editor-panel textarea,
.preset-editor-panel input {
  width: 100%;
}

.wizard-choice-card {
  appearance: none;
  text-align: left;
  display: grid;
  gap: 0.45rem;
  min-height: 132px;
  padding: 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.22);
  background: rgba(51, 65, 85, 0.82);
  color: #f8fafc;
  transition: transform 160ms ease, border-color 160ms ease, box-shadow 160ms ease, background 160ms ease;
}

.wizard-choice-card:hover {
  transform: translateY(-1px);
  border-color: rgba(224, 231, 255, 0.48);
  box-shadow: 0 10px 24px rgba(2, 6, 23, 0.24);
}

.wizard-choice-card:focus-visible {
  outline: 3px solid rgba(244, 196, 48, 0.35);
  outline-offset: 2px;
}

.wizard-choice-card--active {
  border-color: rgba(244, 196, 48, 0.78);
  background: linear-gradient(180deg, rgba(111, 117, 89, 0.38), rgba(51, 65, 85, 0.96));
  box-shadow: 0 12px 28px rgba(15, 23, 42, 0.28);
}

.wizard-choice-card__label {
  font-weight: 700;
  color: #ffffff;
}

.wizard-choice-card__description {
  color: rgba(226, 232, 240, 0.88);
  font-size: 0.92rem;
  line-height: 1.45;
}

.wizard-choice-card__state {
  display: inline-flex;
  align-items: center;
  justify-content: flex-start;
  width: fit-content;
  margin-top: auto;
  padding: 0.22rem 0.58rem;
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.18);
  background: rgba(15, 23, 42, 0.22);
  color: rgba(248, 250, 252, 0.92);
  font-size: 0.78rem;
  font-weight: 700;
}

.wizard-choice-card--active .wizard-choice-card__state {
  border-color: rgba(244, 196, 48, 0.68);
  background: rgba(244, 196, 48, 0.18);
  color: #fff7d1;
}

.wizard-inline-summary {
  padding: 0.95rem 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(15, 23, 42, 0.28);
}

.wizard-progress-track {
  width: 100%;
  height: 0.7rem;
  border-radius: 999px;
  background: rgba(51, 65, 85, 0.82);
  overflow: hidden;
  border: 1px solid rgba(148, 163, 184, 0.16);
}

.wizard-progress-fill {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(244, 196, 48, 0.95) 0%, rgba(111, 117, 89, 0.95) 100%);
  transition: width 220ms ease;
}

.wizard-step-badge,
.wizard-review-chip {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.4rem 0.75rem;
  font-size: 0.78rem;
  font-weight: 700;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(15, 23, 42, 0.34);
}

@media (prefers-reduced-motion: reduce) {
  .wizard-choice-card,
  .wizard-progress-fill {
    transition: none;
  }
}
/* PATCH3_PRESET_AND_ONBOARDING_END */
""")

if sections:
    styles_path.write_text(content + "".join(sections))
    print("Patch 3 styles appended.")
else:
    print("Patch 3 styles already present.")
PY

echo "Running frontend TypeScript verification..."
cd "$FRONTEND_DIR"
npx tsc --noEmit

echo "Patch 3 applied successfully."
echo "Modified files:"
echo " - frontend/src/pages/RecommendationsPage.tsx"
echo " - frontend/src/pages/ProfilePage.tsx"
echo " - frontend/src/pages/OnboardingPage.tsx"
echo " - frontend/src/styles.css"
