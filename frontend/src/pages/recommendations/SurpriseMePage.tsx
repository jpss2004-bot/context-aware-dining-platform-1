import { useState } from "react";
import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  runSurpriseMe,
  saveRecommendationResult
} from "../../lib/recommendationFlow";

export default function SurpriseMePage() {
  const navigate = useNavigate();
  const [includeDrinks, setIncludeDrinks] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSurprise() {
    setLoading(true);
    setError("");

    try {
      const response = await runSurpriseMe({ include_drinks: includeDrinks });

      saveRecommendationResult({
        mode: "surprise",
        createdAt: new Date().toISOString(),
        request: { include_drinks: includeDrinks },
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
            <p className="navbar-eyebrow">Surprise flow</p>
            <h1 className="page-title">Surprise Me</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Fastest path to a new dining suggestion without extra scrolling or clutter.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
          </div>
        </div>
      </section>

      <Card
        title="Generate a surprise set"
        subtitle="Minimal input, separate output page"
        actions={<Badge tone="accent">Fast flow</Badge>}
      >
        {error ? <div className="error">{error}</div> : null}

        <div className="list">
          <div className="item">
            <strong>Include drinks-friendly places?</strong>
            <div className="button-row" style={{ marginTop: "0.75rem" }}>
              <Button
                variant={includeDrinks ? "primary" : "secondary"}
                onClick={() => setIncludeDrinks(true)}
              >
                Yes
              </Button>
              <Button
                variant={!includeDrinks ? "primary" : "secondary"}
                onClick={() => setIncludeDrinks(false)}
              >
                No
              </Button>
            </div>
          </div>

          <div className="button-row">
            <Button onClick={handleSurprise} disabled={loading}>
              {loading ? "Generating..." : "Generate surprise recommendations"}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
}
