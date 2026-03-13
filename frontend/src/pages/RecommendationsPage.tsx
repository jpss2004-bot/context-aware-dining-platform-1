import { FormEvent, useEffect, useMemo, useState } from "react";

import RecommendationCard from "../components/dining/RecommendationCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RecommendationItem, RecommendationResponse } from "../types";

type Mode = "build" | "describe" | "surprise";
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

type BuildPreset = {
  label: string;
  description: string;
  state: BuildFormState;
};

type SavedRun = {
  id: string;
  createdAt: string;
  engineVersion: string;
  requestSummary: BuildFormState;
  resultCount: number;
  topResultName: string | null;
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
      "Now includes transparency, saved runs, and exportable diagnostics."
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

const buildPresets: BuildPreset[] = [
  {
    label: "Scenic date night",
    description: "Luxury, scenic, quieter, wine-friendly validation case.",
    state: {
      outing_type: "date-night",
      budget: "$$$",
      pace: "leisurely",
      social_context: "date",
      preferred_cuisines: ["wine", "seasonal"],
      atmosphere: ["scenic", "quiet", "refined"],
      drinks_focus: true
    }
  },
  {
    label: "Fast solo bite",
    description: "Budget, fast, solo validation case.",
    state: {
      outing_type: "quick-bite",
      budget: "$",
      pace: "fast",
      social_context: "solo",
      preferred_cuisines: ["asian"],
      atmosphere: ["casual"],
      drinks_focus: false
    }
  },
  {
    label: "Quiet coffee stop",
    description: "Solo coffee validation case.",
    state: {
      outing_type: "coffee-stop",
      budget: "$",
      pace: "slow",
      social_context: "solo",
      preferred_cuisines: ["coffee"],
      atmosphere: ["quiet"],
      drinks_focus: false
    }
  },
  {
    label: "Group drinks night",
    description: "Social drinks-forward validation case.",
    state: {
      outing_type: "drinks-night",
      budget: "$$",
      pace: "moderate",
      social_context: "group",
      preferred_cuisines: ["beer", "wine"],
      atmosphere: ["lively", "casual"],
      drinks_focus: true
    }
  }
];

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

function formatRunSummary(run: SavedRun): string {
  const parts: string[] = [];
  if (run.requestSummary.outing_type) parts.push(run.requestSummary.outing_type);
  if (run.requestSummary.budget) parts.push(run.requestSummary.budget);
  if (run.requestSummary.pace) parts.push(run.requestSummary.pace);
  if (run.requestSummary.social_context) parts.push(run.requestSummary.social_context);
  return parts.join(" • ");
}

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [results, setResults] = useState<RecommendationItem[]>([]);
  const [lastResponse, setLastResponse] = useState<RecommendationResponse | null>(null);
  const [savedRuns, setSavedRuns] = useState<SavedRun[]>([]);

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

  function resetBuildForm() {
    setBuildForm(initialBuildForm);
  }

  function applyPreset(preset: BuildPreset) {
    setMode("build");
    setBuildForm(preset.state);
  }

  function applySavedRun(run: SavedRun) {
    setMode("build");
    setBuildForm(run.requestSummary);
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
            <p className="navbar-eyebrow">Validation presets</p>
            <h3 style={{ marginTop: "0.35rem" }}>Apply a known test build</h3>
            <p className="muted" style={{ marginTop: 0 }}>
              These presets help you validate whether the engine is ranking the right types of venues.
            </p>
            <div style={{ display: "grid", gap: "0.85rem", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))" }}>
              {buildPresets.map((preset) => (
                <div
                  key={preset.label}
                  style={{
                    border: "1px solid rgba(148, 163, 184, 0.18)",
                    borderRadius: "1rem",
                    padding: "0.95rem",
                    background: "rgba(15, 23, 42, 0.4)"
                  }}
                >
                  <strong>{preset.label}</strong>
                  <p className="muted" style={{ marginTop: "0.45rem", marginBottom: "0.85rem" }}>
                    {preset.description}
                  </p>
                  <Button variant="secondary" onClick={() => applyPreset(preset)}>
                    Apply preset
                  </Button>
                </div>
              ))}
            </div>
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

          {mode === "build" ? (
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
                  Use a validation preset, generate results, inspect the scoring detail,
                  and export diagnostics when the run looks correct.
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
