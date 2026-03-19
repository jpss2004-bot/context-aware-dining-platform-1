import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  applyPreset,
  listPresets,
  saveRecommendationResult,
  type PresetResponse,
  runBuildNight
} from "../../lib/recommendationFlow";

function summarizePreset(preset: PresetResponse): string[] {
  const payload = preset.selection_payload;
  const chips: string[] = [];

  if (payload.outing_type) chips.push(payload.outing_type);
  if (payload.budget) chips.push(payload.budget);
  if (payload.pace) chips.push(payload.pace);
  if (payload.social_context) chips.push(payload.social_context);
  if (payload.preferred_cuisines?.length) chips.push(...payload.preferred_cuisines.slice(0, 2));
  if (payload.atmosphere?.length) chips.push(...payload.atmosphere.slice(0, 2));

  return chips.slice(0, 6);
}

export default function SelectPresetPage() {
  const navigate = useNavigate();

  const [presets, setPresets] = useState<PresetResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [applyingPresetId, setApplyingPresetId] = useState<string | null>(null);
  const [error, setError] = useState("");

  const grouped = useMemo(
    () => ({
      system: presets.filter((preset) => preset.owner_type !== "user"),
      user: presets.filter((preset) => preset.owner_type === "user")
    }),
    [presets]
  );

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        setError("");
        const data = await listPresets();
        if (!cancelled) {
          setPresets(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load presets.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      cancelled = true;
    };
  }, []);

  async function handleGenerateFromPreset(preset: PresetResponse) {
    setApplyingPresetId(preset.preset_id);
    setError("");

    try {
      const applied = await applyPreset(preset.preset_id);
      const payload = applied.builder_payload;

      const response = await runBuildNight({
        outing_type: payload.outing_type || "casual-bite",
        budget: payload.budget || undefined,
        pace: payload.pace || undefined,
        social_context: payload.social_context || undefined,
        preferred_cuisines: payload.preferred_cuisines || [],
        atmosphere: payload.atmosphere || [],
        drinks_focus: Boolean(payload.drinks_focus),
        fast_food: Boolean(payload.fast_food),
        requires_dine_in: Boolean(payload.requires_dine_in),
        requires_takeout: Boolean(payload.requires_takeout),
        include_dish_hints: payload.include_dish_hints !== false
      });

      saveRecommendationResult({
        mode: "build",
        flowLabel: "Build Your Night",
        originPath: "/recommendations/build/presets",
        createdAt: new Date().toISOString(),
        request: applied.builder_payload,
        response,
        presetContext: {
          preset_id: applied.preset.preset_id,
          name: applied.preset.name,
          owner_type: applied.preset.owner_type,
          can_customize: applied.can_customize
        }
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate from preset.");
    } finally {
      setApplyingPresetId(null);
    }
  }

  function renderPresetCard(preset: PresetResponse) {
    const busy = applyingPresetId === preset.preset_id;

    return (
      <div key={preset.preset_id} className="item">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <strong>{preset.name}</strong>
            <p className="muted" style={{ margin: "0.35rem 0 0" }}>
              {preset.description || "No description provided."}
            </p>
            <div className="preset-chip-row" style={{ marginTop: "0.7rem" }}>
              {summarizePreset(preset).map((chip) => (
                <span key={`${preset.preset_id}-${chip}`} className="preset-chip">
                  {chip}
                </span>
              ))}
            </div>
          </div>

          <Badge tone={preset.owner_type === "user" ? "success" : "accent"}>
            {preset.owner_type === "user" ? "Your preset" : "System preset"}
          </Badge>
        </div>

        <div className="button-row" style={{ marginTop: "0.85rem" }}>
          <Button onClick={() => handleGenerateFromPreset(preset)} disabled={busy}>
            {busy ? "Generating..." : "Generate recommendations"}
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Preset library</p>
        <h1 className="page-title">Select your preset</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Choose from available presets, or create a new preset before generating recommendations.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Button variant="ghost" onClick={() => navigate("/recommendations/build")}>
          Back
        </Button>
        <Button onClick={() => navigate("/recommendations/build/presets/new")}>
          Create new preset
        </Button>
      </div>

      {loading ? (
        <Card title="Loading presets" subtitle="Fetching available presets." actions={<Badge>Loading</Badge>} />
      ) : (
        <section className="grid grid-2">
          <Card
            title="Your presets"
            subtitle="Saved reusable presets tied to your account"
            actions={<Badge tone="success">{grouped.user.length}</Badge>}
          >
            {grouped.user.length === 0 ? (
              <p className="muted" style={{ marginBottom: 0 }}>No user presets saved yet.</p>
            ) : (
              <div className="list">{grouped.user.map(renderPresetCard)}</div>
            )}
          </Card>

          <Card
            title="System presets"
            subtitle="Built-in starter presets"
            actions={<Badge tone="accent">{grouped.system.length}</Badge>}
          >
            {grouped.system.length === 0 ? (
              <p className="muted" style={{ marginBottom: 0 }}>No system presets available.</p>
            ) : (
              <div className="list">{grouped.system.map(renderPresetCard)}</div>
            )}
          </Card>
        </section>
      )}
    </div>
  );
}
