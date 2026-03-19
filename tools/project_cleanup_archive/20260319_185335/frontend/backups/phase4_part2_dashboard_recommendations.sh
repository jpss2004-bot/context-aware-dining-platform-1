#!/bin/zsh
set -e

echo "applying phase 4 dashboard + recommendations refinement..."

cat > src/components/dining/RecommendationCard.tsx <<'EOF'
import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  explanation?: string;
  tags?: string[];
  ctaLabel?: string;
  onClick?: () => void;
};

function formatScore(score?: number) {
  if (score === undefined || score === null || Number.isNaN(score)) {
    return null;
  }

  return `${Math.round(score * 100)}% match`;
}

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  explanation,
  tags = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const scoreLabel = formatScore(score);

  return (
    <Card
      className="recommendation-card"
      title={title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : <Badge>Match pending</Badge>}
    >
      <div className="grid" style={{ gap: "0.8rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {explanation || "A recommendation is ready, but no explanation was provided yet."}
        </p>

        {tags.length > 0 ? (
          <div>
            {tags.map((tag) => (
              <Badge key={tag} tone="accent">
                {tag}
              </Badge>
            ))}
          </div>
        ) : (
          <div>
            <Badge>Context-aware</Badge>
            <Badge tone="accent">Dining fit</Badge>
          </div>
        )}

        {onClick ? (
          <div className="button-row">
            <Button variant="ghost" onClick={onClick}>
              {ctaLabel}
            </Button>
          </div>
        ) : null}
      </div>
    </Card>
  );
}
EOF

cat > src/pages/DashboardPage.tsx <<'EOF'
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";

const workflowSteps = [
  {
    title: "Refresh onboarding",
    description:
      "Keep cuisine, drink, atmosphere, and pace signals current so the engine has stronger preference context."
  },
  {
    title: "Review restaurants",
    description:
      "Inspect the seeded catalog and understand the venues the backend can draw from when creating recommendations."
  },
  {
    title: "Run recommendation modes",
    description:
      "Use structured, prompt-based, or surprise flows depending on how much control you want over the result."
  }
];

const quickPanels = [
  {
    title: "Recommendation modes",
    value: "3",
    subtitle: "Structured, prompt-based, and surprise flows ready to demo.",
    tone: "accent" as const
  },
  {
    title: "Profile readiness",
    value: "Live",
    subtitle: "Onboarding remains the signal backbone behind better recommendation quality.",
    tone: "success" as const
  },
  {
    title: "Experience memory",
    value: "Active",
    subtitle: "Saved dining logs can reinforce future personalization.",
    tone: "default" as const
  }
];

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "Guest";

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div className="grid" style={{ gap: "1rem" }}>
          <div>
            <p className="navbar-eyebrow">Product overview</p>
            <h1 className="page-title">Welcome back, {firstName}</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Your dining platform now has a stronger shell, clearer workflows, and
              a more product-like recommendation surface. Use this page as the
              control center for demos, testing, and iteration.
            </p>
          </div>

          <div>
            <Badge>Premium shell</Badge>
            <Badge tone="accent">Recommendation-led UX</Badge>
            <Badge tone="success">Backend connected</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Open recommendation studio</Button>
            </Link>
            <Link to="/restaurants">
              <Button variant="ghost">Browse restaurants</Button>
            </Link>
            <Link to="/onboarding">
              <Button variant="secondary">Update onboarding</Button>
            </Link>
          </div>
        </div>
      </section>

      <section className="grid grid-3">
        {quickPanels.map((panel) => (
          <Card
            key={panel.title}
            title={panel.title}
            subtitle={panel.subtitle}
            actions={<Badge tone={panel.tone}>{panel.title}</Badge>}
          >
            <p className="kpi">{panel.value}</p>
          </Card>
        ))}
      </section>

      <section className="grid grid-2">
        <Card
          title="Recommended workflow"
          subtitle="Best path for demos and end-to-end testing"
          actions={<Badge tone="accent">Suggested</Badge>}
        >
          <div className="list">
            {workflowSteps.map((step, index) => (
              <div className="item" key={step.title}>
                <p className="navbar-eyebrow" style={{ marginBottom: "0.35rem" }}>
                  Step {index + 1}
                </p>
                <strong>{step.title}</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {step.description}
                </p>
              </div>
            ))}
          </div>
        </Card>

        <Card
          title="What improved"
          subtitle="UI gains from the current iteration"
          actions={<Badge tone="success">Phase 4</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Cleaner shell</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                The sidebar, navbar, spacing, and cards now feel closer to a real
                SaaS product than a class prototype.
              </p>
            </div>

            <div className="item">
              <strong>Better recommendation surface</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                The recommendation workspace is more structured, readable, and ready
                for stronger outputs.
              </p>
            </div>

            <div className="item">
              <strong>Stronger visual system</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Shared components now support richer polish across onboarding,
                restaurants, experiences, login, and register pages.
              </p>
            </div>
          </div>

          <hr />

          <div className="button-row">
            <Link to="/experiences">
              <Button variant="ghost">Review experiences</Button>
            </Link>
            <Link to="/recommendations">
              <Button>Generate recommendations</Button>
            </Link>
          </div>
        </Card>
      </section>
    </div>
  );
}
EOF

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
      "Guide the engine with mood, group context, and outing details for more precise recommendations.",
    bullets: [
      "Best when you know the kind of night you want.",
      "Lets you steer atmosphere, pace, social context, and budget.",
      "Strong fit for repeatable demos."
    ]
  },
  describe: {
    eyebrow: "Prompt mode",
    title: "Describe Your Night",
    subtitle:
      "Write the kind of night you want in natural language and let the system interpret the intent.",
    bullets: [
      "Best when the vibe matters more than structured inputs.",
      "Feels more conversational and product-like.",
      "Useful for showcasing natural-language recommendation behavior."
    ]
  },
  surprise: {
    eyebrow: "Exploration mode",
    title: "Surprise Me",
    subtitle:
      "Get a recommendation quickly when you want novelty with minimal input.",
    bullets: [
      "Best for quick exploration and low-friction discovery.",
      "Minimal input, faster flow.",
      "Ideal when you want novelty without overthinking."
    ]
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
              <div className="grid grid-2">
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
              <div className="item">
                <strong>Low-friction discovery</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  This mode sends a fast request with minimal setup and is useful
                  when you want speed over detailed control.
                </p>
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
                  Try Build Your Night first for the clearest signal control, then
                  compare it to Describe Your Night to test how the engine handles
                  natural-language intent.
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

echo "running build..."
npm run build

echo "phase 4 part 2 complete"
