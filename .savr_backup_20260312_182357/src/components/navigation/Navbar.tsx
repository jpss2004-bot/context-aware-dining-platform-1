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
    subtitle: "Premium recommendation workflows with a cleaner dashboard shell."
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
            <p className="navbar-meta-label">Active profile</p>
            <strong>{userName || "Guest user"}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
