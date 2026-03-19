#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch10_saved_presets_scroll_sidebar_backup_$STAMP"

FILES=(
  "$FRONTEND_DIR/src/App.tsx"
  "$FRONTEND_DIR/src/pages/SavedPresetsPage.tsx"
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
  "$BACKUP_DIR/frontend/src/components/navigation" \
  "$BACKUP_DIR/frontend/src/components/layout" \
  "$BACKUP_DIR/frontend/src/pages" \
  "$BACKUP_DIR/frontend/src"

cp "$FRONTEND_DIR/src/App.tsx" \
  "$BACKUP_DIR/frontend/src/App.tsx"
cp "$FRONTEND_DIR/src/pages/SavedPresetsPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/SavedPresetsPage.tsx"
cp "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" \
  "$BACKUP_DIR/frontend/src/components/navigation/Sidebar.tsx"
cp "$FRONTEND_DIR/src/styles.css" \
  "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch10_saved_presets_scroll_sidebar..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

app_path = Path("frontend/src/App.tsx")
saved_presets_path = Path("frontend/src/pages/SavedPresetsPage.tsx")
sidebar_path = Path("frontend/src/components/navigation/Sidebar.tsx")
scroll_to_top_path = Path("frontend/src/components/layout/ScrollToTop.tsx")
styles_path = Path("frontend/src/styles.css")

app_path.write_text("""import { Navigate, Route, Routes } from "react-router-dom";

import Layout from "./components/layout/Layout";
import ProtectedRoute from "./components/layout/ProtectedRoute";
import ScrollToTop from "./components/layout/ScrollToTop";
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
    <>
      <ScrollToTop />
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
    </>
  );
}
""")

scroll_to_top_path.write_text("""import { useEffect } from "react";
import { useLocation } from "react-router-dom";

export default function ScrollToTop() {
  const location = useLocation();

  useEffect(() => {
    window.scrollTo({
      top: 0,
      left: 0,
      behavior: "auto"
    });
  }, [location.pathname]);

  return null;
}
""")

saved_presets_path.write_text("""import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";

type SavedContentResponse = {
  favorite_restaurants: string[];
  favorite_dining_experiences: string[];
  user_presets: Array<{
    preset_id: string;
    name: string;
    description?: string | null;
    updated_at: string;
  }>;
  recent_experiences: Array<{
    experience_id: number;
    title?: string | null;
    restaurant_name?: string | null;
    overall_rating?: number | null;
    created_at: string;
  }>;
};

type PresetSelectionPayload = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus?: boolean | null;
  atmosphere: string[];
};

type PresetResponse = {
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

function formatLabel(value: string) {
  return value
    .replace(/[_-]/g, " ")
    .split(" ")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function summarizePreset(preset: PresetResponse): string[] {
  const chips: string[] = [];
  if (preset.selection_payload.outing_type) chips.push(formatLabel(preset.selection_payload.outing_type));
  if (preset.selection_payload.budget) chips.push(preset.selection_payload.budget);
  if (preset.selection_payload.pace) chips.push(formatLabel(preset.selection_payload.pace));
  if (preset.selection_payload.social_context) chips.push(formatLabel(preset.selection_payload.social_context));
  preset.selection_payload.preferred_cuisines.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  preset.selection_payload.atmosphere.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  return chips.slice(0, 8);
}

export default function SavedPresetsPage() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [savedContent, setSavedContent] = useState<SavedContentResponse | null>(null);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loadingSavedContent, setLoadingSavedContent] = useState(true);
  const [loadingPresets, setLoadingPresets] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadSavedContent() {
      try {
        setError("");
        const data = await apiRequest<SavedContentResponse>("/users/me/saved-content");
        if (!cancelled) {
          setSavedContent(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your saved content.");
        }
      } finally {
        if (!cancelled) {
          setLoadingSavedContent(false);
        }
      }
    }

    void loadSavedContent();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadPresets() {
      try {
        const data = await apiRequest<PresetResponse[]>("/presets");
        if (!cancelled) {
          setPresets(Array.isArray(data) ? data : []);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your presets.");
        }
      } finally {
        if (!cancelled) {
          setLoadingPresets(false);
        }
      }
    }

    void loadPresets();

    return () => {
      cancelled = true;
    };
  }, []);

  const userPresets = useMemo(
    () =>
      presets.filter(
        (preset) =>
          preset.owner_type === "user" &&
          (preset.owner_user_id == null || preset.owner_user_id === user?.id)
      ),
    [presets, user?.id]
  );

  const hasNoPresets = !loadingPresets && userPresets.length === 0;

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Account-owned presets</p>
        <h1 className="page-title">View my presets</h1>
        <p className="muted" style={{ maxWidth: "800px", marginBottom: 0 }}>
          Review the presets you created, return to recommendation flows, or create a new preset if you do not have one yet.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Button variant="ghost" onClick={() => navigate("/profile")}>
          Back to profile
        </Button>
        <Button onClick={() => navigate("/recommendations/build/presets/new")}>
          Create a new preset
        </Button>
      </div>

      {hasNoPresets ? (
        <Card
          title="No presets created yet"
          subtitle="You have not created any presets yet. Start by creating one now."
          actions={<Badge tone="accent">Empty state</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>What happens next?</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Create your first preset, save it, and then it will appear here in your personal preset library.
              </p>
            </div>
          </div>

          <div className="button-row" style={{ marginTop: "1rem" }}>
            <Button onClick={() => navigate("/recommendations/build/presets/new")}>
              Create your first preset
            </Button>
          </div>
        </Card>
      ) : null}

      <section className="grid grid-2">
        <Card
          title="Account summary"
          subtitle="Quick counts for presets and saved dining signals"
          actions={<Badge tone="accent">Saved content</Badge>}
        >
          {loadingSavedContent ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading saved content...</p>
          ) : (
            <div className="list">
              <div className="item">
                <strong>User presets</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.user_presets.length ?? 0} saved
                </p>
              </div>
              <div className="item">
                <strong>Favorite restaurants</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.favorite_restaurants.length ?? 0} saved
                </p>
              </div>
              <div className="item">
                <strong>Favorite dining experiences</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.favorite_dining_experiences.length ?? 0} saved
                </p>
              </div>
              <div className="button-row">
                <Link to="/recommendations/build">
                  <Button>Open build flow</Button>
                </Link>
                <Link to="/recommendations/build/presets/new">
                  <Button variant="secondary">Create preset</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>

        <Card
          title="Recent experience context"
          subtitle="Useful recent dining activity that may inform future preset changes"
          actions={<Badge tone="success">History</Badge>}
        >
          {loadingSavedContent ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading recent experiences...</p>
          ) : !savedContent?.recent_experiences.length ? (
            <p className="muted" style={{ marginBottom: 0 }}>
              No recent experiences saved yet.
            </p>
          ) : (
            <div className="list">
              {savedContent.recent_experiences.slice(0, 4).map((experience) => (
                <div className="item" key={experience.experience_id}>
                  <strong>{experience.title || "Untitled experience"}</strong>
                  <p className="muted" style={{ margin: "0.35rem 0 0" }}>
                    {experience.restaurant_name || "Unknown venue"}
                    {typeof experience.overall_rating === "number"
                      ? ` · Rating ${experience.overall_rating.toFixed(1)}`
                      : ""}
                  </p>
                </div>
              ))}
            </div>
          )}
        </Card>
      </section>

      {!hasNoPresets ? (
        <section className="grid">
          <Card
            title="Your saved presets"
            subtitle="The presets you created and can reuse later"
            actions={<Badge tone="accent">{loadingPresets ? "Loading" : `${userPresets.length} visible`}</Badge>}
          >
            {loadingPresets ? (
              <p className="muted" style={{ marginBottom: 0 }}>Loading presets...</p>
            ) : (
              <div className="preset-library-grid">
                {userPresets.map((preset) => (
                  <div key={preset.preset_id} className="preset-card">
                    <div className="preset-card__header">
                      <strong>{preset.name}</strong>
                      <Badge tone="success">Your preset</Badge>
                    </div>

                    <p className="muted" style={{ margin: 0 }}>
                      {preset.description || "No description saved for this preset."}
                    </p>

                    <div className="preset-chip-row">
                      {summarizePreset(preset).map((chip) => (
                        <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                          {chip}
                        </span>
                      ))}
                    </div>

                    <div className="saved-preset-meta">
                      <span>Preset id: {preset.preset_id}</span>
                      <span>
                        Updated:{" "}
                        {preset.updated_at ? new Date(preset.updated_at).toLocaleString() : "Unknown"}
                      </span>
                    </div>

                    <div className="button-row">
                      <Button onClick={() => navigate("/recommendations/build/presets")}>
                        Use preset
                      </Button>
                      <Button variant="secondary" onClick={() => navigate("/recommendations/build/presets/new")}>
                        Create another
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </section>
      ) : null}
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
  { to: "/profile/presets", label: "View my presets", short: "VP" },
  { to: "/recommendations", label: "Recommendations", short: "RC" },
  { to: "/restaurants", label: "Restaurants", short: "RS" },
  { to: "/experiences", label: "Experiences", short: "EX" }
];

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-scroll-area">
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
              View my presets
            </Link>
          </div>
        </div>

        <div className="sidebar-section">
          <p className="sidebar-section-label">Recommendation shortcuts</p>
          <div className="sidebar-quick-actions">
            <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/build">
              Build a night
            </Link>
            <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/build/presets/new">
              Create preset
            </Link>
            <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/describe">
              Describe a night
            </Link>
          </div>
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

.sidebar-scroll-area {
  display: grid;
  gap: 1rem;
  min-height: 0;
  overflow-y: auto;
  padding-right: 0.2rem;
}

.app-sidebar {
  position: sticky;
  top: 1rem;
  max-height: calc(100vh - 2rem);
  overflow: hidden;
}

.sidebar-footer {
  margin-top: auto;
  padding-top: 0.75rem;
}
"""
if ".sidebar-scroll-area" not in styles:
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
echo "Patch 10 applied successfully."
echo "Files changed:"
echo " - frontend/src/App.tsx"
echo " - frontend/src/components/layout/ScrollToTop.tsx"
echo " - frontend/src/pages/SavedPresetsPage.tsx"
echo " - frontend/src/components/navigation/Sidebar.tsx"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) run frontend"
echo "2) open /profile/presets"
echo "3) confirm empty state appears if no presets exist"
echo "4) click create preset and confirm redirect to /recommendations/build/presets/new"
echo "5) create a preset and confirm it appears back in /profile/presets"
echo "6) scroll down on any page, change routes, and confirm you land at the top"
echo "7) confirm sidebar stays usable and scrollable"
