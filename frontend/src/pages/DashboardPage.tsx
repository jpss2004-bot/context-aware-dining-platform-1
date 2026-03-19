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

type SavedContentResponse = {
  favorite_restaurants: string[];
  favorite_dining_experiences: string[];
  user_presets: Array<{
    preset_id: string;
    name: string;
    description?: string | null;
    updated_at: string;
  }>;
  recent_experiences: Array<{
    experience_id: number;
    title?: string | null;
    restaurant_name?: string | null;
    overall_rating?: number | null;
    created_at: string;
  }>;
};

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "Guest";

  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [savedContent, setSavedContent] = useState<SavedContentResponse | null>(null);
  const [profileError, setProfileError] = useState("");
  const [savedContentError, setSavedContentError] = useState("");
  const [isLoadingProfile, setIsLoadingProfile] = useState(true);
  const [isLoadingSavedContent, setIsLoadingSavedContent] = useState(true);

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

  useEffect(() => {
    let cancelled = false;

    async function loadSavedContent() {
      try {
        const data = await apiRequest<SavedContentResponse>("/users/me/saved-content");
        if (!cancelled) {
          setSavedContent(data);
        }
      } catch (err) {
        if (!cancelled) {
          setSavedContentError(
            err instanceof Error ? err.message : "We could not load your saved content summary."
          );
        }
      } finally {
        if (!cancelled) {
          setIsLoadingSavedContent(false);
        }
      }
    }

    void loadSavedContent();

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
        title: "Saved presets",
        value: String(savedContent?.user_presets.length ?? 0),
        subtitle: "Reusable builder configurations saved only to your account.",
        tone: "default" as const
      }
    ],
    [profileState, savedContent]
  );

  const workflowSteps = [
    {
      title: "Review your profile",
      description:
        "Visit your dedicated profile page to review saved signals and decide what to refine."
    },
    {
      title: "Review your saved presets",
      description:
        "Open the new saved-presets page to inspect account-owned presets and return to editing quickly."
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
              your dining style, inspect saved presets, and move into the parts of the product
              that now live on their own dedicated pages.
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
            <Link to="/profile/presets">
              <Button variant="ghost">Open saved presets</Button>
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
          title="Saved content access"
          subtitle="Direct routes into reusable account-owned recommendation data"
          actions={<Badge tone="success">Account data</Badge>}
        >
          {isLoadingSavedContent ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading saved content...</p>
          ) : savedContentError ? (
            <div className="error">{savedContentError}</div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>User presets</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.user_presets.length ?? 0} saved to your account
                </p>
              </div>

              <div className="item">
                <strong>Recent experiences</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.recent_experiences.length ?? 0} recent entries
                </p>
              </div>

              <div className="item">
                <strong>Favorite dining experiences</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.favorite_dining_experiences.length ?? 0} saved
                </p>
              </div>

              <div className="button-row">
                <Link to="/profile/presets">
                  <Button>Open saved presets</Button>
                </Link>
                <Link to="/recommendations/build">
                  <Button variant="secondary">Build from a preset</Button>
                </Link>
                <Link to="/experiences">
                  <Button variant="ghost">View history</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>
      </section>

      <section className="grid">
        <Card
          title="Suggested next steps"
          subtitle="A cleaner path through the app for real product testing"
          actions={<Badge tone="accent">Guide</Badge>}
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
        </Card>
      </section>
    </div>
  );
}
