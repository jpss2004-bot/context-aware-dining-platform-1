#!/usr/bin/env bash
set -euo pipefail

PATCH_NAME="patch8_recommendation_flow_polish"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Starting ${PATCH_NAME}..."

if [[ -d "frontend/src" && -f "frontend/package.json" ]]; then
  FRONTEND_DIR="$(pwd)/frontend"
elif [[ -d "src" && -f "package.json" ]]; then
  FRONTEND_DIR="$(pwd)"
else
  echo "ERROR: Could not find frontend directory."
  echo "Run this script from the project root or from frontend."
  exit 1
fi

echo "Resolved frontend directory: ${FRONTEND_DIR}"
cd "${FRONTEND_DIR}"

mkdir -p "${BACKUP_DIR}"
echo "Creating backup at: ${FRONTEND_DIR}/${BACKUP_DIR}"

for path in \
  src/App.tsx \
  src/pages/RecommendationsPage.tsx \
  src/components/dining/RecommendationCard.tsx \
  src/components/navigation/Sidebar.tsx
do
  if [[ -f "$path" ]]; then
    cp "$path" "${BACKUP_DIR}/$(basename "$path").bak"
  fi
done

mkdir -p src/pages/recommendations
mkdir -p src/lib

cat > src/lib/recommendationFlow.ts <<'EOF'
import { apiRequest } from "./api";

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  rank?: number;
  fit_label?: string;
  reasons?: string[];
  explanation?: string | null;
  confidence_level?: string;
  matched_signals?: string[];
  penalized_signals?: string[];
  score_breakdown?: { label: string; points: number }[];
  suggested_dishes?: string[];
  suggested_drinks?: string[];
  active_event_matches?: string[];
};

export type RecommendationResponse = {
  mode: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: Record<string, unknown>;
  results: RecommendationItem[];
};

export type PresetSelectionPayload = {
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

export type PresetResponse = {
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

export type PresetApplyResponse = {
  preset: PresetResponse;
  builder_payload: PresetSelectionPayload;
  banner_message: string;
  can_customize: boolean;
};

export type StoredRecommendationResult = {
  mode: "build" | "describe" | "surprise";
  createdAt: string;
  request?: unknown;
  response: RecommendationResponse;
};

export const RESULT_STORAGE_KEY = "savr:recommendation-flow-result:v3";

export function saveRecommendationResult(result: StoredRecommendationResult) {
  sessionStorage.setItem(RESULT_STORAGE_KEY, JSON.stringify(result));
}

export function loadRecommendationResult(): StoredRecommendationResult | null {
  try {
    const raw = sessionStorage.getItem(RESULT_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as StoredRecommendationResult;
  } catch {
    return null;
  }
}

export function clearRecommendationResult() {
  sessionStorage.removeItem(RESULT_STORAGE_KEY);
}

export async function runBuildNight(body: {
  outing_type: string;
  budget?: string;
  pace?: string;
  social_context?: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
}) {
  return apiRequest<RecommendationResponse>("/recommendations/build-your-night", {
    method: "POST",
    body
  });
}

export async function runDescribeNight(body: { prompt: string }) {
  return apiRequest<RecommendationResponse>("/recommendations/describe-your-night", {
    method: "POST",
    body
  });
}

export async function runSurpriseMe(body: { include_drinks: boolean }) {
  return apiRequest<RecommendationResponse>("/recommendations/surprise-me", {
    method: "POST",
    body
  });
}

export async function listPresets() {
  return apiRequest<PresetResponse[]>("/presets");
}

export async function applyPreset(presetId: string) {
  return apiRequest<PresetApplyResponse>(`/presets/${presetId}/apply`, {
    method: "POST"
  });
}

export async function createPreset(body: {
  name: string;
  description?: string | null;
  selection_payload: PresetSelectionPayload;
}) {
  return apiRequest<PresetResponse>("/presets", {
    method: "POST",
    body
  });
}

export async function deletePreset(presetId: string) {
  return apiRequest<{ message: string; deleted_preset_id: string }>(`/presets/${presetId}`, {
    method: "DELETE"
  });
}

export function normalizeRecommendationScore(score: number, maxScore: number) {
  if (!Number.isFinite(score) || !Number.isFinite(maxScore) || maxScore <= 0) {
    return undefined;
  }
  const value = score / maxScore;
  return Math.max(0, Math.min(value, 1));
}
EOF

cat > src/pages/RecommendationsPage.tsx <<'EOF'
import { useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";

const options = [
  {
    key: "build",
    title: "Build Your Night",
    badge: "Step-by-step",
    description:
      "Choose your vibe, pacing, budget, and preferences in a guided page with preset support.",
    path: "/recommendations/build",
    cta: "Open build flow"
  },
  {
    key: "describe",
    title: "Describe the Night",
    badge: "Natural language",
    description:
      "Write what kind of night you want, then go straight to a separate results page.",
    path: "/recommendations/describe",
    cta: "Open describe flow"
  },
  {
    key: "surprise",
    title: "Surprise Me",
    badge: "Fast path",
    description:
      "Minimal input, less friction, and a dedicated results page with only the recommendations.",
    path: "/recommendations/surprise",
    cta: "Open surprise flow"
  }
] as const;

export default function RecommendationsPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendation hub</p>
        <h1 className="page-title">Choose how you want to generate your night</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Start from one clear option, move into its own focused page, and view the output on a dedicated results screen.
        </p>
      </section>

      <section className="grid grid-3">
        {options.map((option) => (
          <Card
            key={option.key}
            title={option.title}
            subtitle={option.description}
            actions={<Badge tone="accent">{option.badge}</Badge>}
          >
            <div className="button-row">
              <Button onClick={() => navigate(option.path)} fullWidth>
                {option.cta}
              </Button>
            </div>
          </Card>
        ))}
      </section>
    </div>
  );
}
EOF

cat > src/pages/recommendations/BuildNightPage.tsx <<'EOF'
import { FormEvent, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  applyPreset,
  createPreset,
  deletePreset,
  listPresets,
  type PresetResponse,
  type PresetSelectionPayload,
  runBuildNight,
  saveRecommendationResult
} from "../../lib/recommendationFlow";

type BuildFormState = {
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
};

const outingOptions = [
  "casual-bite",
  "date-night",
  "group-dinner",
  "drinks-night",
  "quick-bite",
  "coffee-stop",
  "special-occasion"
];

const budgetOptions = ["", "$", "$$", "$$$"];
const paceOptions = ["", "fast", "moderate", "slow", "leisurely"];
const socialOptions = ["", "solo", "friends", "group", "date"];

const cuisineOptions = [
  "pizza",
  "mediterranean",
  "asian",
  "bakery",
  "dessert",
  "fast food",
  "seasonal",
  "turkish",
  "coffee",
  "beer",
  "wine",
  "cider"
];

const atmosphereOptions = [
  "cozy",
  "lively",
  "quiet",
  "casual",
  "scenic",
  "historic",
  "refined",
  "upscale",
  "rustic"
];

const initialState: BuildFormState = {
  outing_type: "casual-bite",
  budget: "$$",
  pace: "moderate",
  social_context: "friends",
  preferred_cuisines: [],
  atmosphere: [],
  drinks_focus: false
};

function toggleArrayValue(values: string[], value: string) {
  return values.includes(value)
    ? values.filter((item) => item !== value)
    : [...values, value];
}

function toPresetPayload(form: BuildFormState): PresetSelectionPayload {
  return {
    outing_type: form.outing_type,
    budget: form.budget || null,
    pace: form.pace || null,
    social_context: form.social_context || null,
    preferred_cuisines: form.preferred_cuisines,
    drinks_focus: form.drinks_focus,
    atmosphere: form.atmosphere
  };
}

function fromPresetPayload(payload: PresetSelectionPayload): BuildFormState {
  return {
    outing_type: payload.outing_type || "casual-bite",
    budget: payload.budget || "",
    pace: payload.pace || "",
    social_context: payload.social_context || "",
    preferred_cuisines: Array.isArray(payload.preferred_cuisines) ? payload.preferred_cuisines : [],
    atmosphere: Array.isArray(payload.atmosphere) ? payload.atmosphere : [],
    drinks_focus: Boolean(payload.drinks_focus)
  };
}

export default function BuildNightPage() {
  const navigate = useNavigate();

  const [form, setForm] = useState<BuildFormState>(initialState);
  const [loading, setLoading] = useState(false);
  const [presetLoading, setPresetLoading] = useState(false);
  const [presetSaveLoading, setPresetSaveLoading] = useState(false);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [presetName, setPresetName] = useState("");
  const [presetDescription, setPresetDescription] = useState("");

  const userPresets = useMemo(
    () => presets.filter((preset) => preset.owner_type === "user"),
    [presets]
  );

  async function loadPresetLibrary() {
    try {
      const data = await listPresets();
      setPresets(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load presets.");
    }
  }

  useEffect(() => {
    void loadPresetLibrary();
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const response = await runBuildNight({
        outing_type: form.outing_type,
        budget: form.budget || undefined,
        pace: form.pace || undefined,
        social_context: form.social_context || undefined,
        preferred_cuisines: form.preferred_cuisines,
        atmosphere: form.atmosphere,
        drinks_focus: form.drinks_focus
      });

      saveRecommendationResult({
        mode: "build",
        createdAt: new Date().toISOString(),
        request: form,
        response
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate recommendations.");
    } finally {
      setLoading(false);
    }
  }

  async function handleApplyPreset(presetId: string) {
    setPresetLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = await applyPreset(presetId);
      setForm(fromPresetPayload(data.builder_payload));
      setSuccess(data.banner_message || "Preset applied successfully.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to apply preset.");
    } finally {
      setPresetLoading(false);
    }
  }

  async function handleSavePreset(event: FormEvent) {
    event.preventDefault();
    setPresetSaveLoading(true);
    setError("");
    setSuccess("");

    try {
      if (!presetName.trim()) {
        throw new Error("Preset name is required.");
      }

      await createPreset({
        name: presetName.trim(),
        description: presetDescription.trim() || null,
        selection_payload: toPresetPayload(form)
      });

      setPresetName("");
      setPresetDescription("");
      setSuccess("Preset saved successfully.");
      await loadPresetLibrary();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save preset.");
    } finally {
      setPresetSaveLoading(false);
    }
  }

  async function handleDeletePreset(preset: PresetResponse) {
    const confirmed = window.confirm(`Delete the preset "${preset.name}"?`);
    if (!confirmed) return;

    setError("");
    setSuccess("");

    try {
      await deletePreset(preset.preset_id);
      setSuccess(`Preset "${preset.name}" deleted.`);
      await loadPresetLibrary();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete preset.");
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Build flow</p>
            <h1 className="page-title">Build Your Night</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Apply a preset, adjust your current build, save it as a preset, and generate results on the next page.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
          </div>
        </div>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Preset library"
          subtitle="Apply backend presets or reuse your saved builds"
          actions={<Badge tone="accent">{presets.length} presets</Badge>}
        >
          {presets.length === 0 ? (
            <p className="muted" style={{ marginBottom: 0 }}>
              No presets available yet.
            </p>
          ) : (
            <div className="list">
              {presets.map((preset) => (
                <div key={preset.preset_id} className="item">
                  <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
                    <div>
                      <strong>{preset.name}</strong>
                      <p className="muted" style={{ margin: "0.35rem 0 0" }}>
                        {preset.description || "No description provided."}
                      </p>
                    </div>

                    <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                      <Badge tone={preset.owner_type === "user" ? "success" : "accent"}>
                        {preset.owner_type === "user" ? "Your preset" : "System preset"}
                      </Badge>
                    </div>
                  </div>

                  <div className="button-row" style={{ marginTop: "0.8rem" }}>
                    <Button onClick={() => handleApplyPreset(preset.preset_id)} disabled={presetLoading}>
                      {presetLoading ? "Applying..." : "Apply preset"}
                    </Button>

                    {preset.owner_type === "user" && preset.is_editable ? (
                      <Button variant="ghost" onClick={() => handleDeletePreset(preset)}>
                        Delete
                      </Button>
                    ) : null}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card
          title="Save current build as preset"
          subtitle="Turn the current builder selections into a reusable preset"
          actions={<Badge>{userPresets.length} yours</Badge>}
        >
          <form className="form" style={{ gap: "1rem" }} onSubmit={handleSavePreset}>
            <div className="form-row">
              <label htmlFor="preset_name">Preset name</label>
              <input
                id="preset_name"
                value={presetName}
                onChange={(e) => setPresetName(e.target.value)}
                placeholder="Weekend group dinner"
              />
            </div>

            <div className="form-row">
              <label htmlFor="preset_description">Description</label>
              <textarea
                id="preset_description"
                value={presetDescription}
                onChange={(e) => setPresetDescription(e.target.value)}
                rows={4}
                placeholder="What is this preset best for?"
              />
            </div>

            <div className="button-row">
              <Button type="submit" disabled={presetSaveLoading}>
                {presetSaveLoading ? "Saving..." : "Save preset"}
              </Button>
            </div>
          </form>
        </Card>
      </section>

      <form onSubmit={handleSubmit} className="grid grid-2" style={{ alignItems: "start" }}>
        <Card
          title="Build details"
          subtitle="Only the inputs needed for the recommendation run"
          actions={<Badge tone="accent">Focused flow</Badge>}
        >
          <div className="form" style={{ gap: "1rem" }}>
            <div className="form-row">
              <label htmlFor="outing_type">Outing type</label>
              <select
                id="outing_type"
                value={form.outing_type}
                onChange={(e) => setForm((prev) => ({ ...prev, outing_type: e.target.value }))}
              >
                {outingOptions.map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label htmlFor="budget">Budget</label>
              <select
                id="budget"
                value={form.budget}
                onChange={(e) => setForm((prev) => ({ ...prev, budget: e.target.value }))}
              >
                {budgetOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label htmlFor="pace">Pace</label>
              <select
                id="pace"
                value={form.pace}
                onChange={(e) => setForm((prev) => ({ ...prev, pace: e.target.value }))}
              >
                {paceOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label htmlFor="social_context">Social context</label>
              <select
                id="social_context"
                value={form.social_context}
                onChange={(e) => setForm((prev) => ({ ...prev, social_context: e.target.value }))}
              >
                {socialOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>

            <div className="item">
              <strong>Preferred cuisines</strong>
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.7rem" }}>
                {cuisineOptions.map((option) => (
                  <button
                    key={option}
                    type="button"
                    className={form.preferred_cuisines.includes(option) ? "preset-chip preset-chip--active" : "preset-chip"}
                    onClick={() =>
                      setForm((prev) => ({
                        ...prev,
                        preferred_cuisines: toggleArrayValue(prev.preferred_cuisines, option)
                      }))
                    }
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            <div className="item">
              <strong>Atmosphere</strong>
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.7rem" }}>
                {atmosphereOptions.map((option) => (
                  <button
                    key={option}
                    type="button"
                    className={form.atmosphere.includes(option) ? "preset-chip preset-chip--active" : "preset-chip"}
                    onClick={() =>
                      setForm((prev) => ({
                        ...prev,
                        atmosphere: toggleArrayValue(prev.atmosphere, option)
                      }))
                    }
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            <label
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.7rem",
                marginTop: "0.25rem"
              }}
            >
              <input
                type="checkbox"
                checked={form.drinks_focus}
                onChange={(e) => setForm((prev) => ({ ...prev, drinks_focus: e.target.checked }))}
              />
              <span>Prioritize drinks-friendly recommendations</span>
            </label>

            <div className="button-row">
              <Button type="submit" disabled={loading}>
                {loading ? "Generating..." : "Generate recommendations"}
              </Button>
              <Button
                variant="secondary"
                type="button"
                onClick={() => setForm(initialState)}
                disabled={loading}
              >
                Reset
              </Button>
            </div>
          </div>
        </Card>

        <Card
          title="Current build"
          subtitle="Live summary of what will be sent"
          actions={<Badge>Ready</Badge>}
        >
          <div className="list">
            <div className="item"><strong>Outing type</strong><p className="muted">{form.outing_type}</p></div>
            <div className="item"><strong>Budget</strong><p className="muted">{form.budget || "No preference"}</p></div>
            <div className="item"><strong>Pace</strong><p className="muted">{form.pace || "No preference"}</p></div>
            <div className="item"><strong>Social context</strong><p className="muted">{form.social_context || "No preference"}</p></div>
            <div className="item">
              <strong>Cuisines</strong>
              <p className="muted">{form.preferred_cuisines.length ? form.preferred_cuisines.join(", ") : "None selected"}</p>
            </div>
            <div className="item">
              <strong>Atmosphere</strong>
              <p className="muted">{form.atmosphere.length ? form.atmosphere.join(", ") : "None selected"}</p>
            </div>
            <div className="item">
              <strong>Drinks focus</strong>
              <p className="muted">{form.drinks_focus ? "Yes" : "No"}</p>
            </div>
          </div>
        </Card>
      </form>
    </div>
  );
}
EOF

cat > src/pages/recommendations/DescribeNightPage.tsx <<'EOF'
import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  runDescribeNight,
  saveRecommendationResult
} from "../../lib/recommendationFlow";

export default function DescribeNightPage() {
  const navigate = useNavigate();
  const [prompt, setPrompt] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");

    try {
      const response = await runDescribeNight({ prompt });

      saveRecommendationResult({
        mode: "describe",
        createdAt: new Date().toISOString(),
        request: { prompt },
        response
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate recommendations.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Describe flow</p>
            <h1 className="page-title">Describe the Night</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Write the vibe you want here, then see only the recommendation cards on the next page.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
          </div>
        </div>
      </section>

      <form onSubmit={handleSubmit}>
        <Card
          title="Describe your ideal night"
          subtitle="Natural-language request only, without extra clutter"
          actions={<Badge tone="accent">Prompt flow</Badge>}
        >
          {error ? <div className="error">{error}</div> : null}

          <div className="form" style={{ gap: "1rem" }}>
            <div className="form-row">
              <label htmlFor="describe_prompt">Prompt</label>
              <textarea
                id="describe_prompt"
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="I want a cozy dinner spot with good drinks, relaxed pacing, and food that feels memorable without being too formal..."
                rows={8}
              />
            </div>

            <div className="button-row">
              <Button type="submit" disabled={loading || prompt.trim().length < 3}>
                {loading ? "Interpreting..." : "Generate recommendations"}
              </Button>
            </div>
          </div>
        </Card>
      </form>
    </div>
  );
}
EOF

cat > src/pages/recommendations/SurpriseMePage.tsx <<'EOF'
import { useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  runSurpriseMe,
  saveRecommendationResult
} from "../../lib/recommendationFlow";

export default function SurpriseMePage() {
  const navigate = useNavigate();
  const [includeDrinks, setIncludeDrinks] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSurprise() {
    setLoading(true);
    setError("");

    try {
      const response = await runSurpriseMe({ include_drinks: includeDrinks });

      saveRecommendationResult({
        mode: "surprise",
        createdAt: new Date().toISOString(),
        request: { include_drinks: includeDrinks },
        response
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate recommendations.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Surprise flow</p>
            <h1 className="page-title">Surprise Me</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Fastest path to a new dining suggestion without extra scrolling or clutter.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
          </div>
        </div>
      </section>

      <Card
        title="Generate a surprise set"
        subtitle="Minimal input, separate output page"
        actions={<Badge tone="accent">Fast flow</Badge>}
      >
        {error ? <div className="error">{error}</div> : null}

        <div className="list">
          <div className="item">
            <strong>Include drinks-friendly places?</strong>
            <div className="button-row" style={{ marginTop: "0.75rem" }}>
              <Button
                variant={includeDrinks ? "primary" : "secondary"}
                onClick={() => setIncludeDrinks(true)}
              >
                Yes
              </Button>
              <Button
                variant={!includeDrinks ? "primary" : "secondary"}
                onClick={() => setIncludeDrinks(false)}
              >
                No
              </Button>
            </div>
          </div>

          <div className="button-row">
            <Button onClick={handleSurprise} disabled={loading}>
              {loading ? "Generating..." : "Generate surprise recommendations"}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
}
EOF

cat > src/pages/recommendations/RecommendationResultsPage.tsx <<'EOF'
import { useMemo } from "react";
import { useNavigate } from "react-router-dom";

import RecommendationCard from "../../components/dining/RecommendationCard";
import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  clearRecommendationResult,
  loadRecommendationResult,
  normalizeRecommendationScore
} from "../../lib/recommendationFlow";

export default function RecommendationResultsPage() {
  const navigate = useNavigate();
  const stored = useMemo(() => loadRecommendationResult(), []);

  const maxScore = useMemo(() => {
    const scores = (stored?.response.results || [])
      .map((item) => item.score)
      .filter((score) => Number.isFinite(score));
    if (scores.length === 0) return 1;
    return Math.max(...scores, 1);
  }, [stored]);

  if (!stored) {
    return (
      <Card
        title="No recommendation results found"
        subtitle="Start from the recommendation hub to generate a new result page."
        actions={<Badge>Empty</Badge>}
      >
        <div className="button-row">
          <Button onClick={() => navigate("/recommendations")}>Go to recommendation hub</Button>
        </div>
      </Card>
    );
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Recommendation results</p>
            <h1 className="page-title">Your results</h1>
            <p className="muted" style={{ marginBottom: 0 }}>
              Clean output only. No extra diagnostics.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
            <Button
              variant="secondary"
              onClick={() => navigate(
                stored.mode === "build"
                  ? "/recommendations/build"
                  : stored.mode === "describe"
                  ? "/recommendations/describe"
                  : "/recommendations/surprise"
              )}
            >
              Back to flow
            </Button>
            <Button
              onClick={() => {
                clearRecommendationResult();
                navigate("/recommendations");
              }}
            >
              Start new search
            </Button>
          </div>
        </div>
      </section>

      <section className="grid" style={{ gap: "1rem" }}>
        {stored.response.results.length === 0 ? (
          <Card
            title="No recommendations returned"
            subtitle="The request completed, but no result cards were returned."
            actions={<Badge>0 results</Badge>}
          >
            <div className="button-row">
              <Button onClick={() => navigate("/recommendations")}>Go back</Button>
            </div>
          </Card>
        ) : (
          stored.response.results.map((item, index) => (
            <RecommendationCard
              key={`${item.restaurant_id}-${index}`}
              title={item.restaurant_name || `Recommendation ${index + 1}`}
              restaurantName={item.restaurant_name}
              rank={item.rank}
              fitLabel={item.fit_label}
              score={normalizeRecommendationScore(item.score, maxScore)}
              explanation={
                item.explanation ||
                (item.reasons && item.reasons.length > 0
                  ? item.reasons.join(" • ")
                  : "This restaurant matched your current dining request.")
              }
              confidenceLevel={item.confidence_level}
              matchedSignals={item.matched_signals || []}
              penalizedSignals={item.penalized_signals || []}
              scoreBreakdown={item.score_breakdown || []}
              tags={[
                ...(item.active_event_matches || []).map((eventLabel) => `event: ${eventLabel}`),
                ...(item.suggested_dishes || []).map((dish) => `dish: ${dish}`),
                ...(item.suggested_drinks || []).map((drink) => `drink: ${drink}`)
              ].slice(0, 6)}
            />
          ))
        )}
      </section>
    </div>
  );
}
EOF

cat > src/components/dining/RecommendationCard.tsx <<'EOF'
import { useState } from "react";

import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";
import { ScoreBreakdownItem } from "../../types";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  rank?: number;
  fitLabel?: string;
  explanation?: string;
  confidenceLevel?: string;
  tags?: string[];
  matchedSignals?: string[];
  penalizedSignals?: string[];
  scoreBreakdown?: ScoreBreakdownItem[];
  ctaLabel?: string;
  onClick?: () => void;
};

function formatScore(score?: number) {
  if (score === undefined || score === null || Number.isNaN(score)) {
    return null;
  }

  const clamped = Math.max(0, Math.min(score, 1));
  return `${Math.round(clamped * 100)}% match`;
}

function confidenceTone(confidenceLevel?: string): "default" | "accent" | "success" | "warning" {
  switch ((confidenceLevel || "").toLowerCase()) {
    case "high":
      return "success";
    case "medium":
      return "accent";
    case "exploratory":
      return "warning";
    default:
      return "default";
  }
}

function confidenceLabel(confidenceLevel?: string): string | null {
  if (!confidenceLevel) {
    return null;
  }

  if (confidenceLevel === "high") {
    return "High confidence";
  }

  if (confidenceLevel === "medium") {
    return "Medium confidence";
  }

  if (confidenceLevel === "exploratory") {
    return "Exploratory";
  }

  return confidenceLevel;
}

function fitTone(fitLabel?: string): "default" | "accent" | "success" | "warning" {
  switch ((fitLabel || "").toLowerCase()) {
    case "excellent fit":
      return "success";
    case "strong fit":
      return "accent";
    case "possible fit":
      return "warning";
    default:
      return "default";
  }
}

function formatBreakdownPoints(points: number): string {
  return `${points >= 0 ? "+" : ""}${points.toFixed(2)}`;
}

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  rank,
  fitLabel,
  explanation,
  confidenceLevel,
  tags = [],
  matchedSignals = [],
  penalizedSignals = [],
  scoreBreakdown = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const [expanded, setExpanded] = useState(false);
  const scoreLabel = formatScore(score);
  const confidence = confidenceLabel(confidenceLevel);

  return (
    <Card
      className="recommendation-card"
      title={rank ? `#${rank} • ${title}` : title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={
        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
          {scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : <Badge>Match pending</Badge>}
          {fitLabel ? <Badge tone={fitTone(fitLabel)}>{fitLabel}</Badge> : null}
          {confidence ? <Badge tone={confidenceTone(confidenceLevel)}>{confidence}</Badge> : null}
        </div>
      }
    >
      <div className="grid" style={{ gap: "0.9rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {explanation || "A recommendation is ready, but no explanation was provided yet."}
        </p>

        {tags.length > 0 ? (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            {tags.map((tag) => (
              <Badge key={tag} tone="accent">
                {tag}
              </Badge>
            ))}
          </div>
        ) : (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            <Badge>Context-aware</Badge>
            <Badge tone="accent">Dining fit</Badge>
          </div>
        )}

        <div className="button-row" style={{ marginTop: 0 }}>
          <Button variant="ghost" onClick={() => setExpanded((prev) => !prev)}>
            {expanded ? "Hide scoring detail" : "Show scoring detail"}
          </Button>

          {onClick ? (
            <Button variant="ghost" onClick={onClick}>
              {ctaLabel}
            </Button>
          ) : null}
        </div>

        {expanded ? (
          <div className="grid" style={{ gap: "0.85rem" }}>
            {matchedSignals.length > 0 ? (
              <div className="item">
                <strong>Matched signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {matchedSignals.map((signal) => (
                    <Badge key={signal} tone="success">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {penalizedSignals.length > 0 ? (
              <div className="item">
                <strong>Penalized signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {penalizedSignals.map((signal) => (
                    <Badge key={signal} tone="warning">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {scoreBreakdown.length > 0 ? (
              <div className="item">
                <strong>Score breakdown</strong>
                <div style={{ display: "grid", gap: "0.45rem", marginTop: "0.6rem" }}>
                  {scoreBreakdown.map((entry) => (
                    <div
                      key={`${entry.label}-${entry.points}`}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        gap: "1rem",
                        padding: "0.55rem 0.7rem",
                        borderRadius: "0.75rem",
                        background: "rgba(15, 23, 42, 0.35)",
                        border: "1px solid rgba(148, 163, 184, 0.15)"
                      }}
                    >
                      <span>{entry.label}</span>
                      <strong>{formatBreakdownPoints(entry.points)}</strong>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>
    </Card>
  );
}
EOF

cat > src/App.tsx <<'EOF'
import { Navigate, Route, Routes } from "react-router-dom";

import Layout from "./components/layout/Layout";
import ProtectedRoute from "./components/layout/ProtectedRoute";
import { useAuth } from "./context/AuthContext";
import DashboardPage from "./pages/DashboardPage";
import ExperiencesPage from "./pages/ExperiencesPage";
import LoginPage from "./pages/LoginPage";
import NewExperiencePage from "./pages/NewExperiencePage";
import OnboardingPage from "./pages/OnboardingPage";
import ProfilePage from "./pages/ProfilePage";
import RecommendationsPage from "./pages/RecommendationsPage";
import BuildNightPage from "./pages/recommendations/BuildNightPage";
import DescribeNightPage from "./pages/recommendations/DescribeNightPage";
import RecommendationResultsPage from "./pages/recommendations/RecommendationResultsPage";
import SurpriseMePage from "./pages/recommendations/SurpriseMePage";
import RegisterPage from "./pages/RegisterPage";
import RestaurantDetailPage from "./pages/RestaurantDetailPage";
import RestaurantsPage from "./pages/RestaurantsPage";

function AppEntryRedirect() {
  const { token, user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading...</div>
      </div>
    );
  }

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  if (!user?.onboarding_completed) {
    return <Navigate to="/onboarding" replace />;
  }

  return <Navigate to="/dashboard" replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<AppEntryRedirect />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Layout>
              <DashboardPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/profile"
        element={
          <ProtectedRoute>
            <Layout>
              <ProfilePage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/profile/preferences"
        element={
          <ProtectedRoute allowIncompleteOnboarding>
            <Layout>
              <OnboardingPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/onboarding"
        element={
          <ProtectedRoute allowIncompleteOnboarding redirectCompletedUsersTo="/dashboard">
            <Layout>
              <OnboardingPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations"
        element={
          <ProtectedRoute>
            <Layout>
              <RecommendationsPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations/build"
        element={
          <ProtectedRoute>
            <Layout>
              <BuildNightPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations/describe"
        element={
          <ProtectedRoute>
            <Layout>
              <DescribeNightPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations/surprise"
        element={
          <ProtectedRoute>
            <Layout>
              <SurpriseMePage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations/results"
        element={
          <ProtectedRoute>
            <Layout>
              <RecommendationResultsPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/restaurants"
        element={
          <ProtectedRoute>
            <Layout>
              <RestaurantsPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/restaurants/:restaurantId"
        element={
          <ProtectedRoute>
            <Layout>
              <RestaurantDetailPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/experiences"
        element={
          <ProtectedRoute>
            <Layout>
              <ExperiencesPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/experiences/new"
        element={
          <ProtectedRoute>
            <Layout>
              <NewExperiencePage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<AppEntryRedirect />} />
    </Routes>
  );
}
EOF

PYTHON_BIN="python3"
if [[ -x ".venv/bin/python" ]]; then
  PYTHON_BIN=".venv/bin/python"
fi

if [[ -f "src/components/navigation/Sidebar.tsx" ]]; then
  "$PYTHON_BIN" - <<'PYEOF'
from pathlib import Path

path = Path("src/components/navigation/Sidebar.tsx")
text = path.read_text()

text = text.replace(
    'to="/recommendations">\n          Manage presets\n        </Link>',
    'to="/recommendations/build">\n          Build a night\n        </Link>'
)

path.write_text(text)
PYEOF
fi

echo "Running TypeScript check..."
if command -v npx >/dev/null 2>&1; then
  npx tsc -b
else
  echo "npx not found; skipping TypeScript check."
fi

echo
echo "Patch 8 applied successfully."
echo "Next steps:"
echo "1) cd frontend"
echo "2) npm run dev"
echo "3) test /recommendations"
echo "4) test build preset apply/save/delete"
echo "5) test results page clarity and back navigation"
