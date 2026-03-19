import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";

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

function summarizePreset(preset: PresetResponse): string[] {
  const chips: string[] = [];
  if (preset.selection_payload.outing_type) chips.push(formatLabel(preset.selection_payload.outing_type));
  if (preset.selection_payload.budget) chips.push(preset.selection_payload.budget);
  if (preset.selection_payload.pace) chips.push(formatLabel(preset.selection_payload.pace));
  if (preset.selection_payload.social_context) chips.push(formatLabel(preset.selection_payload.social_context));
  preset.selection_payload.preferred_cuisines.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  preset.selection_payload.atmosphere.slice(0, 2).forEach((value) => chips.push(formatLabel(value)));
  if (preset.selection_payload.drinks_focus) chips.push("Drinks");
  return chips.slice(0, 8);
}

export default function SavedPresetsPage() {
  const { user } = useAuth();

  const [savedContent, setSavedContent] = useState<SavedContentResponse | null>(null);
  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loadingSavedContent, setLoadingSavedContent] = useState(true);
  const [loadingPresets, setLoadingPresets] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadSavedContent() {
      try {
        setError("");
        const data = await apiRequest<SavedContentResponse>("/users/me/saved-content");
        if (!cancelled) {
          setSavedContent(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load your saved content.");
        }
      } finally {
        if (!cancelled) {
          setLoadingSavedContent(false);
        }
      }
    }

    void loadSavedContent();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadPresets() {
      try {
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
          setLoadingPresets(false);
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
        <p className="navbar-eyebrow">Account-owned presets</p>
        <h1 className="page-title">Saved presets</h1>
        <p className="muted" style={{ maxWidth: "800px", marginBottom: 0 }}>
          This page is a dedicated account-level surface for presets saved to your user account.
          It only shows presets marked as user-owned, and when an owner id is present it is matched
          against your current signed-in account before display.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Account summary"
          subtitle="Quick counts for presets and saved dining signals"
          actions={<Badge tone="accent">Saved content</Badge>}
        >
          {loadingSavedContent ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading saved content...</p>
          ) : (
            <div className="list">
              <div className="item">
                <strong>User presets</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.user_presets.length ?? 0} saved
                </p>
              </div>
              <div className="item">
                <strong>Favorite restaurants</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.favorite_restaurants.length ?? 0} saved
                </p>
              </div>
              <div className="item">
                <strong>Favorite dining experiences</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {savedContent?.favorite_dining_experiences.length ?? 0} saved
                </p>
              </div>
              <div className="button-row">
                <Link to="/recommendations/build">
                  <Button>Open build flow</Button>
                </Link>
                <Link to="/profile">
                  <Button variant="secondary">Back to profile</Button>
                </Link>
              </div>
            </div>
          )}
        </Card>

        <Card
          title="Recent experience context"
          subtitle="Useful recent dining activity that may inform future preset changes"
          actions={<Badge tone="success">History</Badge>}
        >
          {loadingSavedContent ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading recent experiences...</p>
          ) : !savedContent?.recent_experiences.length ? (
            <p className="muted" style={{ marginBottom: 0 }}>
              No recent experiences saved yet.
            </p>
          ) : (
            <div className="list">
              {savedContent.recent_experiences.slice(0, 4).map((experience) => (
                <div className="item" key={experience.experience_id}>
                  <strong>{experience.title || "Untitled experience"}</strong>
                  <p className="muted" style={{ margin: "0.35rem 0 0" }}>
                    {experience.restaurant_name || "Unknown venue"}
                    {typeof experience.overall_rating === "number"
                      ? ` · Rating ${experience.overall_rating.toFixed(1)}`
                      : ""}
                  </p>
                </div>
              ))}
            </div>
          )}
        </Card>
      </section>

      <section className="grid">
        <Card
          title="Your account-owned presets"
          subtitle="Only user presets are shown here, with an extra owner check when available"
          actions={<Badge tone="accent">{loadingPresets ? "Loading" : `${userPresets.length} visible`}</Badge>}
        >
          {loadingPresets ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading presets...</p>
          ) : userPresets.length === 0 ? (
            <div className="item">
              <strong>No user presets available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Create one from the build flow and it will appear here after save.
              </p>
              <div className="button-row" style={{ marginTop: "0.9rem" }}>
                <Link to="/recommendations/build">
                  <Button>Create a preset</Button>
                </Link>
              </div>
            </div>
          ) : (
            <div className="preset-library-grid">
              {userPresets.map((preset) => (
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

                  <div className="saved-preset-meta">
                    <span>Preset id: {preset.preset_id}</span>
                    <span>
                      Updated:{" "}
                      {preset.updated_at ? new Date(preset.updated_at).toLocaleString() : "Unknown"}
                    </span>
                  </div>

                  <div className="button-row">
                    <Link to="/recommendations/build">
                      <Button>Open build flow</Button>
                    </Link>
                    <Link to="/profile">
                      <Button variant="secondary">Back to profile</Button>
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
