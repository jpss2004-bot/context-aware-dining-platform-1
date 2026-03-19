import { useState } from "react";

import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";
import { ScoreBreakdownItem } from "../../types";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  rank?: number;
  fitLabel?: string;
  explanation?: string;
  confidenceLevel?: string;
  tags?: string[];
  matchedSignals?: string[];
  penalizedSignals?: string[];
  scoreBreakdown?: ScoreBreakdownItem[];
  suggestedDishes?: string[];
  suggestedDrinks?: string[];
  activeEventMatches?: string[];
  ctaLabel?: string;
  onClick?: () => void;
};

function formatScore(score?: number) {
  if (score === undefined || score === null || Number.isNaN(score)) {
    return null;
  }

  const clamped = Math.max(0, Math.min(score, 1));
  return `${Math.round(clamped * 100)}% match`;
}

function confidenceTone(confidenceLevel?: string): "default" | "accent" | "success" | "warning" {
  switch ((confidenceLevel || "").toLowerCase()) {
    case "high":
      return "success";
    case "medium":
      return "accent";
    case "exploratory":
      return "warning";
    default:
      return "default";
  }
}

function confidenceLabel(confidenceLevel?: string): string | null {
  if (!confidenceLevel) {
    return null;
  }

  if (confidenceLevel === "high") {
    return "High confidence";
  }

  if (confidenceLevel === "medium") {
    return "Medium confidence";
  }

  if (confidenceLevel === "exploratory") {
    return "Exploratory";
  }

  return confidenceLevel;
}

function fitTone(fitLabel?: string): "default" | "accent" | "success" | "warning" {
  switch ((fitLabel || "").toLowerCase()) {
    case "excellent fit":
      return "success";
    case "strong fit":
      return "accent";
    case "possible fit":
      return "warning";
    default:
      return "default";
  }
}

function formatBreakdownPoints(points: number): string {
  return `${points >= 0 ? "+" : ""}${points.toFixed(2)}`;
}

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  rank,
  fitLabel,
  explanation,
  confidenceLevel,
  tags = [],
  matchedSignals = [],
  penalizedSignals = [],
  scoreBreakdown = [],
  suggestedDishes = [],
  suggestedDrinks = [],
  activeEventMatches = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const [expanded, setExpanded] = useState(false);
  const scoreLabel = formatScore(score);
  const confidence = confidenceLabel(confidenceLevel);

  return (
    <Card
      className="recommendation-card"
      title={rank ? `#${rank} • ${title}` : title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={
        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
          {scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : <Badge>Match pending</Badge>}
          {fitLabel ? <Badge tone={fitTone(fitLabel)}>{fitLabel}</Badge> : null}
          {confidence ? <Badge tone={confidenceTone(confidenceLevel)}>{confidence}</Badge> : null}
        </div>
      }
    >
      <div className="grid" style={{ gap: "0.9rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {explanation || "A recommendation is ready, but no explanation was provided yet."}
        </p>

        {tags.length > 0 ? (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            {tags.map((tag) => (
              <Badge key={tag} tone="accent">
                {tag}
              </Badge>
            ))}
          </div>
        ) : (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            <Badge>Context-aware</Badge>
            <Badge tone="accent">Dining fit</Badge>
          </div>
        )}

        <div className="button-row" style={{ marginTop: 0 }}>
          <Button variant="ghost" onClick={() => setExpanded((prev) => !prev)}>
            {expanded ? "Hide scoring detail" : "Show scoring detail"}
          </Button>

          {onClick ? (
            <Button variant="ghost" onClick={onClick}>
              {ctaLabel}
            </Button>
          ) : null}
        </div>

        {expanded ? (
          <div className="grid" style={{ gap: "0.85rem" }}>
            {activeEventMatches.length > 0 ? (
              <div className="item">
                <strong>Event matches</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {activeEventMatches.map((eventMatch) => (
                    <Badge key={eventMatch} tone="accent">
                      {eventMatch}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {suggestedDishes.length > 0 ? (
              <div className="item">
                <strong>Suggested dishes</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {suggestedDishes.map((dish) => (
                    <Badge key={dish} tone="success">
                      {dish}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {suggestedDrinks.length > 0 ? (
              <div className="item">
                <strong>Suggested drinks</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {suggestedDrinks.map((drink) => (
                    <Badge key={drink} tone="accent">
                      {drink}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {matchedSignals.length > 0 ? (
              <div className="item">
                <strong>Matched signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {matchedSignals.map((signal) => (
                    <Badge key={signal} tone="success">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {penalizedSignals.length > 0 ? (
              <div className="item">
                <strong>Penalized signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {penalizedSignals.map((signal) => (
                    <Badge key={signal} tone="warning">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {scoreBreakdown.length > 0 ? (
              <div className="item">
                <strong>Score breakdown</strong>
                <div style={{ display: "grid", gap: "0.45rem", marginTop: "0.6rem" }}>
                  {scoreBreakdown.map((entry) => (
                    <div
                      key={`${entry.label}-${entry.points}`}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        gap: "1rem",
                        padding: "0.55rem 0.7rem",
                        borderRadius: "0.75rem",
                        background: "rgba(15, 23, 42, 0.35)",
                        border: "1px solid rgba(148, 163, 184, 0.15)"
                      }}
                    >
                      <span>{entry.label}</span>
                      <strong>{formatBreakdownPoints(entry.points)}</strong>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>
    </Card>
  );
}
