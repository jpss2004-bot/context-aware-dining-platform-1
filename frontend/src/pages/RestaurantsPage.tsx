import { useEffect, useState } from "react";

import RestaurantCard from "../components/dining/RestaurantCard";
import Badge from "../components/ui/Badge";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RestaurantListItem } from "../types";

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurants() {
      try {
        setError("");
        setLoading(true);
        const data = await apiRequest<RestaurantListItem[]>("/restaurants");
        if (!cancelled) {
          setRestaurants(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load the venue guide.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadRestaurants();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Restaurants</p>
        <h1 className="page-title">Browse the SAVR venue catalog</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          This page now focuses only on restaurant discovery. Open any venue to inspect
          its own dedicated detail page.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <Card
        title="Available venues"
        subtitle="Browse the current restaurant catalog from the backend"
        actions={<Badge>{restaurants.length} venues</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading the venue guide</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling available restaurants from the API.
            </p>
          </div>
        ) : restaurants.length === 0 ? (
          <div className="item">
            <strong>No venues are available</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              The backend returned an empty catalog.
            </p>
          </div>
        ) : (
          <div className="grid grid-2">
            {restaurants.map((restaurant) => (
              <RestaurantCard
                key={restaurant.id}
                restaurant={restaurant}
                detailPath={`/restaurants/${restaurant.id}`}
              />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
