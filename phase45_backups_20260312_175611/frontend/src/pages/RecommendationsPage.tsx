import { FormEvent, useMemo, useState } from "react";

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
    eyebrow: "Structured mode",
    title: "Build Your Night",
    subtitle:
      "Build the night by clicking exact option blocks that map directly to the recommendation engine.",
    bullets: [
      "Uses canonical values shared with the backend scorer.",
      "Best for controlled demos and predictable comparisons.",
      "Now includes deeper scoring transparency and validation support."
    ]
  },
  describe: {
    eyebrow: "Prompt mode",
    title: "Describe Your Night",
    subtitle:
      "Write the kind of night you want in natural language and let the system interpret it.",
    bullets: [
      "Best when the vibe matters more than form fields.",
      "Feels closer to a real assistant experience.",
      "Useful for testing natural-language intent parsing."
    ]
  },
  surprise: {
    eyebrow: "Exploration mode",
    title: "Surprise Me",
    subtitle: "Get recommendations quickly with minimal friction.",
    bullets: [
      "Fastest path to discovery.",
      "Uses your saved preferences when available.",
      "Good for novelty and low-effort browsing."
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

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [results, setResults] = useState<RecommendationItem[]>([]);

  const [buildForm, setBuildForm] = useState<BuildFormState>(initialBuildForm);
  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);

  const activeMeta = modeMeta[mode];

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

  async function runRequest(endpoint: string, payload: Record<string, unknown>) {
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
    } finally {
      setLoading(false);
    }
  }

  async function handleBuildSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest("/recommendations/build-your-night", {
      outing_type: buildForm.outing_type,
      budget: buildForm.budget || null,
      pace: buildForm.pace || null,
      social_context: buildForm.social_context || null,
      preferred_cuisines: buildForm.preferred_cuisines,
      drinks_focus: buildForm.drinks_focus,
      atmosphere: buildForm.atmosphere
    });
  }

  async function handleDescribeSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest("/recommendations/describe-your-night", {
      prompt: describeText.trim()
    });
  }

  async function handleSurprise() {
    await runRequest("/recommendations/surprise-me", {
      include_drinks: includeDrinks
    });
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
            Build Your Night
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
            Describe Your Night
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
            Surprise Me
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want novelty with almost no effort.
          </p>
        </button>
      </section>

      {mode === "build" ? (
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
        </Card>

        <Card
          title="Recommendation output"
          subtitle="Curated results from the active mode"
          actions={
            normalizedResults.length > 0 ? (
              <Badge tone="success">
                {normalizedResults.length} result{normalizedResults.length === 1 ? "" : "s"}
              </Badge>
            ) : (
              <Badge>Waiting</Badge>
            )
          }
        >
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
                  Use one of the validation presets, generate results, then open the
                  scoring detail on each recommendation card to inspect why it ranked.
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
