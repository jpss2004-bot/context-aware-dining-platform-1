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

cat > "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" <<'EOF'
import { NavLink } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "DB" },
  { to: "/onboarding", label: "SAVR Profile", short: "SP" },
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
          <p className="sidebar-eyebrow">Dining Intelligence</p>
          <h1 className="sidebar-brand">SAVR</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Signed in</p>
          <span className="sidebar-online-pill">Live</span>
        </div>

        <strong className="sidebar-user-name">{userName || "Guest user"}</strong>

        <p className="muted">
          Context-aware dining discovery, profile signals, and recommendation workflows.
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

      <div className="sidebar-footer">
        <div className="sidebar-footer-card">
          <p className="sidebar-section-label">Workspace status</p>
          <p className="muted">
            SAVR shell upgraded and ready for deeper recommendation refinement.
          </p>
        </div>

        <button
          className="button ghost sidebar-logout"
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

const titleMap: Record<
  string,
  { eyebrow: string; title: string; subtitle: string }
> = {
  "/dashboard": {
    eyebrow: "Overview",
    title: "SAVR command center",
    subtitle:
      "Track profile readiness, review saved taste signals, and move quickly into recommendation workflows."
  },
  "/onboarding": {
    eyebrow: "Profile setup",
    title: "Build your SAVR profile",
    subtitle:
      "Curate the signals that drive more accurate recommendations and better dining matches."
  },
  "/recommendations": {
    eyebrow: "Recommendation studio",
    title: "Plan the right SAVR experience",
    subtitle:
      "Run structured, prompt-based, and surprise recommendation flows from one workspace."
  },
  "/restaurants": {
    eyebrow: "Discovery",
    title: "Restaurant browsing",
    subtitle:
      "Inspect the restaurant catalog, compare venues, and review available dining options."
  },
  "/experiences": {
    eyebrow: "Memory layer",
    title: "Dining experience history",
    subtitle:
      "Log visits, preserve context, and strengthen future SAVR recommendations."
  }
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content = titleMap[location.pathname] ?? {
    eyebrow: "Workspace",
    title: "SAVR workspace",
    subtitle: "A cleaner, profile-aware dining recommendation product shell."
  };

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
            <p className="navbar-meta-label">Active SAVR profile</p>
            <strong>{userName || "Guest user"}</strong>
          </div>
        </div>
      </div>
    </header>
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
            err instanceof Error ? err.message : "Failed to load SAVR profile summary"
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
        title: "Profile readiness",
        value: profileState?.onboarding_completed ? "Complete" : "Incomplete",
        subtitle: profileState?.onboarding_completed
          ? "Your SAVR profile is active and can be refined anytime."
          : "Finish your SAVR profile to strengthen recommendation quality.",
        tone: profileState?.onboarding_completed ? ("success" as const) : ("accent" as const)
      },
      {
        title: "Cuisine signals",
        value: String(profileState?.cuisine_preferences.length ?? 0),
        subtitle: "Saved cuisine preferences currently shaping recommendation context.",
        tone: "accent" as const
      },
      {
        title: "Atmosphere signals",
        value: String(profileState?.atmosphere_preferences.length ?? 0),
        subtitle: "Saved mood and setting preferences available for matching.",
        tone: "default" as const
      }
    ],
    [profileState]
  );

  const workflowSteps = [
    {
      title: "Review SAVR profile",
      description:
        "Check that your cuisine, drink, pace, and atmosphere selections reflect the kind of dining experiences you actually want."
    },
    {
      title: "Browse restaurants",
      description:
        "Inspect the current restaurant catalog and confirm your favorites align with the venues available in the system."
    },
    {
      title: "Run recommendation workflows",
      description:
        "Use the recommendation studio after your profile is current so the engine has stronger guidance."
    }
  ];

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div className="grid" style={{ gap: "1rem" }}>
          <div>
            <p className="navbar-eyebrow">SAVR overview</p>
            <h1 className="page-title">Welcome back, {firstName}</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Your SAVR workspace is now profile-aware. Use this page to confirm
              profile quality, jump into recommendation workflows, and keep your
              dining signals aligned with the kind of experience you want.
            </p>
          </div>

          <div>
            <Badge>SAVR shell</Badge>
            <Badge tone="accent">Profile-aware</Badge>
            <Badge tone="success">Persistence active</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Open recommendation studio</Button>
            </Link>
            <Link to="/restaurants">
              <Button variant="ghost">Browse restaurants</Button>
            </Link>
            <Link to="/onboarding">
              <Button variant="secondary">Edit SAVR profile</Button>
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
          title="Saved profile snapshot"
          subtitle="Live summary pulled from your persisted onboarding data"
          actions={<Badge tone="accent">Live data</Badge>}
        >
          {isLoadingProfile ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading saved SAVR profile...</p>
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

              <div className="item">
                <strong>Dining bio</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {profileState?.bio?.trim() || "No dining bio saved yet."}
                </p>
              </div>
            </div>
          )}
        </Card>

        <Card
          title="Recommended workflow"
          subtitle="Best path for demos and end-to-end testing"
          actions={<Badge tone="success">Suggested</Badge>}
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
            <Link to="/onboarding">
              <Button variant="ghost">Open SAVR profile</Button>
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

python3 - <<PY
from pathlib import Path

styles_path = Path(r"$FRONTEND_DIR/src/styles.css")
text = styles_path.read_text()

marker = "/* PHASE 4 SAVR SHELL AND PROFILE SYNC */"
if marker not in text:
    text += """

/* PHASE 4 SAVR SHELL AND PROFILE SYNC */
.dashboard-chip-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.55rem;
  margin-top: 0.75rem;
}

.dashboard-chip {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.45rem 0.8rem;
  font-size: 0.85rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(15, 23, 42, 0.62);
  color: var(--text-main);
}

.sidebar-brand-mark {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.95), rgba(139, 92, 246, 0.9));
}
"""
    styles_path.write_text(text)
PY

echo "Phase 4 SAVR shell and profile sync applied successfully in: $FRONTEND_DIR"
