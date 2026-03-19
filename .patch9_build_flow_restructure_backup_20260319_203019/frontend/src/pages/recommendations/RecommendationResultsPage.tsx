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

  const request = stored.request as
    | {
        outing_type?: string;
        budget?: string;
        pace?: string;
        social_context?: string;
        preferred_cuisines?: string[];
        atmosphere?: string[];
        drinks_focus?: boolean;
        fast_food?: boolean;
        requires_dine_in?: boolean;
        requires_takeout?: boolean;
        include_dish_hints?: boolean;
      }
    | undefined;

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
          <div>
            <p className="navbar-eyebrow">Recommendation results</p>
            <h1 className="page-title">Your results</h1>
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
              Back to flow
            </Button>
            <Button
              onClick={() => {
                clearRecommendationResult();
                navigate("/recommendations");
              }}
            >
              Start new search
            </Button>
          </div>
        </div>
      </section>

      <section className="grid grid-2">
        <Card
          title="Flow summary"
          subtitle="High-level context for the current recommendation set"
          actions={<Badge tone="accent">{stored.response.results.length} results</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Flow</strong>
              <p className="muted" style={{ marginBottom: 0 }}>{flowLabel}</p>
            </div>
            <div className="item">
              <strong>Generated</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                {new Date(stored.createdAt).toLocaleString()}
              </p>
            </div>
            {stored.presetContext?.name ? (
              <div className="item">
                <strong>Preset context</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {stored.presetContext.name} · {stored.presetContext.owner_type === "user" ? "user preset" : "system preset"}
                </p>
              </div>
            ) : null}
            {stored.response.request_summary ? (
              <>
                <div className="item">
                  <strong>Outing type</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.outing_type || request?.outing_type || "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Budget</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.budget || request?.budget || "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Pace</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.pace || request?.pace || "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Atmosphere</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {stored.response.request_summary.atmosphere?.length
                      ? stored.response.request_summary.atmosphere.join(", ")
                      : request?.atmosphere?.length
                      ? request.atmosphere.join(", ")
                      : "Not specified"}
                  </p>
                </div>
                <div className="item">
                  <strong>Service and hinting</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {[
                      request?.drinks_focus ? "drinks focus" : null,
                      request?.fast_food ? "fast food allowed" : null,
                      request?.requires_dine_in ? "dine-in required" : null,
                      request?.requires_takeout ? "takeout required" : null,
                      request?.include_dish_hints ? "dish hints requested" : "dish hints not requested"
                    ]
                      .filter(Boolean)
                      .join(" • ")}
                  </p>
                </div>
              </>
            ) : null}
          </div>
        </Card>

        <Card
          title="What to do next"
          subtitle="Keep the route-based flow clear and reversible"
          actions={<Badge>Navigation</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Refine this result</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Return to the originating flow to adjust the request and generate a new result set.
              </p>
            </div>
            <div className="item">
              <strong>Start a different flow</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Go back to the hub to switch between build, describe, and surprise without losing route clarity.
              </p>
            </div>
            <div className="item">
              <strong>Review saved presets</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Open your account-owned presets page if this flow should become a reusable saved configuration.
              </p>
            </div>
          </div>
        </Card>
      </section>

      <section className="grid" style={{ gap: "1rem" }}>
        {stored.response.results.length === 0 ? (
          <Card
            title="No recommendations returned"
            subtitle="The request completed, but no result cards were returned."
            actions={<Badge>0 results</Badge>}
          >
            <div className="button-row">
              <Button onClick={() => navigate(returnPath)}>Go back to the previous flow</Button>
            </div>
          </Card>
        ) : (
          stored.response.results.map((item, index) => (
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
              reasons={item.reasons}
              suggestedDishes={item.suggested_dishes}
              suggestedDrinks={item.suggested_drinks}
              activeEventMatches={item.active_event_matches}
              matchedSignals={item.matched_signals}
              penalizedSignals={item.penalized_signals}
              scoreBreakdown={item.score_breakdown}
            />
          ))
        )}
      </section>
    </div>
  );
}
