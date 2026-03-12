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
        title: "Atmosphere preferences",
        value: String(profileState?.atmosphere_preferences.length ?? 0),
        subtitle: "Saved mood and setting signals available for matching.",
        tone: "default" as const
      }
    ],
    [profileState]
  );

  const workflowSteps = [
    {
      title: "Review your profile",
      description:
        "Make sure your taste, pace, drink, and atmosphere selections reflect the kind of dining experience you actually want."
    },
    {
      title: "Explore restaurants",
      description:
        "Browse the restaurant catalog and confirm your favorites align with the venues available in the system."
    },
    {
      title: "Generate recommendations",
      description:
        "Use the recommendation workflow after your profile is current so the system has stronger context."
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
              your dining style, and move into recommendations when you are ready.
            </p>
          </div>

          <div>
            <Badge>SAVR</Badge>
            <Badge tone="accent">Profile-aware</Badge>
            <Badge tone="success">Ready to explore</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Find recommendations</Button>
            </Link>
            <Link to="/restaurants">
              <Button variant="ghost">Browse restaurants</Button>
            </Link>
            <Link to="/onboarding">
              <Button variant="secondary">Edit profile</Button>
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

              <div className="item">
                <strong>Dining note</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {profileState?.bio?.trim() || "No dining note saved yet."}
                </p>
              </div>
            </div>
          )}
        </Card>

        <Card
          title="Suggested next steps"
          subtitle="A simple path for users exploring the product for the first time"
          actions={<Badge tone="success">Guide</Badge>}
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
              <Button variant="ghost">Review profile</Button>
            </Link>
            <Link to="/recommendations">
              <Button>Start exploring</Button>
            </Link>
          </div>
        </Card>
      </section>
    </div>
  );
}
