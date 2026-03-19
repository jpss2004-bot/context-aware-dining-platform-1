import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  runDescribeNight,
  saveRecommendationResult
} from "../../lib/recommendationFlow";

export default function DescribeNightPage() {
  const navigate = useNavigate();
  const [prompt, setPrompt] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");

    try {
      const response = await runDescribeNight({ prompt });

      saveRecommendationResult({
        mode: "describe",
        createdAt: new Date().toISOString(),
        request: { prompt },
        response
      });

      navigate("/recommendations/results");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate recommendations.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Describe flow</p>
            <h1 className="page-title">Describe the Night</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Write the vibe you want here, then see only the recommendation cards on the next page.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
          </div>
        </div>
      </section>

      <form onSubmit={handleSubmit}>
        <Card
          title="Describe your ideal night"
          subtitle="Natural-language request only, without extra clutter"
          actions={<Badge tone="accent">Prompt flow</Badge>}
        >
          {error ? <div className="error">{error}</div> : null}

          <div className="form" style={{ gap: "1rem" }}>
            <div className="form-row">
              <label htmlFor="describe_prompt">Prompt</label>
              <textarea
                id="describe_prompt"
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="I want a cozy dinner spot with good drinks, relaxed pacing, and food that feels memorable without being too formal..."
                rows={8}
              />
            </div>

            <div className="button-row">
              <Button type="submit" disabled={loading || prompt.trim().length < 3}>
                {loading ? "Interpreting..." : "Generate recommendations"}
              </Button>
            </div>
          </div>
        </Card>
      </form>
    </div>
  );
}
