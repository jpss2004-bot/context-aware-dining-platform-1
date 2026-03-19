#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch9_build_flow_restructure_backup_$STAMP"

FILES=(
  "$FRONTEND_DIR/src/App.tsx"
  "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx"
  "$FRONTEND_DIR/src/pages/recommendations/BuildNightPage.tsx"
  "$FRONTEND_DIR/src/pages/recommendations/RecommendationResultsPage.tsx"
  "$FRONTEND_DIR/src/components/navigation/Navbar.tsx"
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
  "$BACKUP_DIR/frontend/src/pages/recommendations" \
  "$BACKUP_DIR/frontend/src/pages" \
  "$BACKUP_DIR/frontend/src/components/navigation" \
  "$BACKUP_DIR/frontend/src"

cp "$FRONTEND_DIR/src/App.tsx" \
  "$BACKUP_DIR/frontend/src/App.tsx"
cp "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/RecommendationsPage.tsx"
cp "$FRONTEND_DIR/src/pages/recommendations/BuildNightPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/recommendations/BuildNightPage.tsx"
cp "$FRONTEND_DIR/src/pages/recommendations/RecommendationResultsPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/recommendations/RecommendationResultsPage.tsx"
cp "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" \
  "$BACKUP_DIR/frontend/src/components/navigation/Navbar.tsx"
cp "$FRONTEND_DIR/src/styles.css" \
  "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch9_build_flow_restructure..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

app_path = Path("frontend/src/App.tsx")
recs_path = Path("frontend/src/pages/RecommendationsPage.tsx")
old_build_path = Path("frontend/src/pages/recommendations/BuildNightPage.tsx")
results_path = Path("frontend/src/pages/recommendations/RecommendationResultsPage.tsx")
navbar_path = Path("frontend/src/components/navigation/Navbar.tsx")
styles_path = Path("frontend/src/styles.css")

build_hub_path = Path("frontend/src/pages/recommendations/BuildNightPage.tsx")
preset_library_path = Path("frontend/src/pages/recommendations/SelectPresetPage.tsx")
create_preset_path = Path("frontend/src/pages/recommendations/CreatePresetPage.tsx")
guided_build_path = Path("frontend/src/pages/recommendations/GuidedBuildNightPage.tsx")

app_path.write_text("""import { Navigate, Route, Routes } from "react-router-dom";

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
import SavedPresetsPage from "./pages/SavedPresetsPage";
import BuildNightPage from "./pages/recommendations/BuildNightPage";
import CreatePresetPage from "./pages/recommendations/CreatePresetPage";
import DescribeNightPage from "./pages/recommendations/DescribeNightPage";
import GuidedBuildNightPage from "./pages/recommendations/GuidedBuildNightPage";
import RecommendationResultsPage from "./pages/recommendations/RecommendationResultsPage";
import SelectPresetPage from "./pages/recommendations/SelectPresetPage";
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
        path="/profile/presets"
        element={
          <ProtectedRoute>
            <Layout>
              <SavedPresetsPage />
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
        path="/recommendations/build/presets"
        element={
          <ProtectedRoute>
            <Layout>
              <SelectPresetPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations/build/presets/new"
        element={
          <ProtectedRoute>
            <Layout>
              <CreatePresetPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations/build/guide"
        element={
          <ProtectedRoute>
            <Layout>
              <GuidedBuildNightPage />
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
""")

recs_path.write_text("""import { useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";

export default function RecommendationsPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendations</p>
        <h1 className="page-title">Choose how you want to generate recommendations</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Start from a guided builder, natural language, or a surprise flow. The build path now has its own dedicated branching flow.
        </p>
      </section>

      <section className="grid grid-3">
        <Card
          title="Build a Night"
          subtitle="Choose a preset or go step by step to build your own night"
          actions={<Badge tone="accent">Structured</Badge>}
        >
          <div className="button-row">
            <Button onClick={() => navigate("/recommendations/build")}>Open build flow</Button>
          </div>
        </Card>

        <Card
          title="Describe the Night"
          subtitle="Use natural language to explain what kind of outing you want"
          actions={<Badge tone="success">Prompt-based</Badge>}
        >
          <div className="button-row">
            <Button onClick={() => navigate("/recommendations/describe")}>Describe a night</Button>
          </div>
        </Card>

        <Card
          title="Surprise Me"
          subtitle="Get recommendations quickly with very little input"
          actions={<Badge>Fastest</Badge>}
        >
          <div className="button-row">
            <Button onClick={() => navigate("/recommendations/surprise")}>Start surprise flow</Button>
          </div>
        </Card>
      </section>
    </div>
  );
}
""")

build_hub_path.write_text("""import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";

export default function BuildNightPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Build a night</p>
        <h1 className="page-title">How do you want to start?</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Either start from an existing preset or build your night step by step. Both paths end with recommendation results.
        </p>
      </section>

      <section className="grid grid-2">
        <Card
          title="Select a preset"
          subtitle="Browse available presets, apply one, and generate recommendations quickly"
          actions={<Badge tone="accent">Preset path</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Best when</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You already know a reusable dining pattern and want fast results.
              </p>
            </div>
          </div>
          <div className="button-row" style={{ marginTop: "1rem" }}>
            <Button onClick={() => navigate("/recommendations/build/presets")}>
              Select a preset
            </Button>
          </div>
        </Card>

        <Card
          title="Build your own night"
          subtitle="Move through a guided step-by-step builder, then save it as a preset if you want"
          actions={<Badge tone="success">Guided flow</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Best when</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You want to create a fresh configuration block by block before generating recommendations.
              </p>
            </div>
          </div>
          <div className="button-row" style={{ marginTop: "1rem" }}>
            <Button onClick={() => navigate("/recommendations/build/guide")}>
              Build your own night
            </Button>
          </div>
        </Card>
      </section>
    </div>
  );
}
""")

preset_library_path.write_text("""import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  applyPreset,
  listPresets,
  saveRecommendationResult,
  type PresetResponse,
  runBuildNight
} from "../../lib/recommendationFlow";

function summarizePreset(preset: PresetResponse): string[] {
  const payload = preset.selection_payload;
  const chips: string[] = [];

  if (payload.outing_type) chips.push(payload.outing_type);
  if (payload.budget) chips.push(payload.budget);
  if (payload.pace) chips.push(payload.pace);
  if (payload.social_context) chips.push(payload.social_context);
  if (payload.preferred_cuisines?.length) chips.push(...payload.preferred_cuisines.slice(0, 2));
  if (payload.atmosphere?.length) chips.push(...payload.atmosphere.slice(0, 2));

  return chips.slice(0, 6);
}

export default function SelectPresetPage() {
  const navigate = useNavigate();

  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [applyingPresetId, setApplyingPresetId] = useState<string | null>(null);
  const [error, setError] = useState("");

  const grouped = useMemo(
    () => ({
      system: presets.filter((preset) => preset.owner_type !== "user"),
      user: presets.filter((preset) => preset.owner_type === "user")
    }),
    [presets]
  );

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        setError("");
        const data = await listPresets();
        if (!cancelled) {
          setPresets(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load presets.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      cancelled = true;
    };
  }, []);

  async function handleGenerateFromPreset(preset: PresetResponse) {
    setApplyingPresetId(preset.preset_id);
    setError("");

    try {
      const applied = await applyPreset(preset.preset_id);
      const payload = applied.builder_payload;

      const response = await runBuildNight({
        outing_type: payload.outing_type || "casual-bite",
        budget: payload.budget || undefined,
        pace: payload.pace || undefined,
        social_context: payload.social_context || undefined,
        preferred_cuisines: payload.preferred_cuisines || [],
        atmosphere: payload.atmosphere || [],
        drinks_focus: Boolean(payload.drinks_focus),
        fast_food: Boolean(payload.fast_food),
        requires_dine_in: Boolean(payload.requires_dine_in),
        requires_takeout: Boolean(payload.requires_takeout),
        include_dish_hints: payload.include_dish_hints !== false
      });

      saveRecommendationResult({
        mode: "build",
        flowLabel: "Build Your Night",
        originPath: "/recommendations/build/presets",
        createdAt: new Date().toISOString(),
        request: applied.builder_payload,
        response,
        presetContext: {
          preset_id: applied.preset.preset_id,
          name: applied.preset.name,
          owner_type: applied.preset.owner_type,
          can_customize: applied.can_customize
        }
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate from preset.");
    } finally {
      setApplyingPresetId(null);
    }
  }

  function renderPresetCard(preset: PresetResponse) {
    const busy = applyingPresetId === preset.preset_id;

    return (
      <div key={preset.preset_id} className="item">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <strong>{preset.name}</strong>
            <p className="muted" style={{ margin: "0.35rem 0 0" }}>
              {preset.description || "No description provided."}
            </p>
            <div className="preset-chip-row" style={{ marginTop: "0.7rem" }}>
              {summarizePreset(preset).map((chip) => (
                <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                  {chip}
                </span>
              ))}
            </div>
          </div>

          <Badge tone={preset.owner_type === "user" ? "success" : "accent"}>
            {preset.owner_type === "user" ? "Your preset" : "System preset"}
          </Badge>
        </div>

        <div className="button-row" style={{ marginTop: "0.85rem" }}>
          <Button onClick={() => handleGenerateFromPreset(preset)} disabled={busy}>
            {busy ? "Generating..." : "Generate recommendations"}
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Preset library</p>
        <h1 className="page-title">Select your preset</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Choose from available presets, or create a new preset before generating recommendations.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Button variant="ghost" onClick={() => navigate("/recommendations/build")}>
          Back
        </Button>
        <Button onClick={() => navigate("/recommendations/build/presets/new")}>
          Create new preset
        </Button>
      </div>

      {loading ? (
        <Card title="Loading presets" subtitle="Fetching available presets." actions={<Badge>Loading</Badge>} />
      ) : (
        <section className="grid grid-2">
          <Card
            title="Your presets"
            subtitle="Saved reusable presets tied to your account"
            actions={<Badge tone="success">{grouped.user.length}</Badge>}
          >
            {grouped.user.length === 0 ? (
              <p className="muted" style={{ marginBottom: 0 }}>No user presets saved yet.</p>
            ) : (
              <div className="list">{grouped.user.map(renderPresetCard)}</div>
            )}
          </Card>

          <Card
            title="System presets"
            subtitle="Built-in starter presets"
            actions={<Badge tone="accent">{grouped.system.length}</Badge>}
          >
            {grouped.system.length === 0 ? (
              <p className="muted" style={{ marginBottom: 0 }}>No system presets available.</p>
            ) : (
              <div className="list">{grouped.system.map(renderPresetCard)}</div>
            )}
          </Card>
        </section>
      )}
    </div>
  );
}
""")

create_preset_path.write_text("""import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import { createPreset, type PresetSelectionPayload } from "../../lib/recommendationFlow";

type CreatePresetState = {
  name: string;
  description: string;
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
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

export default function CreatePresetPage() {
  const navigate = useNavigate();

  const [form, setForm] = useState<CreatePresetState>({
    name: "",
    description: "",
    outing_type: "casual-bite",
    budget: "$$",
    pace: "moderate",
    social_context: "friends"
  });

  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [saving, setSaving] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");

    if (!form.name.trim()) {
      setError("Preset name is required.");
      return;
    }

    setSaving(true);

    try {
      const payload: PresetSelectionPayload = {
        outing_type: form.outing_type,
        budget: form.budget || null,
        pace: form.pace || null,
        social_context: form.social_context || null,
        preferred_cuisines: [],
        atmosphere: [],
        drinks_focus: false,
        include_dish_hints: true
      };

      await createPreset({
        name: form.name.trim(),
        description: form.description.trim() || null,
        selection_payload: payload
      });

      setSuccess("Preset created successfully.");
      setTimeout(() => {
        navigate("/recommendations/build/presets");
      }, 700);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create preset.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Preset creation</p>
        <h1 className="page-title">Create a new preset</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Create a reusable preset first, then return to the preset library to generate recommendations from it.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <Card
        title="Preset setup"
        subtitle="Create a reusable starting point"
        actions={<Badge tone="accent">New preset</Badge>}
      >
        <form className="form" style={{ gap: "1rem" }} onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="preset_name">Preset name</label>
            <input
              id="preset_name"
              value={form.name}
              onChange={(e) => setForm((current) => ({ ...current, name: e.target.value }))}
              placeholder="Weekend group dinner"
            />
          </div>

          <div className="form-row">
            <label htmlFor="preset_description">Description</label>
            <textarea
              id="preset_description"
              rows={4}
              value={form.description}
              onChange={(e) => setForm((current) => ({ ...current, description: e.target.value }))}
              placeholder="What kind of outing is this preset designed for?"
            />
          </div>

          <div className="grid grid-2">
            <div className="form-row">
              <label htmlFor="outing_type">Outing type</label>
              <select
                id="outing_type"
                value={form.outing_type}
                onChange={(e) => setForm((current) => ({ ...current, outing_type: e.target.value }))}
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
                onChange={(e) => setForm((current) => ({ ...current, budget: e.target.value }))}
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
                onChange={(e) => setForm((current) => ({ ...current, pace: e.target.value }))}
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
                onChange={(e) => setForm((current) => ({ ...current, social_context: e.target.value }))}
              >
                {socialOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="button-row">
            <Button type="button" variant="ghost" onClick={() => navigate("/recommendations/build/presets")}>
              Back
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Create preset"}
            </Button>
          </div>
        </form>
      </Card>
    </div>
  );
}
""")

guided_build_path.write_text("""import { useMemo, useState } from "react";
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

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Top recommendations</p>
            <h1 className="page-title">Your top dining recommendations</h1>
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
              Back to previous step
            </Button>
            <Button
              onClick={() => {
                clearRecommendationResult();
                navigate("/recommendations");
              }}
            >
              Start again
            </Button>
          </div>
        </div>
      </section>

      <Card
        title="Recommendation summary"
        subtitle="Your top 10 ranked options from the current flow"
        actions={<Badge tone="accent">{stored.response.results.length} results</Badge>}
      >
        <p className="muted" style={{ marginBottom: 0 }}>
          The cards below show the highest-ranked results returned by the current recommendation request.
        </p>
      </Card>

      <section className="grid" style={{ gap: "1rem" }}>
        {stored.response.results.slice(0, 10).map((item, index) => (
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
            suggestedDishes={item.suggested_dishes}
            suggestedDrinks={item.suggested_drinks}
            activeEventMatches={item.active_event_matches}
            matchedSignals={item.matched_signals}
            penalizedSignals={item.penalized_signals}
            scoreBreakdown={item.score_breakdown}
          />
        ))}
      </section>
    </div>
  );
}
""")

navbar_path.write_text("""import { useLocation } from "react-router-dom";

type NavbarProps = {
  userName?: string;
};

function getPageContent(pathname: string) {
  if (pathname === "/dashboard") {
    return {
      eyebrow: "Home",
      title: "Your SAVR dashboard",
      subtitle:
        "Review your saved dining preferences, check profile readiness, and continue into recommendations."
    };
  }

  if (pathname === "/profile") {
    return {
      eyebrow: "Profile",
      title: "Your SAVR profile",
      subtitle:
        "Review your account information, saved preferences, and the signals shaping your dining recommendations."
    };
  }

  if (pathname === "/profile/preferences") {
    return {
      eyebrow: "Profile editing",
      title: "Update your dining preferences",
      subtitle:
        "Refine the taste, pace, atmosphere, and dining memory signals that guide SAVR."
    };
  }

  if (pathname === "/profile/presets") {
    return {
      eyebrow: "Profile · Saved presets",
      title: "Your saved presets",
      subtitle:
        "Review presets owned by your account, inspect recent dining history, and jump back into preset editing flows."
    };
  }

  if (pathname === "/onboarding") {
    return {
      eyebrow: "Onboarding",
      title: "Set up your SAVR profile",
      subtitle:
        "Complete your initial dining profile so SAVR can begin tailoring recommendations."
    };
  }

  if (pathname === "/recommendations") {
    return {
      eyebrow: "Recommendations",
      title: "Find your next dining match",
      subtitle:
        "Choose a structured recommendation flow and move into a dedicated page for that mode."
    };
  }

  if (pathname === "/recommendations/build") {
    return {
      eyebrow: "Recommendations · Build",
      title: "Build a night",
      subtitle:
        "Choose whether to start from a preset or build your own night step by step."
    };
  }

  if (pathname === "/recommendations/build/presets") {
    return {
      eyebrow: "Build flow · Presets",
      title: "Select your preset",
      subtitle:
        "Choose an available preset or create a new one before generating recommendations."
    };
  }

  if (pathname === "/recommendations/build/presets/new") {
    return {
      eyebrow: "Build flow · New preset",
      title: "Create a preset",
      subtitle:
        "Create a reusable preset that can later generate recommendations in one click."
    };
  }

  if (pathname === "/recommendations/build/guide") {
    return {
      eyebrow: "Build flow · Guided builder",
      title: "Build your own night",
      subtitle:
        "Move block by block through the build flow, then save as a preset or generate recommendations."
    };
  }

  if (pathname === "/recommendations/describe") {
    return {
      eyebrow: "Recommendations · Describe",
      title: "Describe the Night",
      subtitle:
        "Use natural language to describe the dining experience you want, then move into a dedicated results page."
    };
  }

  if (pathname === "/recommendations/surprise") {
    return {
      eyebrow: "Recommendations · Surprise",
      title: "Surprise Me",
      subtitle:
        "Use the fastest recommendation path with minimal input and separate output."
    };
  }

  if (pathname === "/recommendations/results") {
    return {
      eyebrow: "Recommendations · Results",
      title: "Top recommendations",
      subtitle:
        "Review the top ranked dining matches generated by the current recommendation flow."
    };
  }

  if (pathname === "/restaurants") {
    return {
      eyebrow: "Restaurants",
      title: "Browse available venues",
      subtitle:
        "Review the restaurant catalog and choose a place to inspect in more detail."
    };
  }

  if (pathname.startsWith("/restaurants/")) {
    return {
      eyebrow: "Restaurant detail",
      title: "Venue overview",
      subtitle:
        "Inspect menu signals, atmosphere, and restaurant details in a dedicated venue page."
    };
  }

  if (pathname === "/experiences") {
    return {
      eyebrow: "Experiences",
      title: "Your dining history",
      subtitle:
        "Review the dining moments you have already saved and use them to guide future recommendations."
    };
  }

  if (pathname === "/experiences/new") {
    return {
      eyebrow: "New experience",
      title: "Log a dining experience",
      subtitle:
        "Capture a visit in its own dedicated page so SAVR can learn from what actually worked."
    };
  }

  return {
    eyebrow: "Workspace",
    title: "SAVR",
    subtitle: "A structured dining discovery workspace designed for real user testing."
  };
}

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();
  const content = getPageContent(location.pathname);

  const today = new Date().toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric"
  });

  return (
    <header className="app-navbar">
      <div className="navbar-copy">
        <p className="navbar-eyebrow">{content.eyebrow}</p>
        <h2 className="navbar-title">{content.title}</h2>
        <p className="navbar-subtitle">{content.subtitle}</p>
      </div>

      <div className="navbar-right">
        <div className="navbar-date-chip">{today}</div>

        <div className="navbar-meta-card">
          <span className="status-dot" />
          <div>
            <p className="navbar-meta-label">Signed in</p>
            <strong>{userName || "Guest user"}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
""")

styles = styles_path.read_text()
extra = """

.build-path-card {
  min-height: 220px;
}
"""
if ".build-path-card" not in styles:
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
echo "Patch 9 applied successfully."
echo "Files changed:"
echo " - frontend/src/App.tsx"
echo " - frontend/src/pages/RecommendationsPage.tsx"
echo " - frontend/src/pages/recommendations/BuildNightPage.tsx"
echo " - frontend/src/pages/recommendations/SelectPresetPage.tsx"
echo " - frontend/src/pages/recommendations/CreatePresetPage.tsx"
echo " - frontend/src/pages/recommendations/GuidedBuildNightPage.tsx"
echo " - frontend/src/pages/recommendations/RecommendationResultsPage.tsx"
echo " - frontend/src/components/navigation/Navbar.tsx"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) run frontend and backend"
echo "2) open /recommendations"
echo "3) click Build a Night"
echo "4) confirm /recommendations/build now asks preset vs build-your-own"
echo "5) confirm /recommendations/build/presets shows presets and a create-new-preset button"
echo "6) confirm /recommendations/build/presets/new creates a preset and returns to preset library"
echo "7) confirm /recommendations/build/guide is step-by-step with a progress bar"
echo "8) confirm final step lets you save as preset and generate recommendations"
echo "9) confirm /recommendations/results shows top 10 recommendations"
