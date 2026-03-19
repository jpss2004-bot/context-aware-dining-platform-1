import { useMemo } from "react";
import { useNavigate } from "react-router-dom";

import RecommendationCard from "../../components/dining/RecommendationCard";
import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import {
  clearRecommendationResult,
  loadRecommendationResult,
  normalizeRecommendationScore
} from "../../lib/recommendationFlow";

export default function RecommendationResultsPage() {
  const navigate = useNavigate();
  const stored = useMemo(() => loadRecommendationResult(), []);

  const maxScore = useMemo(() => {
    const scores = (stored?.response.results || [])
      .map((item) => item.score)
      .filter((score) => Number.isFinite(score));
    if (scores.length === 0) return 1;
    return Math.max(...scores, 1);
  }, [stored]);

  if (!stored) {
    return (
      <Card
        title="No recommendation results found"
        subtitle="Start from the recommendation hub to generate a new result page."
        actions={<Badge>Empty</Badge>}
      >
        <div className="button-row">
          <Button onClick={() => navigate("/recommendations")}>Go to recommendation hub</Button>
        </div>
      </Card>
    );
  }

  const returnPath =
    stored.originPath ||
    (stored.mode === "build"
      ? "/recommendations/build"
      : stored.mode === "describe"
      ? "/recommendations/describe"
      : "/recommendations/surprise");

  const flowLabel =
    stored.flowLabel ||
    (stored.mode === "build"
      ? "Build Your Night"
      : stored.mode === "describe"
      ? "Describe the Night"
      : "Surprise Me");

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Top recommendations</p>
            <h1 className="page-title">Your top dining recommendations</h1>
            <p className="muted" style={{ marginBottom: 0 }}>
              Generated from <strong>{flowLabel}</strong>
              {stored.presetContext?.name ? ` using preset "${stored.presetContext.name}"` : ""}.
            </p>
          </div>

          <div className="button-row">
            <Button variant="ghost" onClick={() => navigate("/recommendations")}>
              Back to hub
            </Button>
            <Button variant="secondary" onClick={() => navigate(returnPath)}>
              Back to previous step
            </Button>
            <Button
              onClick={() => {
                clearRecommendationResult();
                navigate("/recommendations");
              }}
            >
              Start again
            </Button>
          </div>
        </div>
      </section>

      <Card
        title="Recommendation summary"
        subtitle="Your top 10 ranked options from the current flow"
        actions={<Badge tone="accent">{stored.response.results.length} results</Badge>}
      >
        <p className="muted" style={{ marginBottom: 0 }}>
          The cards below show the highest-ranked results returned by the current recommendation request.
        </p>
      </Card>

      <section className="grid" style={{ gap: "1rem" }}>
        {stored.response.results.slice(0, 10).map((item, index) => (
          <RecommendationCard
            key={`${item.restaurant_id}-${index}`}
            title={item.restaurant_name || `Recommendation ${index + 1}`}
            restaurantName={item.restaurant_name}
            rank={item.rank}
            fitLabel={item.fit_label}
            score={normalizeRecommendationScore(item.score, maxScore)}
            explanation={
              item.explanation ||
              (item.reasons && item.reasons.length > 0
                ? item.reasons.join(" • ")
                : "This restaurant matched your current dining request.")
            }
            confidenceLevel={item.confidence_level}
            suggestedDishes={item.suggested_dishes}
            suggestedDrinks={item.suggested_drinks}
            activeEventMatches={item.active_event_matches}
            matchedSignals={item.matched_signals}
            penalizedSignals={item.penalized_signals}
            scoreBreakdown={item.score_breakdown}
          />
        ))}
      </section>
    </div>
  );
}
