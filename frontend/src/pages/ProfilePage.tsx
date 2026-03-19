import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingState } from "../types";

type PresetSelectionPayload = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus?: boolean | null;
  atmosphere: string[];
};

type PresetResponse = {
  preset_id: string;
  owner_type: "system" | "user" | string;
  owner_user_id?: number | null;
  is_editable: boolean;
  name: string;
  description?: string | null;
  selection_payload: PresetSelectionPayload;
  created_at?: string | null;
  updated_at?: string | null;
};

function formatLabel(value: string) {
  return value
    .replace(/[_-]/g, " ")
    .split(" ")
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

function summarizePreset(preset: PresetResponse): string[] {
  const chips: string[] = [];
  if (preset.selection_payload.outing_type) chips.push(formatLabel(preset.selection_payload.outing_type));
  if (preset.selection_payload.budget) chips.push(preset.selection_payload.budget);
  if (preset.selection_payload.pace) chips.push(formatLabel(preset.selection_payload.pace));
  if (preset.selection_payload.social_context) chips.push(formatLabel(preset.selection_payload.social_context));
  preset.selection_payload.preferred_cuisines.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  return chips;
}

export default function ProfilePage() {
  const { user } = useAuth();
  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [presetLoading, setPresetLoading] = useState(true);
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

  useEffect(() => {
    let cancelled = false;

    async function loadPresets() {
      try {
        setPresetLoading(true);
        const data = await apiRequest<PresetResponse[]>("/presets");
        if (!cancelled) {
          setPresets(Array.isArray(data) ? data : []);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your presets.");
        }
      } finally {
        if (!cancelled) {
          setPresetLoading(false);
        }
      }
    }

    void loadPresets();

    return () => {
      cancelled = true;
    };
  }, []);

  const userPresets = useMemo(
    () =>
      presets.filter(
        (preset) =>
          preset.owner_type === "user" &&
          (preset.owner_user_id == null || preset.owner_user_id === user?.id)
      ),
    [presets, user?.id]
  );

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile</p>
        <h1 className="page-title">Your SAVR profile</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page is your dedicated profile overview. Review what SAVR knows about your tastes,
          your saved reusable presets, and the quickest places to update those signals.
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
              <Link to="/profile/presets">
                <Button variant="secondary">Saved presets</Button>
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

      <section className="grid">
        <Card
          title="Your saved presets"
          subtitle="Reusable personal builders saved only to your account"
          actions={<Badge tone="accent">{presetLoading ? "Loading" : `${userPresets.length} saved`}</Badge>}
        >
          {presetLoading ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your presets...</p>
          ) : userPresets.length === 0 ? (
            <div className="item">
              <strong>No custom presets saved yet</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Go to recommendations, configure the builder, and save that configuration as a reusable preset.
              </p>
              <div className="button-row" style={{ marginTop: "0.9rem" }}>
                <Link to="/recommendations/build">
                  <Button>Open build flow</Button>
                </Link>
                <Link to="/profile/presets">
                  <Button variant="secondary">Open saved presets page</Button>
                </Link>
              </div>
            </div>
          ) : (
            <div className="preset-library-grid">
              {userPresets.slice(0, 3).map((preset) => (
                <div key={preset.preset_id} className="preset-card">
                  <div className="preset-card__header">
                    <strong>{preset.name}</strong>
                    <Badge tone="success">Your preset</Badge>
                  </div>
                  <p className="muted" style={{ margin: 0 }}>
                    {preset.description || "No description saved for this preset."}
                  </p>
                  <div className="preset-chip-row">
                    {summarizePreset(preset).map((chip) => (
                      <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                        {chip}
                      </span>
                    ))}
                  </div>
                </div>
              ))}

              <div className="button-row">
                <Link to="/profile/presets">
                  <Button>View all saved presets</Button>
                </Link>
                <Link to="/recommendations/build">
                  <Button variant="secondary">Create or edit presets</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
