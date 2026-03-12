import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  explanation?: string;
  confidenceLevel?: string;
  tags?: string[];
  ctaLabel?: string;
  onClick?: () => void;
};

function formatScore(score?: number) {
  if (score === undefined || score === null || Number.isNaN(score)) {
    return null;
  }

  return `${Math.round(score * 100)}% match`;
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

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  explanation,
  confidenceLevel,
  tags = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const scoreLabel = formatScore(score);
  const confidence = confidenceLabel(confidenceLevel);

  return (
    <Card
      className="recommendation-card"
      title={title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={
        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
          {scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : <Badge>Match pending</Badge>}
          {confidence ? <Badge tone={confidenceTone(confidenceLevel)}>{confidence}</Badge> : null}
        </div>
      }
    >
      <div className="grid" style={{ gap: "0.8rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {explanation || "A recommendation is ready, but no explanation was provided yet."}
        </p>

        {tags.length > 0 ? (
          <div>
            {tags.map((tag) => (
              <Badge key={tag} tone="accent">
                {tag}
              </Badge>
            ))}
          </div>
        ) : (
          <div>
            <Badge>Context-aware</Badge>
            <Badge tone="accent">Dining fit</Badge>
          </div>
        )}

        {onClick ? (
          <div className="button-row">
            <Button variant="ghost" onClick={onClick}>
              {ctaLabel}
            </Button>
          </div>
        ) : null}
      </div>
    </Card>
  );
}
