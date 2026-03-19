import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  createPreset,
  runBuildNight,
  saveRecommendationResult,
  type PresetSelectionPayload
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

type StepDefinition = {
  key: "outing_type" | "budget" | "pace" | "social_context" | "preferred_cuisines" | "atmosphere" | "finish";
  title: string;
  description: string;
  selectionLabel: string;
  optional?: boolean;
};

const steps: StepDefinition[] = [
  {
    key: "outing_type",
    title: "What kind of night are you building?",
    description: "Choose the overall dining scenario first.",
    selectionLabel: "Choose one"
  },
  {
    key: "budget",
    title: "What budget fits tonight?",
    description: "Choose the spending level that feels right.",
    selectionLabel: "Choose one",
    optional: true
  },
  {
    key: "pace",
    title: "How should the night feel?",
    description: "Choose how fast or relaxed the dining pace should be.",
    selectionLabel: "Choose one",
    optional: true
  },
  {
    key: "social_context",
    title: "Who is this for?",
    description: "Choose the main social context for this outing.",
    selectionLabel: "Choose one",
    optional: true
  },
  {
    key: "preferred_cuisines",
    title: "What cuisines should SAVR prioritize?",
    description: "Choose one or more cuisines for this build.",
    selectionLabel: "Choose one or more",
    optional: true
  },
  {
    key: "atmosphere",
    title: "What atmosphere are you looking for?",
    description: "Choose one or more vibe signals for this night.",
    selectionLabel: "Choose one or more",
    optional: true
  },
  {
    key: "finish",
    title: "Review and generate",
    description: "Save this build as a preset if you want, then generate recommendations.",
    selectionLabel: "Final step"
  }
];

const outingOptions = [
  "casual-bite",
  "date-night",
  "group-dinner",
  "drinks-night",
  "quick-bite",
  "coffee-stop",
  "special-occasion"
];

const budgetOptions = ["$", "$$", "$$$"];
const paceOptions = ["fast", "moderate", "slow", "leisurely"];
const socialOptions = ["solo", "friends", "group", "date"];
const cuisineOptions = ["italian", "mexican", "japanese", "seafood", "cafe", "pub fare", "fast food"];
const atmosphereOptions = ["cozy", "casual", "upscale", "family friendly", "live music", "trivia"];

const initialState: BuildFormState = {
  outing_type: "casual-bite",
  budget: "",
  pace: "",
  social_context: "",
  preferred_cuisines: [],
  atmosphere: [],
  drinks_focus: false
};

function toggleArrayValue(values: string[], value: string) {
  return values.includes(value)
    ? values.filter((item) => item !== value)
    : [...values, value];
}

function toPayload(form: BuildFormState): PresetSelectionPayload {
  return {
    outing_type: form.outing_type,
    budget: form.budget || null,
    pace: form.pace || null,
    social_context: form.social_context || null,
    preferred_cuisines: form.preferred_cuisines,
    atmosphere: form.atmosphere,
    drinks_focus: form.drinks_focus,
    include_dish_hints: true
  };
}

export default function GuidedBuildNightPage() {
  const navigate = useNavigate();

  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [form, setForm] = useState<BuildFormState>(initialState);
  const [presetName, setPresetName] = useState("");
  const [presetDescription, setPresetDescription] = useState("");
  const [savingPreset, setSavingPreset] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const currentStep = steps[currentStepIndex];
  const isFinalStep = currentStep.key === "finish";
  const progressPercent = Math.round(((currentStepIndex + 1) / steps.length) * 100);

  const summary = useMemo(
    () => [
      { label: "Outing type", value: form.outing_type || "Not set" },
      { label: "Budget", value: form.budget || "No preference" },
      { label: "Pace", value: form.pace || "No preference" },
      { label: "Social context", value: form.social_context || "No preference" },
      {
        label: "Cuisines",
        value: form.preferred_cuisines.length ? form.preferred_cuisines.join(", ") : "None selected"
      },
      {
        label: "Atmosphere",
        value: form.atmosphere.length ? form.atmosphere.join(", ") : "None selected"
      }
    ],
    [form]
  );

  function goNext() {
    setError("");
    setCurrentStepIndex((current) => Math.min(current + 1, steps.length - 1));
  }

  function goBack() {
    setError("");
    setCurrentStepIndex((current) => Math.max(current - 1, 0));
  }

  async function handleSavePreset() {
    if (!presetName.trim()) {
      setError("Preset name is required.");
      return;
    }

    setSavingPreset(true);
    setError("");
    setSuccess("");

    try {
      await createPreset({
        name: presetName.trim(),
        description: presetDescription.trim() || null,
        selection_payload: toPayload(form)
      });

      setSuccess("Preset saved successfully.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save preset.");
    } finally {
      setSavingPreset(false);
    }
  }

  async function handleGenerate() {
    setGenerating(true);
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
        include_dish_hints: true
      });

      saveRecommendationResult({
        mode: "build",
        flowLabel: "Build Your Night",
        originPath: "/recommendations/build/guide",
        createdAt: new Date().toISOString(),
        request: form,
        response,
        presetContext: null
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate recommendations.");
    } finally {
      setGenerating(false);
    }
  }

  function renderOptionButton(
    label: string,
    selected: boolean,
    onClick: () => void
  ) {
    return (
      <button
        type="button"
        className={selected ? "single-onboarding-choice single-onboarding-choice--active" : "single-onboarding-choice"}
        onClick={onClick}
      >
        <strong>{label}</strong>
      </button>
    );
  }

  return (
    <div className="single-onboarding-shell">
      <div className="single-onboarding-card">
        <div className="single-onboarding-header">
          <p className="single-onboarding-eyebrow">Build your own night</p>
          <h1 className="single-onboarding-title">Build your night step by step</h1>
          <p className="single-onboarding-subtitle">
            Move block by block, create a clear dining setup, save it as a preset if you want, then generate recommendations.
          </p>

          <div className="single-onboarding-progress-meta">
            <span>Step {currentStepIndex + 1} of {steps.length}</span>
            <strong>{progressPercent}%</strong>
          </div>

          <div className="single-onboarding-progress-track" aria-hidden="true">
            <div className="single-onboarding-progress-fill" style={{ width: `${progressPercent}%` }} />
          </div>
        </div>

        {error ? <div className="error">{error}</div> : null}
        {success ? <div className="success">{success}</div> : null}

        <section className="single-onboarding-stage">
          <div className="single-onboarding-stage-copy">
            <p className="single-onboarding-step-tag">{currentStep.selectionLabel}</p>
            <h2>{currentStep.title}</h2>
            <p>{currentStep.description}</p>
          </div>

          {!isFinalStep ? (
            <>
              {currentStep.key === "outing_type" ? (
                <div className="single-onboarding-choice-grid">
                  {outingOptions.map((option) =>
                    renderOptionButton(option, form.outing_type === option, () =>
                      setForm((current) => ({ ...current, outing_type: option }))
                    )
                  )}
                </div>
              ) : null}

              {currentStep.key === "budget" ? (
                <div className="single-onboarding-choice-grid">
                  {budgetOptions.map((option) =>
                    renderOptionButton(option, form.budget === option, () =>
                      setForm((current) => ({ ...current, budget: current.budget === option ? "" : option }))
                    )
                  )}
                </div>
              ) : null}

              {currentStep.key === "pace" ? (
                <div className="single-onboarding-choice-grid">
                  {paceOptions.map((option) =>
                    renderOptionButton(option, form.pace === option, () =>
                      setForm((current) => ({ ...current, pace: current.pace === option ? "" : option }))
                    )
                  )}
                </div>
              ) : null}

              {currentStep.key === "social_context" ? (
                <div className="single-onboarding-choice-grid">
                  {socialOptions.map((option) =>
                    renderOptionButton(option, form.social_context === option, () =>
                      setForm((current) => ({
                        ...current,
                        social_context: current.social_context === option ? "" : option
                      }))
                    )
                  )}
                </div>
              ) : null}

              {currentStep.key === "preferred_cuisines" ? (
                <div className="single-onboarding-choice-grid">
                  {cuisineOptions.map((option) =>
                    renderOptionButton(option, form.preferred_cuisines.includes(option), () =>
                      setForm((current) => ({
                        ...current,
                        preferred_cuisines: toggleArrayValue(current.preferred_cuisines, option)
                      }))
                    )
                  )}
                </div>
              ) : null}

              {currentStep.key === "atmosphere" ? (
                <div className="single-onboarding-choice-grid">
                  {atmosphereOptions.map((option) =>
                    renderOptionButton(option, form.atmosphere.includes(option), () =>
                      setForm((current) => ({
                        ...current,
                        atmosphere: toggleArrayValue(current.atmosphere, option)
                      }))
                    )
                  )}
                </div>
              ) : null}
            </>
          ) : (
            <div className="grid" style={{ gap: "1rem" }}>
              <div className="single-onboarding-summary-list">
                {summary.map((item) => (
                  <div key={item.label} className="item">
                    <strong>{item.label}</strong>
                    <p className="muted" style={{ marginBottom: 0 }}>{item.value}</p>
                  </div>
                ))}
              </div>

              <Card
                title="Save as preset"
                subtitle="Optional, but useful if you want to reuse this build later"
                actions={<Badge tone="accent">Optional</Badge>}
              >
                <div className="form" style={{ gap: "1rem" }}>
                  <div className="form-row">
                    <label htmlFor="preset_name">Preset name</label>
                    <input
                      id="preset_name"
                      value={presetName}
                      onChange={(e) => setPresetName(e.target.value)}
                      placeholder="Friday date-night build"
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="preset_description">Description</label>
                    <textarea
                      id="preset_description"
                      rows={4}
                      value={presetDescription}
                      onChange={(e) => setPresetDescription(e.target.value)}
                      placeholder="Describe when this build is useful."
                    />
                  </div>

                  <div className="button-row">
                    <Button type="button" variant="secondary" onClick={handleSavePreset} disabled={savingPreset}>
                      {savingPreset ? "Saving..." : "Save as preset"}
                    </Button>
                  </div>
                </div>
              </Card>
            </div>
          )}
        </section>

        <div className="single-onboarding-actions">
          <Button type="button" variant="ghost" onClick={goBack} disabled={currentStepIndex === 0 || generating}>
            Back
          </Button>

          <div className="button-row">
            {!isFinalStep && currentStep.optional ? (
              <Button type="button" variant="secondary" onClick={goNext} disabled={generating}>
                Skip for now
              </Button>
            ) : null}

            {!isFinalStep ? (
              <Button type="button" onClick={goNext} disabled={generating}>
                Continue
              </Button>
            ) : (
              <Button type="button" onClick={handleGenerate} disabled={generating}>
                {generating ? "Generating..." : "Generate recommendations"}
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
