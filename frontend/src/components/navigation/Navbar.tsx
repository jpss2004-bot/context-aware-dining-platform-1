import { useLocation } from 'react-router-dom';

import { brandContent } from '../../config/content';

type NavbarProps = {
  userName?: string;
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content =
    brandContent.routeMeta[location.pathname as keyof typeof brandContent.routeMeta] ?? {
      eyebrow: 'Workspace',
      title: 'SAVR',
      subtitle: brandContent.strapline
    };

  const today = new Date().toLocaleDateString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric'
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
            <p className="navbar-meta-label">Active profile</p>
            <strong>{userName || 'Guest user'}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
