#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
else
  echo "Error: could not find frontend/src from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

mkdir -p "$FRONTEND_DIR/src/pages"

cat > "$FRONTEND_DIR/src/App.tsx" <<'EOF'
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

cat > "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" <<'EOF'
import { Link, NavLink } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "DB" },
  { to: "/profile", label: "Profile", short: "PF" },
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
          Explore restaurants, update your profile, and discover dining experiences that fit your style.
        </p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
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
        <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/experiences/new">
          Log an experience
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
EOF

cat > "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" <<'EOF'
import { useLocation } from "react-router-dom";

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
        "Explore dining recommendations shaped by your profile, preferences, and context."
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
EOF

cat > "$FRONTEND_DIR/src/components/dining/RestaurantCard.tsx" <<'EOF'
import { Link } from "react-router-dom";

import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";
import { RestaurantListItem } from "../../types";

type RestaurantCardProps = {
  restaurant: RestaurantListItem;
  onSelect?: (restaurantId: number) => void;
  isActive?: boolean;
  detailPath?: string;
};

function buildMeta(restaurant: RestaurantListItem) {
  return [restaurant.city, restaurant.price_tier, restaurant.pace || "pace not set"]
    .filter(Boolean)
    .join(" • ");
}

export default function RestaurantCard({
  restaurant,
  onSelect,
  isActive = false,
  detailPath
}: RestaurantCardProps) {
  return (
    <Card
      className={isActive ? "restaurant-card restaurant-card--active" : "restaurant-card"}
      title={restaurant.name}
      subtitle={buildMeta(restaurant)}
      actions={
        restaurant.serves_alcohol ? (
          <Badge tone="accent">Drinks</Badge>
        ) : (
          <Badge>Food-first</Badge>
        )
      }
    >
      <div className="grid" style={{ gap: "0.85rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {restaurant.description || "No description available yet for this restaurant."}
        </p>

        <div>
          {restaurant.atmosphere ? <Badge>{restaurant.atmosphere}</Badge> : null}
          {restaurant.social_style ? <Badge tone="accent">{restaurant.social_style}</Badge> : null}
          {restaurant.pace ? <Badge tone="success">{restaurant.pace}</Badge> : null}
        </div>

        <div className="button-row">
          {onSelect ? (
            <Button
              variant={isActive ? "secondary" : "ghost"}
              onClick={() => onSelect(restaurant.id)}
            >
              {isActive ? "Selected" : "View details"}
            </Button>
          ) : null}

          {detailPath ? (
            <Link className="ui-button ui-button--ghost ui-button--md" to={detailPath}>
              Open venue page
            </Link>
          ) : null}
        </div>
      </div>
    </Card>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/DashboardPage.tsx" <<'EOF'
import { useEffect, useMemo, useState } from "react";
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

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "Guest";

  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [profileError, setProfileError] = useState("");
  const [isLoadingProfile, setIsLoadingProfile] = useState(true);

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
        title: "Atmosphere preferences",
        value: String(profileState?.atmosphere_preferences.length ?? 0),
        subtitle: "Saved mood and setting signals available for matching.",
        tone: "default" as const
      }
    ],
    [profileState]
  );

  const workflowSteps = [
    {
      title: "Review your profile",
      description:
        "Visit your dedicated profile page to review saved signals and decide what to refine."
    },
    {
      title: "Explore restaurants",
      description:
        "Browse the venue catalog and open a dedicated page for any restaurant you want to inspect."
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
              your dining style, and move into the parts of the product that now live on
              their own dedicated pages.
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
            <Link to="/experiences/new">
              <Button variant="ghost">Log an experience</Button>
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
          title="Suggested next steps"
          subtitle="A cleaner path through the app for real product testing"
          actions={<Badge tone="success">Guide</Badge>}
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

          <hr />

          <div className="button-row">
            <Link to="/restaurants">
              <Button variant="ghost">Browse restaurants</Button>
            </Link>
            <Link to="/experiences">
              <Button variant="secondary">View history</Button>
            </Link>
            <Link to="/recommendations">
              <Button>Start exploring</Button>
            </Link>
          </div>
        </Card>
      </section>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/ProfilePage.tsx" <<'EOF'
import { useEffect, useState } from "react";
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

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [loading, setLoading] = useState(true);
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

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile</p>
        <h1 className="page-title">Your SAVR profile</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page is your dedicated profile overview. Review what SAVR knows about your tastes,
          then move into preference editing only when you actually want to update those signals.
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
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/RestaurantsPage.tsx" <<'EOF'
import { useEffect, useState } from "react";

import RestaurantCard from "../components/dining/RestaurantCard";
import Badge from "../components/ui/Badge";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RestaurantListItem } from "../types";

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurants() {
      try {
        setError("");
        setLoading(true);
        const data = await apiRequest<RestaurantListItem[]>("/restaurants");
        if (!cancelled) {
          setRestaurants(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load the venue guide.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadRestaurants();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Restaurants</p>
        <h1 className="page-title">Browse the SAVR venue catalog</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page now focuses only on restaurant discovery. Open any venue to inspect
          its own dedicated detail page.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <Card
        title="Available venues"
        subtitle="Browse the current restaurant catalog from the backend"
        actions={<Badge>{restaurants.length} venues</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading the venue guide</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling available restaurants from the API.
            </p>
          </div>
        ) : restaurants.length === 0 ? (
          <div className="item">
            <strong>No venues are available</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              The backend returned an empty catalog.
            </p>
          </div>
        ) : (
          <div className="grid grid-2">
            {restaurants.map((restaurant) => (
              <RestaurantCard
                key={restaurant.id}
                restaurant={restaurant}
                detailPath={`/restaurants/${restaurant.id}`}
              />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/RestaurantDetailPage.tsx" <<'EOF'
import { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RestaurantDetail } from "../types";

export default function RestaurantDetailPage() {
  const { restaurantId } = useParams<{ restaurantId: string }>();

  const [restaurant, setRestaurant] = useState<RestaurantDetail | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurant() {
      if (!restaurantId) {
        setError("No restaurant was selected.");
        setLoading(false);
        return;
      }

      try {
        setError("");
        setLoading(true);
        const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
        if (!cancelled) {
          setRestaurant(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load this venue.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadRestaurant();

    return () => {
      cancelled = true;
    };
  }, [restaurantId]);

  const summaryText = useMemo(() => {
    if (!restaurant) {
      return "Open a venue from the restaurant catalog to inspect its menu, tags, atmosphere, and recommendation signals.";
    }

    return restaurant.description || "No summary is available for this venue yet.";
  }, [restaurant]);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Restaurant detail</p>
        <h1 className="page-title">{restaurant?.name || "Venue overview"}</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Dedicated venue pages make it easier to inspect a restaurant without crowding the full restaurant listing page.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Link to="/restaurants">
          <Button variant="ghost">Back to restaurants</Button>
        </Link>
        <Link to="/recommendations">
          <Button variant="secondary">Go to recommendations</Button>
        </Link>
      </div>

      <Card
        title={restaurant?.name || "Venue detail"}
        subtitle={summaryText}
        actions={restaurant ? <Badge tone="accent">{restaurant.price_tier}</Badge> : <Badge>Preview</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading venue detail</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling restaurant information from the backend.
            </p>
          </div>
        ) : !restaurant ? (
          <div className="item">
            <strong>No venue selected</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Return to the restaurant list and choose a venue.
            </p>
          </div>
        ) : (
          <div className="list">
            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Venue profile</p>
              <strong>Atmosphere and positioning</strong>
              <p className="muted">
                {restaurant.city} • {restaurant.price_tier} • {restaurant.atmosphere || "No atmosphere"} • {restaurant.pace || "No pace"} • {restaurant.social_style || "No social style"}
              </p>
              <div>
                {restaurant.tags.map((tag) => (
                  <Badge key={`${tag.category}-${tag.name}`}>{tag.category}: {tag.name}</Badge>
                ))}
              </div>
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Menu signals</p>
              <strong>Menu items</strong>
              {restaurant.menu_items.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No menu items were returned for this venue.
                </p>
              ) : (
                <div className="list" style={{ marginTop: "0.8rem" }}>
                  {restaurant.menu_items.map((item) => (
                    <div className="item" key={item.id}>
                      <strong>{item.name}</strong>
                      <p className="muted">
                        {item.category} • Price: {item.price ?? "-"} • {item.is_signature ? "Signature item" : "Standard item"}
                      </p>
                      <p style={{ marginBottom: item.tags.length > 0 ? "0.8rem" : 0 }}>
                        {item.description || "No description"}
                      </p>
                      {item.tags.length > 0 ? (
                        <div>
                          {item.tags.map((tag) => (
                            <Badge key={`${item.id}-${tag.id}`} tone="accent">
                              {tag.name}
                            </Badge>
                          ))}
                        </div>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/ExperiencesPage.tsx" <<'EOF'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import ExperienceCard from "../components/dining/ExperienceCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { Experience } from "../types";

export default function ExperiencesPage() {
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadExperiences() {
      try {
        setError("");
        setLoading(true);
        const experienceData = await apiRequest<Experience[]>("/experiences");
        if (!cancelled) {
          setExperiences(experienceData);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load your SAVR history.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadExperiences();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Experiences</p>
        <h1 className="page-title">Your saved dining history</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page now focuses on browsing what you have already saved. Logging a new experience happens in its own dedicated page.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Link to="/experiences/new">
          <Button>Log a new experience</Button>
        </Link>
        <Link to="/recommendations">
          <Button variant="ghost">Go to recommendations</Button>
        </Link>
      </div>

      <Card
        title="Saved entries"
        subtitle="A running memory of real dining moments"
        actions={<Badge>{experiences.length} entries</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading SAVR history</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling your saved entries from the backend.
            </p>
          </div>
        ) : experiences.length === 0 ? (
          <div className="item">
            <strong>No entries yet</strong>
            <p className="muted" style={{ marginBottom: "1rem" }}>
              Your first saved night will appear here.
            </p>
            <Link to="/experiences/new">
              <Button>Log your first experience</Button>
            </Link>
          </div>
        ) : (
          <div className="grid grid-2">
            {experiences.map((experience) => (
              <ExperienceCard key={experience.id} experience={experience} />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/NewExperiencePage.tsx" <<'EOF'
import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { Experience, RestaurantListItem } from "../types";

const occasionOptions = [
  "date night",
  "friends night",
  "family dinner",
  "celebration",
  "casual lunch",
  "solo meal",
  "business meal"
];

const socialOptions = [
  "romantic",
  "friends",
  "family",
  "solo",
  "group",
  "professional"
];

export default function NewExperiencePage() {
  const navigate = useNavigate();

  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loadingRestaurants, setLoadingRestaurants] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [form, setForm] = useState({
    restaurant_id: "",
    title: "",
    occasion: "",
    social_context: "",
    notes: "",
    overall_rating: "4"
  });

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurants() {
      try {
        setError("");
        setLoadingRestaurants(true);
        const restaurantData = await apiRequest<RestaurantListItem[]>("/restaurants");
        if (!cancelled) {
          setRestaurants(restaurantData);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load restaurants for this form.");
        }
      } finally {
        if (!cancelled) {
          setLoadingRestaurants(false);
        }
      }
    }

    void loadRestaurants();

    return () => {
      cancelled = true;
    };
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");
    setIsSubmitting(true);

    try {
      await apiRequest<Experience>("/experiences", {
        method: "POST",
        body: {
          restaurant_id: form.restaurant_id ? Number(form.restaurant_id) : null,
          title: form.title || null,
          occasion: form.occasion || null,
          social_context: form.social_context || null,
          notes: form.notes || null,
          overall_rating: form.overall_rating ? Number(form.overall_rating) : null,
          menu_item_ids: [],
          ratings: form.overall_rating
            ? [
                {
                  category: "overall",
                  score: Number(form.overall_rating)
                }
              ]
            : []
        }
      });

      setSuccess("Your experience has been saved.");
      setTimeout(() => {
        navigate("/experiences");
      }, 700);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save this experience.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">New experience</p>
        <h1 className="page-title">Log a dining experience</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This dedicated page separates logging from history so saving a new dining moment feels clearer and more focused.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <Card
          title="New SAVR entry"
          subtitle="Capture the essentials from a real dining experience"
          actions={<Badge tone="accent">Log</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label htmlFor="restaurant_id">Venue</label>
              <select
                id="restaurant_id"
                value={form.restaurant_id}
                onChange={(e) => setForm({ ...form, restaurant_id: e.target.value })}
              >
                <option value="">
                  {loadingRestaurants ? "Loading restaurants..." : "Select a venue"}
                </option>
                {restaurants.map((restaurant) => (
                  <option key={restaurant.id} value={restaurant.id}>
                    {restaurant.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="title">Entry title</label>
                <input
                  id="title"
                  value={form.title}
                  placeholder="e.g. Excellent Friday dinner"
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="overall_rating">Overall rating</label>
                <select
                  id="overall_rating"
                  value={form.overall_rating}
                  onChange={(e) => setForm({ ...form, overall_rating: e.target.value })}
                >
                  <option value="">Select a rating</option>
                  <option value="5">5</option>
                  <option value="4.5">4.5</option>
                  <option value="4">4</option>
                  <option value="3.5">3.5</option>
                  <option value="3">3</option>
                  <option value="2.5">2.5</option>
                  <option value="2">2</option>
                  <option value="1">1</option>
                </select>
              </div>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="occasion">Occasion</label>
                <select
                  id="occasion"
                  value={form.occasion}
                  onChange={(e) => setForm({ ...form, occasion: e.target.value })}
                >
                  <option value="">Select an occasion</option>
                  {occasionOptions.map((option) => (
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
                  onChange={(e) => setForm({ ...form, social_context: e.target.value })}
                >
                  <option value="">Select the social context</option>
                  {socialOptions.map((option) => (
                    <option key={option} value={option}>
                      {option}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="notes">Notes</label>
              <textarea
                id="notes"
                rows={5}
                value={form.notes}
                placeholder="What stood out about the food, pacing, service, or atmosphere?"
                onChange={(e) => setForm({ ...form, notes: e.target.value })}
              />
            </div>

            <div className="button-row">
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Saving..." : "Save experience"}
              </Button>
              <Link to="/experiences">
                <Button variant="ghost">Back to history</Button>
              </Link>
            </div>
          </form>
        </Card>

        <Card
          title="Why this page exists"
          subtitle="Logging now has its own dedicated route to keep the product structure clearer"
          actions={<Badge tone="success">Structure</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Focused logging flow</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Saving a new experience is no longer mixed into the history view.
              </p>
            </div>

            <div className="item">
              <strong>Cleaner history page</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Your saved dining history now has its own space, which makes browsing easier.
              </p>
            </div>

            <div className="item">
              <strong>Better phase foundation</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                This sets up the next redesign phase where the experience form can become much more guided and mistake-resistant.
              </p>
            </div>
          </div>
        </Card>
      </section>
    </div>
  );
}
EOF

python3 - <<PY
from pathlib import Path

styles_path = Path(r"$FRONTEND_DIR/src/styles.css")
text = styles_path.read_text()

marker = "/* PHASE 6 ARCHITECTURE AND NAVIGATION REFACTOR */"
if marker not in text:
    text += """

/* PHASE 6 ARCHITECTURE AND NAVIGATION REFACTOR */
.sidebar-quick-actions {
  display: grid;
  gap: 0.75rem;
}

@media (max-width: 1100px) {
  .app-sidebar {
    gap: 1rem;
  }

  .sidebar-nav {
    display: flex;
    gap: 0.75rem;
    overflow-x: auto;
    padding-bottom: 0.25rem;
  }

  .sidebar-link {
    min-width: max-content;
    white-space: nowrap;
  }

  .sidebar-quick-actions {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 760px) {
  .sidebar-profile-card {
    padding: 0.9rem;
  }

  .sidebar-nav {
    display: flex;
    gap: 0.65rem;
    overflow-x: auto;
    scrollbar-width: thin;
  }

  .sidebar-link {
    min-width: max-content;
    padding: 0.78rem 0.9rem;
  }

  .sidebar-quick-actions {
    grid-template-columns: 1fr;
  }

  .button-row > a,
  .button-row > button {
    width: 100%;
  }

  .button-row .ui-button {
    width: 100%;
    justify-content: center;
    display: inline-flex;
  }
}
"""
    styles_path.write_text(text)
PY

echo "Phase 6 architecture and navigation refactor applied successfully in: $FRONTEND_DIR"
echo "New pages created:"
echo " - src/pages/ProfilePage.tsx"
echo " - src/pages/RestaurantDetailPage.tsx"
echo " - src/pages/NewExperiencePage.tsx"
