#!/bin/zsh
set -e

echo "writing navigation components..."

mkdir -p src/components/navigation

cat > src/components/navigation/Sidebar.tsx <<'EOF'
import { NavLink } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard" },
  { to: "/onboarding", label: "Onboarding" },
  { to: "/recommendations", label: "Recommendations" },
  { to: "/restaurants", label: "Restaurants" },
  { to: "/experiences", label: "Experiences" }
];

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">CA</div>

        <div>
          <p className="sidebar-eyebrow">Dining Intelligence</p>
          <h1 className="sidebar-brand">Context-Aware Dining</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <p className="sidebar-section-label">Signed in</p>
        <strong>{userName || "Guest user"}</strong>
        <p className="muted">
          Taste-led restaurant discovery and recommendation workflows.
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
            <span className="sidebar-link__dot" />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
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

cat > src/components/navigation/Navbar.tsx <<'EOF'
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
    title: "Dining command center",
    subtitle:
      "Track onboarding, jump into recommendation modes, and keep the product feeling polished."
  },
  "/onboarding": {
    eyebrow: "Profile setup",
    title: "Taste and preference onboarding",
    subtitle:
      "Capture the signals that drive more accurate recommendation outputs."
  },
  "/recommendations": {
    eyebrow: "Recommendation studio",
    title: "Plan the right dining experience",
    subtitle:
      "Run build-your-night, describe-your-night, and surprise-me flows from one workspace."
  },
  "/restaurants": {
    eyebrow: "Discovery",
    title: "Restaurant browsing",
    subtitle:
      "Inspect seeded venues, compare details, and explore the dining catalog."
  },
  "/experiences": {
    eyebrow: "Memory layer",
    title: "Dining experience history",
    subtitle:
      "Log visits, preserve context, and strengthen future recommendations."
  }
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content = titleMap[location.pathname] ?? {
    eyebrow: "Workspace",
    title: "Context-Aware Dining Platform",
    subtitle:
      "Premium recommendation workflows with a cleaner dashboard shell."
  };

  return (
    <header className="app-navbar">
      <div>
        <p className="navbar-eyebrow">{content.eyebrow}</p>
        <h2 className="navbar-title">{content.title}</h2>
        <p className="navbar-subtitle">{content.subtitle}</p>
      </div>

      <div className="navbar-meta-card">
        <span className="status-dot" />
        <div>
          <p className="navbar-meta-label">Active profile</p>
          <strong>{userName || "Guest user"}</strong>
        </div>
      </div>
    </header>
  );
}
EOF

echo "navigation components written"
