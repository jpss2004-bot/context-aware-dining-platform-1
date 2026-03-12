#!/bin/zsh
set -e

echo "writing RecommendationsPage..."

cat > src/pages/RecommendationsPage.tsx <<'EOF'
import { FormEvent, useMemo, useState } from "react";

import RecommendationCard from "../components/dining/RecommendationCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";

type RecommendationResponse = {
  recommendations?: Array<Record<string, any>>;
  message?: string;
};

type Mode = "build" | "describe" | "surprise";

const modeMeta: Record<
  Mode,
  { eyebrow: string; title: string; subtitle: string }
> = {
  build: {
    eyebrow: "Structured mode",
    title: "Build Your Night",
    subtitle:
      "Guide the engine with mood, group context, and outing details for more precise recommendations."
  },
  describe: {
    eyebrow: "Prompt mode",
    title: "Describe Your Night",
    subtitle:
      "Write the kind of night you want in natural language and let the system interpret the intent."
  },
  surprise: {
    eyebrow: "Exploration mode",
    title: "Surprise Me",
    subtitle:
      "Get a recommendation quickly when you want novelty with minimal input."
  }
};

function normalizeTags(item: Record<string, any>) {
  const tags: string[] = [];

  if (item.atmosphere) tags.push(String(item.atmosphere));
  if (item.social_style) tags.push(String(item.social_style));
  if (item.pace) tags.push(String(item.pace));
  if (item.price_tier) tags.push(String(item.price_tier));
  if (item.cuisine) tags.push(String(item.cuisine));

  return tags.slice(0, 4);
}

function normalizeRecommendation(item: Record<string, any>, index: number) {
  return {
    id: item.id ?? item.restaurant_id ?? index,
    title:
      item.title ??
      item.restaurant_name ??
      item.name ??
      `Recommendation ${index + 1}`,
    restaurantName:
      item.restaurant_name ?? item.name ?? item.restaurant ?? undefined,
    explanation:
      item.explanation ??
      item.reason ??
      item.description ??
      "A recommendation was returned, but no explanation was provided.",
    score:
      typeof item.score === "number"
        ? item.score
        : typeof item.match_score === "number"
          ? item.match_score
          : undefined,
    tags: normalizeTags(item)
  };
}

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [results, setResults] = useState<Array<Record<string, any>>>([]);

  const [buildForm, setBuildForm] = useState({
    occasion: "",
    social_context: "",
    desired_atmosphere: "",
    dining_pace: "",
    price_tier: ""
  });

  const [describeText, setDescribeText] = useState("");

  const activeMeta = modeMeta[mode];

  const normalizedResults = useMemo(
    () => results.map((item, index) => normalizeRecommendation(item, index)),
    [results]
  );

  async function runRequest(endpoint: string, payload?: Record<string, any>) {
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = (await apiRequest(endpoint, {
        method: "POST",
        body: payload ? JSON.stringify(payload) : undefined
      })) as RecommendationResponse;

      const recs = Array.isArray(data.recommendations)
        ? data.recommendations
        : [];

      setResults(recs);
      setSuccess(
        recs.length > 0
          ? `Generated ${recs.length} recommendation${recs.length === 1 ? "" : "s"}.`
          : data.message || "Request completed, but no recommendations were returned."
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
    await runRequest("/recommendations/build-your-night", buildForm);
  }

  async function handleDescribeSubmit(event: FormEvent) {
    event.preventDefault();
    await runRequest("/recommendations/describe-your-night", {
      prompt: describeText
    });
  }

  async function handleSurprise() {
    await runRequest("/recommendations/surprise-me");
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
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

      <section className="grid grid-2">
        <Card
          title={activeMeta.title}
          subtitle={activeMeta.subtitle}
          actions={<Badge tone="accent">{activeMeta.eyebrow}</Badge>}
        >
          {error ? <div className="error">{error}</div> : null}
          {success ? <div className="success">{success}</div> : null}

          {mode === "build" ? (
            <form className="form" onSubmit={handleBuildSubmit}>
              <div className="form-row">
                <label htmlFor="occasion">Occasion</label>
                <input
                  id="occasion"
                  value={buildForm.occasion}
                  onChange={(e) =>
                    setBuildForm((prev) => ({ ...prev, occasion: e.target.value }))
                  }
                  placeholder="Date night, group dinner, casual bite..."
                />
              </div>

              <div className="form-row">
                <label htmlFor="social_context">Social context</label>
                <input
                  id="social_context"
                  value={buildForm.social_context}
                  onChange={(e) =>
                    setBuildForm((prev) => ({
                      ...prev,
                      social_context: e.target.value
                    }))
                  }
                  placeholder="Solo, friends, partner, family..."
                />
              </div>

              <div className="form-row">
                <label htmlFor="desired_atmosphere">Desired atmosphere</label>
                <input
                  id="desired_atmosphere"
                  value={buildForm.desired_atmosphere}
                  onChange={(e) =>
                    setBuildForm((prev) => ({
                      ...prev,
                      desired_atmosphere: e.target.value
                    }))
                  }
                  placeholder="Cozy, lively, upscale, quiet..."
                />
              </div>

              <div className="grid grid-2">
                <div className="form-row">
                  <label htmlFor="dining_pace">Dining pace</label>
                  <input
                    id="dining_pace"
                    value={buildForm.dining_pace}
                    onChange={(e) =>
                      setBuildForm((prev) => ({
                        ...prev,
                        dining_pace: e.target.value
                      }))
                    }
                    placeholder="Quick, relaxed, long-form..."
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="price_tier">Price tier</label>
                  <input
                    id="price_tier"
                    value={buildForm.price_tier}
                    onChange={(e) =>
                      setBuildForm((prev) => ({
                        ...prev,
                        price_tier: e.target.value
                      }))
                    }
                    placeholder="$, $$, $$$"
                  />
                </div>
              </div>

              <div className="button-row">
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
                  placeholder="I want a cozy dinner spot with good cocktails, relaxed pacing, and food that feels memorable without being too formal..."
                />
              </div>

              <div className="button-row">
                <Button type="submit" disabled={loading}>
                  {loading ? "Interpreting..." : "Interpret and recommend"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "surprise" ? (
            <div className="form">
              <p className="muted" style={{ marginTop: 0 }}>
                This mode sends a fast request for a recommendation without asking
                for much input. It is ideal when you want to discover something
                quickly.
              </p>

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
            <div className="item">
              <strong>No recommendations yet</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Run one of the recommendation modes to populate this panel with
                curated dining suggestions.
              </p>
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

echo "RecommendationsPage written"
