import { Link, NavLink, type NavLinkRenderProps } from "react-router-dom";

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
