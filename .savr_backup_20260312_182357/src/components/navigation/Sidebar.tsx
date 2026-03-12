import { NavLink } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "OV" },
  { to: "/onboarding", label: "Onboarding", short: "ON" },
  { to: "/recommendations", label: "Recommendations", short: "RE" },
  { to: "/restaurants", label: "Restaurants", short: "RS" },
  { to: "/experiences", label: "Experiences", short: "EX" }
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
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Signed in</p>
          <span className="sidebar-online-pill">Live</span>
        </div>

        <strong className="sidebar-user-name">{userName || "Guest user"}</strong>

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
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-footer-card">
          <p className="sidebar-section-label">Workspace status</p>
          <p className="muted">UI shell upgraded and ready for deeper page-level polish.</p>
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
