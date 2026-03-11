import { useEffect, useState } from "react";

import { apiRequest } from "../lib/api";
import { RestaurantDetail, RestaurantListItem } from "../types";

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<RestaurantDetail | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    void loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      const data = await apiRequest<RestaurantListItem[]>("/restaurants");
      setRestaurants(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurants");
    }
  }

  async function loadRestaurantDetail(restaurantId: number) {
    try {
      const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
      setSelectedRestaurant(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurant detail");
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Restaurants</h1>
        <p className="muted">Browse the seeded restaurants and inspect details from the backend.</p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <div className="card">
          <h2>Available restaurants</h2>
          <div className="list">
            {restaurants.map((restaurant) => (
              <div className="item" key={restaurant.id}>
                <h3>{restaurant.name}</h3>
                <p>{restaurant.description || "No description"}</p>
                <p className="muted">
                  {restaurant.city} • {restaurant.price_tier} • {restaurant.atmosphere || "No atmosphere tag"}
                </p>
                <button
                  className="button ghost"
                  onClick={() => void loadRestaurantDetail(restaurant.id)}
                  type="button"
                >
                  View details
                </button>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <h2>Restaurant detail</h2>
          {!selectedRestaurant ? (
            <div className="item">Select a restaurant to view details.</div>
          ) : (
            <div className="item">
              <h3>{selectedRestaurant.name}</h3>
              <p>{selectedRestaurant.description || "No description"}</p>
              <p className="muted">
                {selectedRestaurant.city} • {selectedRestaurant.price_tier} •{" "}
                {selectedRestaurant.atmosphere || "No atmosphere"}
              </p>

              <div>
                {selectedRestaurant.tags.map((tag) => (
                  <span className="pill" key={`${tag.category}-${tag.name}`}>
                    {tag.category}: {tag.name}
                  </span>
                ))}
              </div>

              <h4>Menu items</h4>
              <div className="list">
                {selectedRestaurant.menu_items.map((item) => (
                  <div className="item" key={item.id}>
                    <strong>{item.name}</strong> — {item.category}
                    <p>{item.description || "No description"}</p>
                    <p className="muted">Price: {item.price ?? "-"}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </section>
    </>
  );
}
