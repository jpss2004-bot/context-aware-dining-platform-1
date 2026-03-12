import { NavLink } from 'react-router-dom';

import { brandContent } from '../../config/content';

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">SV</div>

        <div>
          <p className="sidebar-eyebrow">{brandContent.tagline}</p>
          <h1 className="sidebar-brand">{brandContent.productName}</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Signed in</p>
          <span className="sidebar-online-pill">Live</span>
        </div>

        <strong className="sidebar-user-name">{userName || 'Guest user'}</strong>

        <p className="muted">A personal dining assistant for the nights you want to savor.</p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {brandContent.nav.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              ['sidebar-link', isActive ? 'sidebar-link--active' : '']
                .filter(Boolean)
                .join(' ')
            }
          >
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-footer-card">
          <p className="sidebar-section-label">Brand note</p>
          <p className="muted">Warm, curated, and discovery-led — without changing routes, features, or backend behavior.</p>
        </div>

        <button className="ui-button ui-button--ghost ui-button--md ui-button--full sidebar-logout" type="button" onClick={onLogout}>
          Leave SAVR
        </button>
      </div>
    </aside>
  );
}
