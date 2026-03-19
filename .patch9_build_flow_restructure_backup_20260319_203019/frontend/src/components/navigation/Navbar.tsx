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
