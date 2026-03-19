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

  return chips.slice(0, 6);
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
        drinks_focus: form.drinks_focus
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
              Apply a preset, review it, customize it safely, save or update your own preset, and generate results on the next page.
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
              <strong>Drinks focus</strong>
              <p className="muted">{form.drinks_focus ? "Yes" : "No"}</p>
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
