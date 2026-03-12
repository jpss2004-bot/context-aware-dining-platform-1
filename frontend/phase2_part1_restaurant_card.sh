#!/bin/zsh
set -e

echo "writing RestaurantCard component..."

cat > src/components/dining/RestaurantCard.tsx <<'EOF'
import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";
import { RestaurantListItem } from "../../types";

type RestaurantCardProps = {
  restaurant: RestaurantListItem;
  onSelect?: (restaurantId: number) => void;
  isActive?: boolean;
};

function buildMeta(restaurant: RestaurantListItem) {
  return [
    restaurant.city,
    restaurant.price_tier,
    restaurant.pace || "pace not set"
  ]
    .filter(Boolean)
    .join(" • ");
}

export default function RestaurantCard({
  restaurant,
  onSelect,
  isActive = false
}: RestaurantCardProps) {
  return (
    <Card
      className={isActive ? "restaurant-card restaurant-card--active" : "restaurant-card"}
      title={restaurant.name}
      subtitle={buildMeta(restaurant)}
      actions={
        restaurant.serves_alcohol ? (
          <Badge tone="accent">Drinks</Badge>
        ) : (
          <Badge tone="default">Food-first</Badge>
        )
      }
    >
      <p className="muted">
        {restaurant.description || "No description available yet for this restaurant."}
      </p>

      <div>
        {restaurant.atmosphere ? <Badge>{restaurant.atmosphere}</Badge> : null}
        {restaurant.social_style ? <Badge tone="accent">{restaurant.social_style}</Badge> : null}
        {restaurant.pace ? <Badge tone="success">{restaurant.pace}</Badge> : null}
      </div>

      {onSelect ? (
        <Button
          variant={isActive ? "secondary" : "ghost"}
          onClick={() => onSelect(restaurant.id)}
        >
          {isActive ? "Selected" : "View details"}
        </Button>
      ) : null}
    </Card>
  );
}
EOF

echo "RestaurantCard component written"
