#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch5_fastfood_dishes_and_navigation_backup_$STAMP"

FILES=(
  "$FRONTEND_DIR/src/lib/recommendationFlow.ts"
  "$FRONTEND_DIR/src/pages/recommendations/BuildNightPage.tsx"
  "$FRONTEND_DIR/src/pages/recommendations/RecommendationResultsPage.tsx"
  "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx"
  "$FRONTEND_DIR/src/styles.css"
)

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file"
    echo "Run this from the project root."
    exit 1
  fi
done

mkdir -p \
  "$BACKUP_DIR/frontend/src/lib" \
  "$BACKUP_DIR/frontend/src/pages/recommendations" \
  "$BACKUP_DIR/frontend/src/components/navigation" \
  "$BACKUP_DIR/frontend/src"

cp "$FRONTEND_DIR/src/lib/recommendationFlow.ts" \
  "$BACKUP_DIR/frontend/src/lib/recommendationFlow.ts"
cp "$FRONTEND_DIR/src/pages/recommendations/BuildNightPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/recommendations/BuildNightPage.tsx"
cp "$FRONTEND_DIR/src/pages/recommendations/RecommendationResultsPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/recommendations/RecommendationResultsPage.tsx"
cp "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" \
  "$BACKUP_DIR/frontend/src/components/navigation/Sidebar.tsx"
cp "$FRONTEND_DIR/src/styles.css" \
  "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch5_fastfood_dishes_and_navigation..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

flow_path = Path("frontend/src/lib/recommendationFlow.ts")
build_path = Path("frontend/src/pages/recommendations/BuildNightPage.tsx")
results_path = Path("frontend/src/pages/recommendations/RecommendationResultsPage.tsx")
sidebar_path = Path("frontend/src/components/navigation/Sidebar.tsx")
styles_path = Path("frontend/src/styles.css")

flow_path.write_text("""import { apiRequest } from "./api";
import type { RecommendationResponse } from "../types";

export type PresetSelectionPayload = {
  outing_type?: string | null;
  mood?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines?: string[];
  drinks_focus?: boolean | null;
  atmosphere?: string[];
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
  flowLabel?: string;
  originPath?: string;
  presetContext?: {
    preset_id?: string | null;
    name?: string | null;
    owner_type?: string | null;
    can_customize?: boolean;
  } | null;
};

export const RESULT_STORAGE_KEY = "savr:recommendation-flow-result:v5";

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
  fast_food?: boolean;
  requires_dine_in?: boolean;
  requires_takeout?: boolean;
  include_dish_hints?: boolean;
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

export async function getPreset(presetId: string) {
  return apiRequest<PresetResponse>(`/presets/${presetId}`);
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

export async function updatePreset(
  presetId: string,
  body: {
    name?: string;
    description?: string | null;
    selection_payload?: PresetSelectionPayload;
  }
) {
  return apiRequest<PresetResponse>(`/presets/${presetId}`, {
    method: "PUT",
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
""")

build_path.write_text("""import { FormEvent, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  applyPreset,
  createPreset,
  deletePreset,
  listPresets,
  type PresetApplyResponse,
  type PresetResponse,
  type PresetSelectionPayload,
  runBuildNight,
  saveRecommendationResult,
  updatePreset
} from "../../lib/recommendationFlow";

type BuildFormState = {
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
  fast_food: boolean;
  requires_dine_in: boolean;
  requires_takeout: boolean;
  include_dish_hints: boolean;
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
  drinks_focus: false,
  fast_food: false,
  requires_dine_in: false,
  requires_takeout: false,
  include_dish_hints: true
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
    atmosphere: form.atmosphere,
    fast_food: form.fast_food,
    requires_dine_in: form.requires_dine_in,
    requires_takeout: form.requires_takeout,
    include_dish_hints: form.include_dish_hints
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
    drinks_focus: Boolean(payload.drinks_focus),
    fast_food: Boolean(payload.fast_food),
    requires_dine_in: Boolean(payload.requires_dine_in),
    requires_takeout: Boolean(payload.requires_takeout),
    include_dish_hints: payload.include_dish_hints !== false
  };
}

function presetSummary(preset: PresetResponse) {
  const payload = preset.selection_payload;
  const chips: string[] = [];

  if (payload.outing_type) chips.push(payload.outing_type);
  if (payload.budget) chips.push(payload.budget);
  if (payload.pace) chips.push(payload.pace);
  if (payload.social_context) chips.push(payload.social_context);
  if (payload.preferred_cuisines?.length) chips.push(...payload.preferred_cuisines.slice(0, 2));
  if (payload.atmosphere?.length) chips.push(...payload.atmosphere.slice(0, 2));
  if (payload.drinks_focus) chips.push("drinks");
  if (payload.fast_food) chips.push("fast food");
  if (payload.requires_dine_in) chips.push("dine-in");
  if (payload.requires_takeout) chips.push("takeout");
  if (payload.include_dish_hints) chips.push("dish hints");

  return chips.slice(0, 8);
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
  const [activePreset, setActivePreset] = useState<PresetResponse | null>(null);
  const [activePresetReview, setActivePresetReview] = useState<PresetApplyResponse | null>(null);
  const [editingPresetId, setEditingPresetId] = useState<string | null>(null);

  const userPresets = useMemo(
    () => presets.filter((preset) => preset.owner_type === "user"),
    [presets]
  );

  const currentPayload = useMemo(() => toPresetPayload(form), [form]);

  const isPresetCustomized = useMemo(() => {
    if (!activePresetReview) return false;
    return JSON.stringify(activePresetReview.builder_payload) !== JSON.stringify(currentPayload);
  }, [activePresetReview, currentPayload]);

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
        drinks_focus: form.drinks_focus,
        fast_food: form.fast_food,
        requires_dine_in: form.requires_dine_in,
        requires_takeout: form.requires_takeout,
        include_dish_hints: form.include_dish_hints
      });

      saveRecommendationResult({
        mode: "build",
        flowLabel: "Build Your Night",
        originPath: "/recommendations/build",
        createdAt: new Date().toISOString(),
        request: form,
        response,
        presetContext: activePreset
          ? {
              preset_id: activePreset.preset_id,
              name: activePreset.name,
              owner_type: activePreset.owner_type,
              can_customize: activePresetReview?.can_customize ?? true
            }
          : null
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
      setActivePreset(data.preset);
      setActivePresetReview(data);
      setEditingPresetId(null);
      setPresetName(data.preset.owner_type === "user" ? data.preset.name : "");
      setPresetDescription(data.preset.owner_type === "user" ? data.preset.description || "" : "");
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

      if (editingPresetId) {
        const updated = await updatePreset(editingPresetId, {
          name: presetName.trim(),
          description: presetDescription.trim() || null,
          selection_payload: currentPayload
        });

        setActivePreset(updated);
        setActivePresetReview({
          preset: updated,
          builder_payload: updated.selection_payload,
          banner_message: `Preset "${updated.name}" updated. You can keep customizing before generating recommendations.`,
          can_customize: true
        });
        setSuccess(`Preset "${updated.name}" updated successfully.`);
      } else {
        const created = await createPreset({
          name: presetName.trim(),
          description: presetDescription.trim() || null,
          selection_payload: currentPayload
        });

        setActivePreset(created);
        setActivePresetReview({
          preset: created,
          builder_payload: created.selection_payload,
          banner_message: `Preset "${created.name}" saved. You can keep customizing before generating recommendations.`,
          can_customize: true
        });
        setEditingPresetId(created.preset_id);
        setSuccess("Preset saved successfully.");
      }

      await loadPresetLibrary();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save preset.");
    } finally {
      setPresetSaveLoading(false);
    }
  }

  function handleStartEditingPreset(preset: PresetResponse) {
    setEditingPresetId(preset.preset_id);
    setPresetName(preset.name);
    setPresetDescription(preset.description || "");
    setActivePreset(preset);
    setActivePresetReview({
      preset,
      builder_payload: preset.selection_payload,
      banner_message: `Editing preset "${preset.name}". Update fields, then save your changes.`,
      can_customize: true
    });
    setForm(fromPresetPayload(preset.selection_payload));
    setSuccess(`Loaded "${preset.name}" into the builder for editing.`);
    setError("");
  }

  function handleClearPresetContext() {
    setActivePreset(null);
    setActivePresetReview(null);
    setEditingPresetId(null);
    setPresetName("");
    setPresetDescription("");
    setSuccess("Preset context cleared. You are now working from the current builder values only.");
    setError("");
  }

  async function handleDeletePreset(preset: PresetResponse) {
    const confirmed = window.confirm(`Delete the preset "${preset.name}"?`);
    if (!confirmed) return;

    setError("");
    setSuccess("");

    try {
      await deletePreset(preset.preset_id);
      if (activePreset?.preset_id === preset.preset_id) {
        handleClearPresetContext();
      }
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
              Apply presets, customize the builder, include fast-food or service-mode constraints, request dish hints, and generate results on the next page.
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

      {activePreset ? (
        <section className="recommendation-flow-banner" role="status">
          <div>
            <p className="navbar-eyebrow" style={{ marginBottom: "0.35rem" }}>Preset review</p>
            <strong>{activePreset.name}</strong>
            <p className="muted" style={{ margin: "0.35rem 0 0" }}>
              {activePresetReview?.banner_message ||
                `Preset "${activePreset.name}" is active in this build flow.`}
            </p>
            <div className="preset-chip-row" style={{ marginTop: "0.75rem" }}>
              <span className="preset-chip preset-chip--active">
                {activePreset.owner_type === "user" ? "Your preset" : "System preset"}
              </span>
              {isPresetCustomized ? (
                <span className="preset-chip preset-chip--active">Customized after apply</span>
              ) : (
                <span className="preset-chip">Using preset defaults</span>
              )}
              {activePresetReview?.can_customize ? (
                <span className="preset-chip">Builder remains editable</span>
              ) : null}
            </div>
          </div>

          <div className="button-row">
            {activePreset.owner_type === "user" && activePreset.is_editable ? (
              <Button variant="secondary" onClick={() => handleStartEditingPreset(activePreset)}>
                Edit preset
              </Button>
            ) : null}
            <Button variant="ghost" onClick={handleClearPresetContext}>
              Clear preset context
            </Button>
          </div>
        </section>
      ) : null}

      <section className="grid grid-2">
        <Card
          title="Preset library"
          subtitle="Apply backend presets or reuse and edit your saved builds"
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
                      <div className="preset-chip-row" style={{ marginTop: "0.7rem" }}>
                        {presetSummary(preset).map((chip) => (
                          <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                            {chip}
                          </span>
                        ))}
                      </div>
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
                      <>
                        <Button variant="secondary" onClick={() => handleStartEditingPreset(preset)}>
                          Load to edit
                        </Button>
                        <Button variant="ghost" onClick={() => handleDeletePreset(preset)}>
                          Delete
                        </Button>
                      </>
                    ) : null}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card
          title={editingPresetId ? "Update current preset" : "Save current build as preset"}
          subtitle={
            editingPresetId
              ? "You are editing one of your saved presets with the current builder selections"
              : "Turn the current builder selections into a reusable preset"
          }
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
                {presetSaveLoading
                  ? editingPresetId
                    ? "Updating..."
                    : "Saving..."
                  : editingPresetId
                  ? "Update preset"
                  : "Save preset"}
              </Button>

              {editingPresetId ? (
                <Button variant="ghost" type="button" onClick={handleClearPresetContext}>
                  Cancel edit
                </Button>
              ) : null}
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

            <div className="toggle-grid">
              <label className="build-toggle">
                <input
                  type="checkbox"
                  checked={form.drinks_focus}
                  onChange={(e) => setForm((prev) => ({ ...prev, drinks_focus: e.target.checked }))}
                />
                <div>
                  <strong>Drinks focus</strong>
                  <p className="muted">Prioritize drinks-friendly recommendations.</p>
                </div>
              </label>

              <label className="build-toggle">
                <input
                  type="checkbox"
                  checked={form.fast_food}
                  onChange={(e) => setForm((prev) => ({ ...prev, fast_food: e.target.checked }))}
                />
                <div>
                  <strong>Fast food okay</strong>
                  <p className="muted">Allow quick-service and fast-food style recommendations.</p>
                </div>
              </label>

              <label className="build-toggle">
                <input
                  type="checkbox"
                  checked={form.requires_dine_in}
                  onChange={(e) =>
                    setForm((prev) => ({
                      ...prev,
                      requires_dine_in: e.target.checked,
                      requires_takeout: e.target.checked ? false : prev.requires_takeout
                    }))
                  }
                />
                <div>
                  <strong>Dine-in required</strong>
                  <p className="muted">Useful when you want a sit-down experience only.</p>
                </div>
              </label>

              <label className="build-toggle">
                <input
                  type="checkbox"
                  checked={form.requires_takeout}
                  onChange={(e) =>
                    setForm((prev) => ({
                      ...prev,
                      requires_takeout: e.target.checked,
                      requires_dine_in: e.target.checked ? false : prev.requires_dine_in
                    }))
                  }
                />
                <div>
                  <strong>Takeout required</strong>
                  <p className="muted">Useful when you want portability and speed.</p>
                </div>
              </label>

              <label className="build-toggle">
                <input
                  type="checkbox"
                  checked={form.include_dish_hints}
                  onChange={(e) => setForm((prev) => ({ ...prev, include_dish_hints: e.target.checked }))}
                />
                <div>
                  <strong>Show dish hints</strong>
                  <p className="muted">Ask the engine to emphasize dish and drink suggestions.</p>
                </div>
              </label>
            </div>

            <div className="button-row">
              <Button type="submit" disabled={loading}>
                {loading ? "Generating..." : "Generate recommendations"}
              </Button>
              <Button
                variant="secondary"
                type="button"
                onClick={() => {
                  setForm(initialState);
                  setActivePreset(null);
                  setActivePresetReview(null);
                  setEditingPresetId(null);
                }}
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
          actions={<Badge>{activePreset ? "Preset-aware" : "Manual"}</Badge>}
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
              <strong>Service & hinting</strong>
              <p className="muted">
                {[
                  form.drinks_focus ? "drinks focus" : null,
                  form.fast_food ? "fast food enabled" : null,
                  form.requires_dine_in ? "dine-in only" : null,
                  form.requires_takeout ? "takeout only" : null,
                  form.include_dish_hints ? "dish hints on" : "dish hints off"
                ]
                  .filter(Boolean)
                  .join(" • ")}
              </p>
            </div>
            {activePreset ? (
              <div className="item">
                <strong>Preset state</strong>
                <p className="muted">
                  {activePreset.name} · {isPresetCustomized ? "customized after apply" : "using preset defaults"}
                </p>
              </div>
            ) : null}
          </div>
        </Card>
      </form>
    </div>
  );
}
""")

results_path.write_text("""import { useMemo } from "react";
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

  const returnPath =
    stored.originPath ||
    (stored.mode === "build"
      ? "/recommendations/build"
      : stored.mode === "describe"
      ? "/recommendations/describe"
      : "/recommendations/surprise");

  const flowLabel =
    stored.flowLabel ||
    (stored.mode === "build"
      ? "Build Your Night"
      : stored.mode === "describe"
      ? "Describe the Night"
      : "Surprise Me");

  const request = stored.request as
    | {
        outing_type?: string;
        budget?: string;
        pace?: string;
        social_context?: string;
        preferred_cuisines?: string[];
        atmosphere?: string[];
        drinks_focus?: boolean;
        fast_food?: boolean;
        requires_dine_in?: boolean;
        requires_takeout?: boolean;
        include_dish_hints?: boolean;
      }
    | undefined;

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Recommendation results</p>
            <h1 className="page-title">Your results</h1>
            <p className="muted" style={{ marginBottom: 0 }}>
              Generated from <strong>{flowLabel}</strong>
              {stored.presetContext?.name ? ` using preset "${stored.presetContext.name}"` : ""}.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
            <Button variant="secondary" onClick={() => navigate(returnPath)}>
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

      <section className="grid grid-2">
        <Card
          title="Flow summary"
          subtitle="High-level context for the current recommendation set"
          actions={<Badge tone="accent">{stored.response.results.length} results</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Flow</strong>
              <p className="muted" style={{ marginBottom: 0 }}>{flowLabel}</p>
            </div>
            <div className="item">
              <strong>Generated</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {new Date(stored.createdAt).toLocaleString()}
              </p>
            </div>
            {stored.presetContext?.name ? (
              <div className="item">
                <strong>Preset context</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {stored.presetContext.name} · {stored.presetContext.owner_type === "user" ? "user preset" : "system preset"}
                </p>
              </div>
            ) : null}
            {stored.response.request_summary ? (
              <>
                <div className="item">
                  <strong>Outing type</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.outing_type || request?.outing_type || "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Budget</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.budget || request?.budget || "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Pace</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.pace || request?.pace || "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Atmosphere</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.atmosphere?.length
                      ? stored.response.request_summary.atmosphere.join(", ")
                      : request?.atmosphere?.length
                      ? request.atmosphere.join(", ")
                      : "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Service and hinting</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {[
                      request?.drinks_focus ? "drinks focus" : null,
                      request?.fast_food ? "fast food allowed" : null,
                      request?.requires_dine_in ? "dine-in required" : null,
                      request?.requires_takeout ? "takeout required" : null,
                      request?.include_dish_hints ? "dish hints requested" : "dish hints not requested"
                    ]
                      .filter(Boolean)
                      .join(" • ")}
                  </p>
                </div>
              </>
            ) : null}
          </div>
        </Card>

        <Card
          title="What to do next"
          subtitle="Keep the route-based flow clear and reversible"
          actions={<Badge>Navigation</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Refine this result</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Return to the originating flow to adjust the request and generate a new result set.
              </p>
            </div>
            <div className="item">
              <strong>Start a different flow</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Go back to the hub to switch between build, describe, and surprise without losing route clarity.
              </p>
            </div>
            <div className="item">
              <strong>Review saved presets</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Open your account-owned presets page if this flow should become a reusable saved configuration.
              </p>
            </div>
          </div>
        </Card>
      </section>

      <section className="grid" style={{ gap: "1rem" }}>
        {stored.response.results.length === 0 ? (
          <Card
            title="No recommendations returned"
            subtitle="The request completed, but no result cards were returned."
            actions={<Badge>0 results</Badge>}
          >
            <div className="button-row">
              <Button onClick={() => navigate(returnPath)}>Go back to the previous flow</Button>
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
              reasons={item.reasons}
              suggestedDishes={item.suggested_dishes}
              suggestedDrinks={item.suggested_drinks}
              activeEventMatches={item.active_event_matches}
              matchedSignals={item.matched_signals}
              penalizedSignals={item.penalized_signals}
              scoreBreakdown={item.score_breakdown}
            />
          ))
        )}
      </section>
    </div>
  );
}
""")

sidebar_path.write_text("""import { Link, NavLink, type NavLinkRenderProps } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "DB" },
  { to: "/profile", label: "Profile", short: "PF" },
  { to: "/profile/presets", label: "Saved presets", short: "SP" },
  { to: "/recommendations", label: "Recommendations", short: "RC" },
  { to: "/restaurants", label: "Restaurants", short: "RS" },
  { to: "/experiences", label: "Experiences", short: "EX" }
];

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">SV</div>

        <div>
          <p className="sidebar-eyebrow">Personal dining guide</p>
          <h1 className="sidebar-brand">SAVR</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Current user</p>
          <span className="sidebar-online-pill">Online</span>
        </div>

        <strong className="sidebar-user-name">{userName || "Guest user"}</strong>

        <p className="muted">
          Explore restaurants, update your profile, review saved presets, and discover dining experiences that fit your style.
        </p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }: NavLinkRenderProps) =>
              ["sidebar-link", isActive ? "sidebar-link--active" : ""]
                .filter(Boolean)
                .join(" ")
            }
          >
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-section">
        <p className="sidebar-section-label">Account shortcuts</p>
        <div className="sidebar-quick-actions">
          <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/profile">
            Open profile
          </Link>
          <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/profile/preferences">
            Edit preferences
          </Link>
          <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/profile/presets">
            Open saved presets
          </Link>
        </div>
      </div>

      <div className="sidebar-section">
        <p className="sidebar-section-label">Recommendation shortcuts</p>
        <div className="sidebar-quick-actions">
          <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/build">
            Build a night
          </Link>
          <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/describe">
            Describe a night
          </Link>
          <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/surprise">
            Surprise me
          </Link>
        </div>
      </div>

      <div className="sidebar-footer">
        <button
          className="ui-button ui-button--ghost ui-button--md ui-button--full sidebar-logout"
          type="button"
          onClick={onLogout}
        >
          Logout
        </button>
      </div>
    </aside>
  );
}
""")

styles = styles_path.read_text()
extra = """

.toggle-grid {
  display: grid;
  gap: 0.85rem;
}

.build-toggle {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.8rem;
  align-items: start;
  padding: 0.9rem 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(15, 23, 42, 0.25);
}

.build-toggle input {
  margin-top: 0.2rem;
}

.build-toggle p {
  margin: 0.25rem 0 0;
}

.sidebar-section {
  display: grid;
  gap: 0.75rem;
}

.sidebar-section + .sidebar-section {
  margin-top: 0.5rem;
}
"""
if ".toggle-grid" not in styles:
    styles += extra
styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 5 applied successfully."
echo "Files changed:"
echo " - frontend/src/lib/recommendationFlow.ts"
echo " - frontend/src/pages/recommendations/BuildNightPage.tsx"
echo " - frontend/src/pages/recommendations/RecommendationResultsPage.tsx"
echo " - frontend/src/components/navigation/Sidebar.tsx"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) run frontend and backend"
echo "2) open /recommendations/build"
echo "3) test fast food, dine-in, takeout, and dish-hint toggles"
echo "4) save a preset containing those new toggles"
echo "5) re-apply that preset and confirm the toggles restore correctly"
echo "6) generate recommendations and confirm the results summary shows those request flags"
echo "7) confirm Sidebar account and recommendation shortcut sections render cleanly"
