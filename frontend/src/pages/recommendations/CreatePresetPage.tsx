import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import { createPreset, type PresetSelectionPayload } from "../../lib/recommendationFlow";

type CreatePresetState = {
  name: string;
  description: string;
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
};

const outingOptions = [
  "casual-bite",
  "date-night",
  "group-dinner",
  "drinks-night",
  "quick-bite",
  "coffee-stop",
  "special-occasion"
];

const budgetOptions = ["", "$", "$$", "$$$"];
const paceOptions = ["", "fast", "moderate", "slow", "leisurely"];
const socialOptions = ["", "solo", "friends", "group", "date"];

export default function CreatePresetPage() {
  const navigate = useNavigate();

  const [form, setForm] = useState<CreatePresetState>({
    name: "",
    description: "",
    outing_type: "casual-bite",
    budget: "$$",
    pace: "moderate",
    social_context: "friends"
  });

  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [saving, setSaving] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");

    if (!form.name.trim()) {
      setError("Preset name is required.");
      return;
    }

    setSaving(true);

    try {
      const payload: PresetSelectionPayload = {
        outing_type: form.outing_type,
        budget: form.budget || null,
        pace: form.pace || null,
        social_context: form.social_context || null,
        preferred_cuisines: [],
        atmosphere: [],
        drinks_focus: false,
        include_dish_hints: true
      };

      await createPreset({
        name: form.name.trim(),
        description: form.description.trim() || null,
        selection_payload: payload
      });

      setSuccess("Preset created successfully.");
      setTimeout(() => {
        navigate("/recommendations/build/presets");
      }, 700);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create preset.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Preset creation</p>
        <h1 className="page-title">Create a new preset</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Create a reusable preset first, then return to the preset library to generate recommendations from it.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <Card
        title="Preset setup"
        subtitle="Create a reusable starting point"
        actions={<Badge tone="accent">New preset</Badge>}
      >
        <form className="form" style={{ gap: "1rem" }} onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="preset_name">Preset name</label>
            <input
              id="preset_name"
              value={form.name}
              onChange={(e) => setForm((current) => ({ ...current, name: e.target.value }))}
              placeholder="Weekend group dinner"
            />
          </div>

          <div className="form-row">
            <label htmlFor="preset_description">Description</label>
            <textarea
              id="preset_description"
              rows={4}
              value={form.description}
              onChange={(e) => setForm((current) => ({ ...current, description: e.target.value }))}
              placeholder="What kind of outing is this preset designed for?"
            />
          </div>

          <div className="grid grid-2">
            <div className="form-row">
              <label htmlFor="outing_type">Outing type</label>
              <select
                id="outing_type"
                value={form.outing_type}
                onChange={(e) => setForm((current) => ({ ...current, outing_type: e.target.value }))}
              >
                {outingOptions.map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label htmlFor="budget">Budget</label>
              <select
                id="budget"
                value={form.budget}
                onChange={(e) => setForm((current) => ({ ...current, budget: e.target.value }))}
              >
                {budgetOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label htmlFor="pace">Pace</label>
              <select
                id="pace"
                value={form.pace}
                onChange={(e) => setForm((current) => ({ ...current, pace: e.target.value }))}
              >
                {paceOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label htmlFor="social_context">Social context</label>
              <select
                id="social_context"
                value={form.social_context}
                onChange={(e) => setForm((current) => ({ ...current, social_context: e.target.value }))}
              >
                {socialOptions.map((option) => (
                  <option key={option} value={option}>
                    {option || "No preference"}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="button-row">
            <Button type="button" variant="ghost" onClick={() => navigate("/recommendations/build/presets")}>
              Back
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Create preset"}
            </Button>
          </div>
        </form>
      </Card>
    </div>
  );
}
