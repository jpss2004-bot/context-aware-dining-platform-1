#!/usr/bin/env bash
set -euo pipefail

PATCH_NAME="patch7_flow_pages_fix"
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
  restaurant_id?: number;
  restaurant_name?: string;
  score?: number;
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
  mode?: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: Record<string, unknown>;
  results?: RecommendationItem[];
};

export type StoredRecommendationResult = {
  mode: "build" | "describe" | "surprise";
  createdAt: string;
  request?: unknown;
  response: RecommendationResponse;
};

export const RESULT_STORAGE_KEY = "savr:recommendation-flow-result:v2";

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
  budget: string;
  pace: string;
  social_context: string;
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
    subtitle: "Step-by-step flow",
    description:
      "Answer structured questions one page at a time so the experience feels guided instead of cluttered.",
    cta: "Open build flow",
    path: "/recommendations/build"
  },
  {
    key: "describe",
    title: "Describe the Night",
    subtitle: "Natural language flow",
    description:
      "Write the kind of dining experience you want in your own words, then generate recommendations on a separate results page.",
    cta: "Open describe flow",
    path: "/recommendations/describe"
  },
  {
    key: "surprise",
    title: "Surprise Me",
    subtitle: "Fast discovery flow",
    description:
      "Skip the long form and go directly into a faster recommendation path with minimal input and a dedicated results page.",
    cta: "Open surprise flow",
    path: "/recommendations/surprise"
  }
] as const;

export default function RecommendationsPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendation flow</p>
        <h1 className="page-title">Choose how you want to generate your night</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Pick one clear path, move into its own page, then view the output on a dedicated results screen.
        </p>
      </section>

      <section className="grid grid-3">
        {options.map((option) => (
          <Card
            key={option.key}
            title={option.title}
            subtitle={option.description}
            actions={<Badge tone="accent">{option.subtitle}</Badge>}
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
import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
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

const budgetOptions = ["$", "$$", "$$$"];
const paceOptions = ["fast", "moderate", "slow", "leisurely"];
const socialOptions = ["solo", "friends", "group", "date"];
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

export default function BuildNightPage() {
  const navigate = useNavigate();
  const [form, setForm] = useState<BuildFormState>(initialState);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");

    try {
      const response = await runBuildNight(form);

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

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Build flow</p>
            <h1 className="page-title">Build Your Night</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              This page is focused only on the build flow. Results appear on the next page after submit.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to recommendation hub
            </Button>
          </div>
        </div>
      </section>

      <form onSubmit={handleSubmit} className="grid grid-2" style={{ alignItems: "start" }}>
        <Card
          title="Night setup"
          subtitle="Fill the key signals, then generate the results page"
          actions={<Badge tone="accent">Structured flow</Badge>}
        >
          {error ? <div className="error">{error}</div> : null}

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
                    {option}
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
                    {option}
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
                    {option}
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
            </div>
          </div>
        </Card>

        <Card
          title="Summary"
          subtitle="Only the information needed before you submit"
          actions={<Badge>Focused page</Badge>}
        >
          <div className="list">
            <div className="item"><strong>Outing type</strong><p className="muted">{form.outing_type}</p></div>
            <div className="item"><strong>Budget</strong><p className="muted">{form.budget}</p></div>
            <div className="item"><strong>Pace</strong><p className="muted">{form.pace}</p></div>
            <div className="item"><strong>Social context</strong><p className="muted">{form.social_context}</p></div>
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
              Write the vibe you want here, then see the recommendations on the next page.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to recommendation hub
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
              Fastest path to a new dining suggestion without making the user scroll through a large page.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to recommendation hub
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
  loadRecommendationResult
} from "../../lib/recommendationFlow";

function normalizeResults(response: {
  results?: Array<{
    restaurant_id?: number;
    restaurant_name?: string;
    score?: number;
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
  }>;
}) {
  return (response.results || []).map((item, index) => ({
    id: `${item.restaurant_id ?? "restaurant"}-${index}`,
    title: item.restaurant_name || `Recommendation ${index + 1}`,
    restaurantName: item.restaurant_name || "Dining recommendation",
    rank: item.rank,
    fitLabel: item.fit_label,
    score: item.score,
    explanation:
      item.explanation ||
      (item.reasons && item.reasons.length > 0 ? item.reasons.join(" • ") : "No explanation provided."),
    confidenceLevel: item.confidence_level,
    matchedSignals: item.matched_signals || [],
    penalizedSignals: item.penalized_signals || [],
    scoreBreakdown: item.score_breakdown || [],
    tags: [
      ...(item.suggested_dishes || []),
      ...(item.suggested_drinks || []),
      ...(item.active_event_matches || [])
    ].slice(0, 6)
  }));
}

export default function RecommendationResultsPage() {
  const navigate = useNavigate();
  const stored = useMemo(() => loadRecommendationResult(), []);
  const results = normalizeResults(stored?.response || {});

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
            <h1 className="page-title">Your generated results</h1>
            <p className="muted" style={{ marginBottom: 0 }}>
              Flow used: <strong>{stored.mode}</strong>
            </p>
          </div>

          <div className="button-row">
            <Button variant="secondary" onClick={() => navigate("/recommendations")}>
              Start another flow
            </Button>
            <Button
              variant="ghost"
              onClick={() => {
                clearRecommendationResult();
                navigate("/recommendations");
              }}
            >
              Clear results
            </Button>
          </div>
        </div>
      </section>

      <section className="grid grid-2">
        <Card
          title="Run summary"
          subtitle="The request that generated these results"
          actions={<Badge tone="accent">{stored.response.results?.length || 0} results</Badge>}
        >
          <div className="item">
            <strong>Mode</strong>
            <p className="muted">{stored.mode}</p>
          </div>

          <div className="item">
            <strong>Generated at</strong>
            <p className="muted">{new Date(stored.createdAt).toLocaleString()}</p>
          </div>

          <div className="item">
            <strong>Request payload</strong>
            <pre
              style={{
                margin: "0.75rem 0 0",
                padding: "0.85rem",
                borderRadius: "0.85rem",
                overflowX: "auto",
                background: "rgba(15, 23, 42, 0.35)",
                border: "1px solid rgba(148, 163, 184, 0.15)"
              }}
            >
{JSON.stringify(stored.request ?? {}, null, 2)}
            </pre>
          </div>
        </Card>

        <Card
          title="System metadata"
          subtitle="Useful backend response details"
          actions={<Badge>{stored.response.engine_version || "No engine label"}</Badge>}
        >
          <div className="item">
            <strong>Generated timestamp</strong>
            <p className="muted">{stored.response.generated_at || "Not provided"}</p>
          </div>

          <div className="item">
            <strong>Backend mode</strong>
            <p className="muted">{stored.response.mode || "Not provided"}</p>
          </div>

          <div className="item">
            <strong>Request summary</strong>
            <pre
              style={{
                margin: "0.75rem 0 0",
                padding: "0.85rem",
                borderRadius: "0.85rem",
                overflowX: "auto",
                background: "rgba(15, 23, 42, 0.35)",
                border: "1px solid rgba(148, 163, 184, 0.15)"
              }}
            >
{JSON.stringify(stored.response.request_summary ?? {}, null, 2)}
            </pre>
          </div>
        </Card>
      </section>

      <section className="grid" style={{ gap: "1rem" }}>
        {results.length === 0 ? (
          <Card
            title="No recommendations returned"
            subtitle="The request completed, but the backend did not return result cards."
            actions={<Badge>0 results</Badge>}
          >
            <pre
              style={{
                margin: 0,
                padding: "0.85rem",
                borderRadius: "0.85rem",
                overflowX: "auto",
                background: "rgba(15, 23, 42, 0.35)",
                border: "1px solid rgba(148, 163, 184, 0.15)"
              }}
            >
{JSON.stringify(stored.response, null, 2)}
            </pre>
          </Card>
        ) : (
          results.map((item) => (
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
          ))
        )}
      </section>
    </div>
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
echo "Patch 7 applied successfully."
echo "Next steps:"
echo "1) cd frontend"
echo "2) npm run dev"
echo "3) test /recommendations"
echo "4) click Build / Describe / Surprise"
echo "5) submit and confirm redirect to /recommendations/results"
