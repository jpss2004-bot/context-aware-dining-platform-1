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
