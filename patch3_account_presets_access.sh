#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch3_account_presets_access_backup_$STAMP"

FILES=(
  "$FRONTEND_DIR/src/App.tsx"
  "$FRONTEND_DIR/src/components/navigation/Navbar.tsx"
  "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx"
  "$FRONTEND_DIR/src/pages/DashboardPage.tsx"
  "$FRONTEND_DIR/src/pages/ProfilePage.tsx"
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
  "$BACKUP_DIR/frontend/src/pages" \
  "$BACKUP_DIR/frontend/src"

cp "$FRONTEND_DIR/src/App.tsx" \
  "$BACKUP_DIR/frontend/src/App.tsx"
cp "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" \
  "$BACKUP_DIR/frontend/src/components/navigation/Navbar.tsx"
cp "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" \
  "$BACKUP_DIR/frontend/src/components/navigation/Sidebar.tsx"
cp "$FRONTEND_DIR/src/pages/DashboardPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/DashboardPage.tsx"
cp "$FRONTEND_DIR/src/pages/ProfilePage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/ProfilePage.tsx"
cp "$FRONTEND_DIR/src/styles.css" \
  "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch3_account_presets_access..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

app_path = Path("frontend/src/App.tsx")
navbar_path = Path("frontend/src/components/navigation/Navbar.tsx")
sidebar_path = Path("frontend/src/components/navigation/Sidebar.tsx")
dashboard_path = Path("frontend/src/pages/DashboardPage.tsx")
profile_path = Path("frontend/src/pages/ProfilePage.tsx")
saved_presets_path = Path("frontend/src/pages/SavedPresetsPage.tsx")
styles_path = Path("frontend/src/styles.css")

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
      title: "Build Your Night",
      subtitle:
        "Apply presets, customize the builder, and generate recommendation results from a focused flow."
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
      title: "Recommendation results",
      subtitle:
        "Review the generated dining matches and navigate back to the originating flow when needed."
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

      <div className="sidebar-quick-actions">
        <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/profile/preferences">
          Edit preferences
        </Link>
        <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/profile/presets">
          Open saved presets
        </Link>
        <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/recommendations/build">
          Build a night
        </Link>
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

dashboard_path.write_text("""import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingState } from "../types";

function formatLabel(value: string) {
  return value
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function renderSignalList(values: string[], emptyText: string) {
  if (values.length === 0) {
    return <p className="muted" style={{ marginBottom: 0 }}>{emptyText}</p>;
  }

  return (
    <div className="dashboard-chip-row">
      {values.slice(0, 6).map((value) => (
        <span key={value} className="dashboard-chip">
          {formatLabel(value)}
        </span>
      ))}
    </div>
  );
}

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

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "Guest";

  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [savedContent, setSavedContent] = useState<SavedContentResponse | null>(null);
  const [profileError, setProfileError] = useState("");
  const [savedContentError, setSavedContentError] = useState("");
  const [isLoadingProfile, setIsLoadingProfile] = useState(true);
  const [isLoadingSavedContent, setIsLoadingSavedContent] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadProfileSnapshot() {
      try {
        const state = await apiRequest<OnboardingState>("/onboarding");
        if (!cancelled) {
          setProfileState(state);
        }
      } catch (err) {
        if (!cancelled) {
          setProfileError(
            err instanceof Error ? err.message : "We could not load your profile summary."
          );
        }
      } finally {
        if (!cancelled) {
          setIsLoadingProfile(false);
        }
      }
    }

    void loadProfileSnapshot();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadSavedContent() {
      try {
        const data = await apiRequest<SavedContentResponse>("/users/me/saved-content");
        if (!cancelled) {
          setSavedContent(data);
        }
      } catch (err) {
        if (!cancelled) {
          setSavedContentError(
            err instanceof Error ? err.message : "We could not load your saved content summary."
          );
        }
      } finally {
        if (!cancelled) {
          setIsLoadingSavedContent(false);
        }
      }
    }

    void loadSavedContent();

    return () => {
      cancelled = true;
    };
  }, []);

  const quickPanels = useMemo(
    () => [
      {
        title: "Profile status",
        value: profileState?.onboarding_completed ? "Ready" : "Incomplete",
        subtitle: profileState?.onboarding_completed
          ? "Your SAVR profile is active and can be refined anytime."
          : "Finish your profile to improve your recommendation quality.",
        tone: profileState?.onboarding_completed ? ("success" as const) : ("accent" as const)
      },
      {
        title: "Cuisine preferences",
        value: String(profileState?.cuisine_preferences.length ?? 0),
        subtitle: "Saved cuisine signals currently helping shape your results.",
        tone: "accent" as const
      },
      {
        title: "Saved presets",
        value: String(savedContent?.user_presets.length ?? 0),
        subtitle: "Reusable builder configurations saved only to your account.",
        tone: "default" as const
      }
    ],
    [profileState, savedContent]
  );

  const workflowSteps = [
    {
      title: "Review your profile",
      description:
        "Visit your dedicated profile page to review saved signals and decide what to refine."
    },
    {
      title: "Review your saved presets",
      description:
        "Open the new saved-presets page to inspect account-owned presets and return to editing quickly."
    },
    {
      title: "Log real dining moments",
      description:
        "Use the dedicated experience logging page to save what actually worked after each outing."
    }
  ];

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div className="grid" style={{ gap: "1rem" }}>
          <div>
            <p className="navbar-eyebrow">Welcome</p>
            <h1 className="page-title">Welcome back, {firstName}</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Use this space to review your profile, check what SAVR already knows about
              your dining style, inspect saved presets, and move into the parts of the product
              that now live on their own dedicated pages.
            </p>
          </div>

          <div>
            <Badge>SAVR</Badge>
            <Badge tone="accent">Structured navigation</Badge>
            <Badge tone="success">Ready to explore</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Find recommendations</Button>
            </Link>
            <Link to="/profile">
              <Button variant="secondary">Edit profile</Button>
            </Link>
            <Link to="/profile/presets">
              <Button variant="ghost">Open saved presets</Button>
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
          title="Your saved profile"
          subtitle="A quick summary of the preferences currently guiding SAVR"
          actions={<Badge tone="accent">Profile</Badge>}
        >
          {isLoadingProfile ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your profile...</p>
          ) : profileError ? (
            <div className="error">{profileError}</div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>Cuisine preferences</strong>
                {renderSignalList(
                  profileState?.cuisine_preferences ?? [],
                  "No cuisine preferences saved yet."
                )}
              </div>

              <div className="item">
                <strong>Drink preferences</strong>
                {renderSignalList(
                  profileState?.drink_preferences ?? [],
                  "No drink preferences saved yet."
                )}
              </div>

              <div className="item">
                <strong>Atmosphere preferences</strong>
                {renderSignalList(
                  profileState?.atmosphere_preferences ?? [],
                  "No atmosphere preferences saved yet."
                )}
              </div>

              <div className="item">
                <strong>Favorite restaurants</strong>
                {renderSignalList(
                  profileState?.favorite_restaurants ?? [],
                  "No favorite restaurants saved yet."
                )}
              </div>

              <div className="button-row">
                <Link to="/profile">
                  <Button variant="secondary">Open profile page</Button>
                </Link>
                <Link to="/profile/preferences">
                  <Button variant="ghost">Update preferences</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>

        <Card
          title="Saved content access"
          subtitle="Direct routes into reusable account-owned recommendation data"
          actions={<Badge tone="success">Account data</Badge>}
        >
          {isLoadingSavedContent ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading saved content...</p>
          ) : savedContentError ? (
            <div className="error">{savedContentError}</div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>User presets</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.user_presets.length ?? 0} saved to your account
                </p>
              </div>

              <div className="item">
                <strong>Recent experiences</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.recent_experiences.length ?? 0} recent entries
                </p>
              </div>

              <div className="item">
                <strong>Favorite dining experiences</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.favorite_dining_experiences.length ?? 0} saved
                </p>
              </div>

              <div className="button-row">
                <Link to="/profile/presets">
                  <Button>Open saved presets</Button>
                </Link>
                <Link to="/recommendations/build">
                  <Button variant="secondary">Build from a preset</Button>
                </Link>
                <Link to="/experiences">
                  <Button variant="ghost">View history</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>
      </section>

      <section className="grid">
        <Card
          title="Suggested next steps"
          subtitle="A cleaner path through the app for real product testing"
          actions={<Badge tone="accent">Guide</Badge>}
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
      </section>
    </div>
  );
}
""")

profile_path.write_text("""import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingState } from "../types";

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

function renderBadges(values: string[], tone: "default" | "accent" | "success" = "default") {
  if (values.length === 0) {
    return <p className="muted" style={{ marginBottom: 0 }}>Nothing saved yet.</p>;
  }

  return (
    <div>
      {values.map((value) => (
        <Badge key={value} tone={tone}>
          {formatLabel(value)}
        </Badge>
      ))}
    </div>
  );
}

function summarizePreset(preset: PresetResponse): string[] {
  const chips: string[] = [];
  if (preset.selection_payload.outing_type) chips.push(formatLabel(preset.selection_payload.outing_type));
  if (preset.selection_payload.budget) chips.push(preset.selection_payload.budget);
  if (preset.selection_payload.pace) chips.push(formatLabel(preset.selection_payload.pace));
  if (preset.selection_payload.social_context) chips.push(formatLabel(preset.selection_payload.social_context));
  preset.selection_payload.preferred_cuisines.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  return chips;
}

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [presetLoading, setPresetLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadProfile() {
      try {
        setError("");
        setLoading(true);
        const state = await apiRequest<OnboardingState>("/onboarding");
        if (!cancelled) {
          setProfileState(state);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your SAVR profile.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadProfile();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadPresets() {
      try {
        setPresetLoading(true);
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
          setPresetLoading(false);
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

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile</p>
        <h1 className="page-title">Your SAVR profile</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page is your dedicated profile overview. Review what SAVR knows about your tastes,
          your saved reusable presets, and the quickest places to update those signals.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Account summary"
          subtitle="Your saved user identity and current profile readiness"
          actions={<Badge tone="accent">Account</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Name</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user ? `${user.first_name} ${user.last_name}`.trim() : "Guest user"}
              </p>
            </div>

            <div className="item">
              <strong>Email</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user?.email || "No email available"}
              </p>
            </div>

            <div className="item">
              <strong>Profile status</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user?.onboarding_completed ? "Ready" : "Incomplete"}
              </p>
            </div>

            <div className="button-row">
              <Link to="/profile/preferences">
                <Button>Edit profile</Button>
              </Link>
              <Link to="/profile/presets">
                <Button variant="secondary">Saved presets</Button>
              </Link>
              <Link to="/dashboard">
                <Button variant="ghost">Back to dashboard</Button>
              </Link>
            </div>
          </div>
        </Card>

        <Card
          title="Preference overview"
          subtitle="A structured summary of the signals currently shaping your recommendations"
          actions={<Badge tone="success">Profile data</Badge>}
        >
          {loading ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your saved profile...</p>
          ) : !profileState ? (
            <div className="item">
              <strong>No profile data available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You can continue to the preference editor to create or update your profile.
              </p>
            </div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>Cuisine preferences</strong>
                {renderBadges(profileState.cuisine_preferences)}
              </div>

              <div className="item">
                <strong>Atmosphere preferences</strong>
                {renderBadges(profileState.atmosphere_preferences, "accent")}
              </div>

              <div className="item">
                <strong>Drink preferences</strong>
                {renderBadges(profileState.drink_preferences, "success")}
              </div>

              <div className="item">
                <strong>Favorite restaurants</strong>
                {renderBadges(profileState.favorite_restaurants)}
              </div>

              <div className="item">
                <strong>Dining note</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {profileState.bio?.trim() || "No dining note saved yet."}
                </p>
              </div>
            </div>
          )}
        </Card>
      </section>

      <section className="grid">
        <Card
          title="Your saved presets"
          subtitle="Reusable personal builders saved only to your account"
          actions={<Badge tone="accent">{presetLoading ? "Loading" : `${userPresets.length} saved`}</Badge>}
        >
          {presetLoading ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your presets...</p>
          ) : userPresets.length === 0 ? (
            <div className="item">
              <strong>No custom presets saved yet</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Go to recommendations, configure the builder, and save that configuration as a reusable preset.
              </p>
              <div className="button-row" style={{ marginTop: "0.9rem" }}>
                <Link to="/recommendations/build">
                  <Button>Open build flow</Button>
                </Link>
                <Link to="/profile/presets">
                  <Button variant="secondary">Open saved presets page</Button>
                </Link>
              </div>
            </div>
          ) : (
            <div className="preset-library-grid">
              {userPresets.slice(0, 3).map((preset) => (
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
                </div>
              ))}

              <div className="button-row">
                <Link to="/profile/presets">
                  <Button>View all saved presets</Button>
                </Link>
                <Link to="/recommendations/build">
                  <Button variant="secondary">Create or edit presets</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
""")

saved_presets_path.write_text("""import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

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
  if (preset.selection_payload.drinks_focus) chips.push("Drinks");
  return chips.slice(0, 8);
}

export default function SavedPresetsPage() {
  const { user } = useAuth();

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

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Account-owned presets</p>
        <h1 className="page-title">Saved presets</h1>
        <p className="muted" style={{ maxWidth: "800px", marginBottom: 0 }}>
          This page is a dedicated account-level surface for presets saved to your user account.
          It only shows presets marked as user-owned, and when an owner id is present it is matched
          against your current signed-in account before display.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

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
                <Link to="/profile">
                  <Button variant="secondary">Back to profile</Button>
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

      <section className="grid">
        <Card
          title="Your account-owned presets"
          subtitle="Only user presets are shown here, with an extra owner check when available"
          actions={<Badge tone="accent">{loadingPresets ? "Loading" : `${userPresets.length} visible`}</Badge>}
        >
          {loadingPresets ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading presets...</p>
          ) : userPresets.length === 0 ? (
            <div className="item">
              <strong>No user presets available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Create one from the build flow and it will appear here after save.
              </p>
              <div className="button-row" style={{ marginTop: "0.9rem" }}>
                <Link to="/recommendations/build">
                  <Button>Create a preset</Button>
                </Link>
              </div>
            </div>
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
                    <Link to="/recommendations/build">
                      <Button>Open build flow</Button>
                    </Link>
                    <Link to="/profile">
                      <Button variant="secondary">Back to profile</Button>
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
""")

styles = styles_path.read_text()
extra = """

.saved-preset-meta {
  display: flex;
  gap: 0.85rem;
  flex-wrap: wrap;
  margin-top: 0.85rem;
  color: var(--color-text-muted, #5f6b61);
  font-size: 0.92rem;
}
"""
if ".saved-preset-meta" not in styles:
    styles += extra
styles_path.write_text(styles)
PY

echo
echo "Running TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 3 applied successfully."
echo "Files changed:"
echo " - frontend/src/App.tsx"
echo " - frontend/src/components/navigation/Navbar.tsx"
echo " - frontend/src/components/navigation/Sidebar.tsx"
echo " - frontend/src/pages/DashboardPage.tsx"
echo " - frontend/src/pages/ProfilePage.tsx"
echo " - frontend/src/pages/SavedPresetsPage.tsx"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) cd frontend"
echo "2) npm run dev"
echo "3) open /profile/presets"
echo "4) confirm the page loads saved-content and user presets"
echo "5) confirm Dashboard, Profile, and Sidebar link to /profile/presets"
echo "6) confirm only user-owned presets are shown there"
echo "7) confirm build flow remains the editing surface for presets"
