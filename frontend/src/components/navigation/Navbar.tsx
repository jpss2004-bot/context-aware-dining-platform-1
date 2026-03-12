import { useLocation } from "react-router-dom";

type NavbarProps = {
  userName?: string;
};

const titleMap: Record<
  string,
  { eyebrow: string; title: string; subtitle: string }
> = {
  "/dashboard": {
    eyebrow: "Home",
    title: "Your SAVR dashboard",
    subtitle:
      "Review your saved dining preferences, check profile readiness, and continue into recommendations."
  },
  "/onboarding": {
    eyebrow: "Profile",
    title: "Update your dining profile",
    subtitle:
      "Tell SAVR more about your tastes, habits, and ideal dining atmosphere."
  },
  "/recommendations": {
    eyebrow: "Recommendations",
    title: "Find your next dining match",
    subtitle:
      "Explore dining recommendations shaped by your profile, preferences, and context."
  },
  "/restaurants": {
    eyebrow: "Restaurants",
    title: "Browse available venues",
    subtitle:
      "Review the restaurant catalog and discover places that may fit your dining style."
  },
  "/experiences": {
    eyebrow: "Experiences",
    title: "Track dining memories",
    subtitle:
      "Review and log dining experiences to help strengthen future recommendations."
  }
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content = titleMap[location.pathname] ?? {
    eyebrow: "Workspace",
    title: "SAVR",
    subtitle: "A cleaner dining discovery workspace designed for real user testing."
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
            <p className="navbar-meta-label">Signed in</p>
            <strong>{userName || "Guest user"}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
