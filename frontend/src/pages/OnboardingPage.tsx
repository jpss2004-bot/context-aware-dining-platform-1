import { FormEvent, useState } from "react";

import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingPayload, OnboardingResponse } from "../types";

function splitList(value: string): string[] {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

export default function OnboardingPage() {
  const { refreshUser } = useAuth();

  const [form, setForm] = useState({
    dietary_restrictions: "",
    cuisine_preferences: "italian, comfort-food",
    texture_preferences: "creamy, crispy",
    dining_pace_preferences: "leisurely",
    social_preferences: "romantic",
    drink_preferences: "cocktails, wine",
    atmosphere_preferences: "cozy",
    favorite_dining_experiences: "pasta night, cocktail date night",
    favorite_restaurants: "Luna Trattoria",
    bio: "I like cozy dinners with pasta and drinks.",
    spice_tolerance: "medium",
    price_sensitivity: "$$"
  });

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [submittedJson, setSubmittedJson] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setMessage("");
    setIsSubmitting(true);

    const payload: OnboardingPayload = {
      dietary_restrictions: splitList(form.dietary_restrictions),
      cuisine_preferences: splitList(form.cuisine_preferences),
      texture_preferences: splitList(form.texture_preferences),
      dining_pace_preferences: splitList(form.dining_pace_preferences),
      social_preferences: splitList(form.social_preferences),
      drink_preferences: splitList(form.drink_preferences),
      atmosphere_preferences: splitList(form.atmosphere_preferences),
      favorite_dining_experiences: splitList(form.favorite_dining_experiences),
      favorite_restaurants: splitList(form.favorite_restaurants),
      bio: form.bio || null,
      spice_tolerance: form.spice_tolerance || null,
      price_sensitivity: form.price_sensitivity || null
    };

    try {
      const response = await apiRequest<OnboardingResponse>("/onboarding", {
        method: "POST",
        body: payload
      });
      await refreshUser();
      setMessage(response.message);
      setSubmittedJson(JSON.stringify(payload, null, 2));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save onboarding");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Let&apos;s get to know you</h1>
        <p className="muted">
          Enter comma-separated values for preference lists. This page writes directly to your working backend.
        </p>
      </section>

      <section className="card">
        {error ? <div className="error">{error}</div> : null}
        {message ? <div className="success">{message}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="grid grid-2">
            <div className="form-row">
              <label>Dietary restrictions</label>
              <input
                value={form.dietary_restrictions}
                onChange={(e) => setForm({ ...form, dietary_restrictions: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Cuisine preferences</label>
              <input
                value={form.cuisine_preferences}
                onChange={(e) => setForm({ ...form, cuisine_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Texture preferences</label>
              <input
                value={form.texture_preferences}
                onChange={(e) => setForm({ ...form, texture_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Dining pace preferences</label>
              <input
                value={form.dining_pace_preferences}
                onChange={(e) => setForm({ ...form, dining_pace_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Social preferences</label>
              <input
                value={form.social_preferences}
                onChange={(e) => setForm({ ...form, social_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Drink preferences</label>
              <input
                value={form.drink_preferences}
                onChange={(e) => setForm({ ...form, drink_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Atmosphere preferences</label>
              <input
                value={form.atmosphere_preferences}
                onChange={(e) => setForm({ ...form, atmosphere_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Favorite restaurants</label>
              <input
                value={form.favorite_restaurants}
                onChange={(e) => setForm({ ...form, favorite_restaurants: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Spice tolerance</label>
              <input
                value={form.spice_tolerance}
                onChange={(e) => setForm({ ...form, spice_tolerance: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Price sensitivity</label>
              <input
                value={form.price_sensitivity}
                onChange={(e) => setForm({ ...form, price_sensitivity: e.target.value })}
              />
            </div>
          </div>

          <div className="form-row">
            <label>Favorite dining experiences</label>
            <input
              value={form.favorite_dining_experiences}
              onChange={(e) => setForm({ ...form, favorite_dining_experiences: e.target.value })}
            />
          </div>

          <div className="form-row">
            <label>Bio</label>
            <textarea value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} />
          </div>

          <button className="button" disabled={isSubmitting} type="submit">
            {isSubmitting ? "Saving..." : "Save onboarding"}
          </button>
        </form>
      </section>

      {submittedJson ? (
        <section className="card">
          <h2>Last submitted payload</h2>
          <pre className="json-box">{submittedJson}</pre>
        </section>
      ) : null}
    </>
  );
}
