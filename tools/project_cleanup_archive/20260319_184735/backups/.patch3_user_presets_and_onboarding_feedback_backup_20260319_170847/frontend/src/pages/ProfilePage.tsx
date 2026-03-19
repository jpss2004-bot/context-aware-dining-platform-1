import { useEffect, useState } from "react";
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

function renderBadges(values: string[], tone: "default" | "accent" | "success" = "default") {
  if (values.length === 0) {
    return <p className="muted" style={{ marginBottom: 0 }}>Nothing saved yet.</p>;
  }

  return (
    <div>
      {values.map((value) => (
        <Badge key={value} tone={tone}>
          {formatLabel(value)}
        </Badge>
      ))}
    </div>
  );
}

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadProfile() {
      try {
        setError("");
        setLoading(true);
        const state = await apiRequest<OnboardingState>("/onboarding");
        if (!cancelled) {
          setProfileState(state);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your SAVR profile.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadProfile();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile</p>
        <h1 className="page-title">Your SAVR profile</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page is your dedicated profile overview. Review what SAVR knows about your tastes,
          then move into preference editing only when you actually want to update those signals.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Account summary"
          subtitle="Your saved user identity and current profile readiness"
          actions={<Badge tone="accent">Account</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Name</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user ? `${user.first_name} ${user.last_name}`.trim() : "Guest user"}
              </p>
            </div>

            <div className="item">
              <strong>Email</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user?.email || "No email available"}
              </p>
            </div>

            <div className="item">
              <strong>Profile status</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {user?.onboarding_completed ? "Ready" : "Incomplete"}
              </p>
            </div>

            <div className="button-row">
              <Link to="/profile/preferences">
                <Button>Edit profile</Button>
              </Link>
              <Link to="/dashboard">
                <Button variant="ghost">Back to dashboard</Button>
              </Link>
            </div>
          </div>
        </Card>

        <Card
          title="Preference overview"
          subtitle="A structured summary of the signals currently shaping your recommendations"
          actions={<Badge tone="success">Profile data</Badge>}
        >
          {loading ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your saved profile...</p>
          ) : !profileState ? (
            <div className="item">
              <strong>No profile data available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You can continue to the preference editor to create or update your profile.
              </p>
            </div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>Cuisine preferences</strong>
                {renderBadges(profileState.cuisine_preferences)}
              </div>

              <div className="item">
                <strong>Atmosphere preferences</strong>
                {renderBadges(profileState.atmosphere_preferences, "accent")}
              </div>

              <div className="item">
                <strong>Drink preferences</strong>
                {renderBadges(profileState.drink_preferences, "success")}
              </div>

              <div className="item">
                <strong>Favorite restaurants</strong>
                {renderBadges(profileState.favorite_restaurants)}
              </div>

              <div className="item">
                <strong>Dining note</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {profileState.bio?.trim() || "No dining note saved yet."}
                </p>
              </div>
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
