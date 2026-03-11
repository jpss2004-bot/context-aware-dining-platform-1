import { FormEvent, useEffect, useState } from "react";

import { apiRequest } from "../lib/api";
import { Experience, RestaurantListItem } from "../types";

export default function ExperiencesPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

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
      const [restaurantData, experienceData] = await Promise.all([
        apiRequest<RestaurantListItem[]>("/restaurants"),
        apiRequest<Experience[]>("/experiences")
      ]);
      setRestaurants(restaurantData);
      setExperiences(experienceData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load experiences");
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

      setSuccess("Experience saved successfully");
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save experience");
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Experiences</h1>
        <p className="muted">Create a dining log entry and review your saved history.</p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <div className="card">
          <h2>Log a new experience</h2>

          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label>Restaurant</label>
              <select
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

            <div className="form-row">
              <label>Title</label>
              <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label>Occasion</label>
                <input
                  value={form.occasion}
                  onChange={(e) => setForm({ ...form, occasion: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Social context</label>
                <input
                  value={form.social_context}
                  onChange={(e) => setForm({ ...form, social_context: e.target.value })}
                />
              </div>
            </div>

            <div className="form-row">
              <label>Overall rating</label>
              <input
                value={form.overall_rating}
                onChange={(e) => setForm({ ...form, overall_rating: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Notes</label>
              <textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
            </div>

            <button className="button" type="submit">
              Save experience
            </button>
          </form>
        </div>

        <div className="card">
          <h2>Saved experiences</h2>
          <div className="list">
            {experiences.length === 0 ? (
              <div className="item">No experiences logged yet.</div>
            ) : (
              experiences.map((experience) => (
                <div className="item" key={experience.id}>
                  <strong>{experience.title || "Untitled experience"}</strong>
                  <p className="muted">
                    Occasion: {experience.occasion || "-"} | Social: {experience.social_context || "-"}
                  </p>
                  <p>Overall rating: {experience.overall_rating ?? "-"}</p>
                  <p>{experience.notes || "No notes"}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </section>
    </>
  );
}
