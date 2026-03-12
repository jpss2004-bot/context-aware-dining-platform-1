#!/bin/zsh
set -e

echo "writing RecommendationCard component..."

cat > src/components/dining/RecommendationCard.tsx <<'EOF'
import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  explanation?: string;
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

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  explanation,
  tags = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const scoreLabel = formatScore(score);

  return (
    <Card
      className="recommendation-card"
      title={title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : null}
    >
      <p className="muted">
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
      ) : null}

      {onClick ? (
        <Button variant="ghost" onClick={onClick}>
          {ctaLabel}
        </Button>
      ) : null}
    </Card>
  );
}
EOF

echo "RecommendationCard component written"
