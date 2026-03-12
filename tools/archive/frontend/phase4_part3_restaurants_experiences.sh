#!/bin/zsh
set -e

echo "applying phase 4 restaurants + experiences refinement..."

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
EOF

cat > src/components/dining/ExperienceCard.tsx <<'EOF'
import Badge from "../ui/Badge";
import Card from "../ui/Card";
import { Experience } from "../../types";

type ExperienceCardProps = {
  experience: Experience;
};

function formatDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
}

export default function ExperienceCard({ experience }: ExperienceCardProps) {
  return (
    <Card
      className="experience-card"
      title={experience.title || "Untitled experience"}
      subtitle={`Saved ${formatDate(experience.created_at)}`}
      actions={
        experience.overall_rating !== null ? (
          <Badge tone="success">{experience.overall_rating}/5</Badge>
        ) : (
          <Badge>Unrated</Badge>
        )
      }
    >
      <div>
        {experience.occasion ? <Badge>{experience.occasion}</Badge> : null}
        {experience.social_context ? (
          <Badge tone="accent">{experience.social_context}</Badge>
        ) : null}
      </div>

      <p className="muted" style={{ margin: 0 }}>
        {experience.notes || "No notes were added for this experience."}
      </p>

      {experience.ratings.length > 0 ? (
        <div>
          {experience.ratings.map((rating) => (
            <Badge key={rating.id} tone="warning">
              {rating.category}: {rating.score}
            </Badge>
          ))}
        </div>
      ) : (
        <div>
          <Badge>No category ratings</Badge>
        </div>
      )}
    </Card>
  );
}
EOF

cat > src/pages/RestaurantsPage.tsx <<'EOF'
import { useEffect, useMemo, useState } from "react";

import RestaurantCard from "../components/dining/RestaurantCard";
import Badge from "../components/ui/Badge";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RestaurantDetail, RestaurantListItem } from "../types";

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<RestaurantDetail | null>(null);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [loadingList, setLoadingList] = useState(true);
  const [loadingDetail, setLoadingDetail] = useState(false);

  useEffect(() => {
    void loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      setError("");
      setLoadingList(true);
      const data = await apiRequest<RestaurantListItem[]>("/restaurants");
      setRestaurants(data);
      if (data.length > 0 && selectedId === null) {
        void loadRestaurantDetail(data[0].id);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurants");
    } finally {
      setLoadingList(false);
    }
  }

  async function loadRestaurantDetail(restaurantId: number) {
    try {
      setError("");
      setLoadingDetail(true);
      setSelectedId(restaurantId);
      const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
      setSelectedRestaurant(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurant detail");
    } finally {
      setLoadingDetail(false);
    }
  }

  const summaryText = useMemo(() => {
    if (!selectedRestaurant) {
      return "Select a restaurant to inspect its tags, menu items, and recommendation signals.";
    }

    return selectedRestaurant.description || "No description available for this restaurant.";
  }, [selectedRestaurant]);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Discovery</p>
        <h1 className="page-title">Restaurant library</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Explore the seeded restaurant catalog, compare restaurant signals, and
          inspect menu-level detail in a cleaner split-view workspace.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Available restaurants"
          subtitle="Browse the backend-loaded catalog"
          actions={<Badge>{restaurants.length} loaded</Badge>}
        >
          {loadingList ? (
            <div className="item">
              <strong>Loading restaurant catalog</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Pulling available venues from the backend.
              </p>
            </div>
          ) : restaurants.length === 0 ? (
            <div className="item">
              <strong>No restaurants available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                The backend returned an empty catalog.
              </p>
            </div>
          ) : (
            <div className="list">
              {restaurants.map((restaurant) => (
                <RestaurantCard
                  key={restaurant.id}
                  restaurant={restaurant}
                  onSelect={(restaurantId) => void loadRestaurantDetail(restaurantId)}
                  isActive={selectedId === restaurant.id}
                />
              ))}
            </div>
          )}
        </Card>

        <Card
          title={selectedRestaurant?.name || "Restaurant detail"}
          subtitle={summaryText}
          actions={
            selectedRestaurant ? (
              <Badge tone="accent">{selectedRestaurant.price_tier}</Badge>
            ) : (
              <Badge>Preview</Badge>
            )
          }
        >
          {!selectedRestaurant ? (
            <div className="item">
              <strong>No restaurant selected</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Choose a restaurant from the left panel to inspect its full detail.
              </p>
            </div>
          ) : (
            <div className="list">
              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>
                  Restaurant signal profile
                </p>
                <strong>Location and style</strong>
                <p className="muted">
                  {selectedRestaurant.city} • {selectedRestaurant.price_tier} •{" "}
                  {selectedRestaurant.atmosphere || "No atmosphere"} •{" "}
                  {selectedRestaurant.pace || "No pace"} •{" "}
                  {selectedRestaurant.social_style || "No social style"}
                </p>

                <div>
                  {selectedRestaurant.tags.map((tag) => (
                    <Badge key={`${tag.category}-${tag.name}`}>
                      {tag.category}: {tag.name}
                    </Badge>
                  ))}
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>
                  Menu intelligence
                </p>
                <strong>Menu items</strong>

                {loadingDetail ? (
                  <p className="muted">Loading detail...</p>
                ) : selectedRestaurant.menu_items.length === 0 ? (
                  <p className="muted" style={{ marginBottom: 0 }}>
                    No menu items were returned for this restaurant.
                  </p>
                ) : (
                  <div className="list" style={{ marginTop: "0.8rem" }}>
                    {selectedRestaurant.menu_items.map((item) => (
                      <div className="item" key={item.id}>
                        <strong>{item.name}</strong>
                        <p className="muted">
                          {item.category} • Price: {item.price ?? "-"} •{" "}
                          {item.is_signature ? "Signature item" : "Standard item"}
                        </p>
                        <p style={{ marginBottom: item.tags.length > 0 ? "0.8rem" : 0 }}>
                          {item.description || "No description"}
                        </p>

                        {item.tags.length > 0 ? (
                          <div>
                            {item.tags.map((tag) => (
                              <Badge key={`${item.id}-${tag.id}`} tone="accent">
                                {tag.name}
                              </Badge>
                            ))}
                          </div>
                        ) : null}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
EOF

cat > src/pages/ExperiencesPage.tsx <<'EOF'
import { FormEvent, useEffect, useState } from "react";

import ExperienceCard from "../components/dining/ExperienceCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { Experience, RestaurantListItem } from "../types";

export default function ExperiencesPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({
    restaurant_id: "",
    title: "Great dinner",
    occasion: "date night",
    social_context: "romantic",
    notes: "Really enjoyed the pasta and drinks.",
    overall_rating: "4.5"
  });

  async function loadData() {
    try {
      setError("");
      setLoading(true);
      const [restaurantData, experienceData] = await Promise.all([
        apiRequest<RestaurantListItem[]>("/restaurants"),
        apiRequest<Experience[]>("/experiences")
      ]);
      setRestaurants(restaurantData);
      setExperiences(experienceData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load experiences");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadData();
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");

    try {
      await apiRequest<Experience>("/experiences", {
        method: "POST",
        body: {
          restaurant_id: form.restaurant_id ? Number(form.restaurant_id) : null,
          title: form.title || null,
          occasion: form.occasion || null,
          social_context: form.social_context || null,
          notes: form.notes || null,
          overall_rating: form.overall_rating ? Number(form.overall_rating) : null,
          menu_item_ids: [],
          ratings: [
            {
              category: "overall",
              score: form.overall_rating ? Number(form.overall_rating) : 4
            }
          ]
        }
      });

      setSuccess("Experience saved successfully.");
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save experience");
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Memory layer</p>
        <h1 className="page-title">Dining experiences</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Log a dining moment, attach context to the meal, and keep a cleaner memory
          layer that can support future personalization.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Log a new experience"
          subtitle="Capture the context of a real meal"
          actions={<Badge tone="accent">Journal</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label htmlFor="restaurant_id">Restaurant</label>
              <select
                id="restaurant_id"
                value={form.restaurant_id}
                onChange={(e) => setForm({ ...form, restaurant_id: e.target.value })}
              >
                <option value="">Select a restaurant</option>
                {restaurants.map((restaurant) => (
                  <option key={restaurant.id} value={restaurant.id}>
                    {restaurant.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="title">Title</label>
                <input
                  id="title"
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="overall_rating">Overall rating</label>
                <input
                  id="overall_rating"
                  value={form.overall_rating}
                  onChange={(e) => setForm({ ...form, overall_rating: e.target.value })}
                />
              </div>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="occasion">Occasion</label>
                <input
                  id="occasion"
                  value={form.occasion}
                  onChange={(e) => setForm({ ...form, occasion: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="social_context">Social context</label>
                <input
                  id="social_context"
                  value={form.social_context}
                  onChange={(e) => setForm({ ...form, social_context: e.target.value })}
                />
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="notes">Notes</label>
              <textarea
                id="notes"
                value={form.notes}
                onChange={(e) => setForm({ ...form, notes: e.target.value })}
              />
            </div>

            <div className="button-row">
              <Button type="submit">Save experience</Button>
            </div>
          </form>
        </Card>

        <Card
          title="Saved experiences"
          subtitle="Your recorded dining history"
          actions={<Badge>{experiences.length} saved</Badge>}
        >
          {loading ? (
            <div className="item">
              <strong>Loading experience history</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Pulling your saved experiences from the backend.
              </p>
            </div>
          ) : experiences.length === 0 ? (
            <div className="item">
              <strong>No experiences logged yet</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Save your first experience to start building a reusable memory layer.
              </p>
            </div>
          ) : (
            <div className="list">
              {experiences.map((experience) => (
                <ExperienceCard key={experience.id} experience={experience} />
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
EOF

echo "running build..."
npm run build

echo "phase 4 part 3 complete"
