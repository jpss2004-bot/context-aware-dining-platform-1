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
  return [restaurant.city, restaurant.price_tier, restaurant.pace || "pace not set"]
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
          <Badge>Food-first</Badge>
        )
      }
    >
      <div className="grid" style={{ gap: "0.85rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {restaurant.description || "No description available yet for this restaurant."}
        </p>

        <div>
          {restaurant.atmosphere ? <Badge>{restaurant.atmosphere}</Badge> : null}
          {restaurant.social_style ? <Badge tone="accent">{restaurant.social_style}</Badge> : null}
          {restaurant.pace ? <Badge tone="success">{restaurant.pace}</Badge> : null}
        </div>

        {onSelect ? (
          <div className="button-row">
            <Button
              variant={isActive ? "secondary" : "ghost"}
              onClick={() => onSelect(restaurant.id)}
            >
              {isActive ? "Selected" : "View details"}
            </Button>
          </div>
        ) : null}
      </div>
    </Card>
  );
}
