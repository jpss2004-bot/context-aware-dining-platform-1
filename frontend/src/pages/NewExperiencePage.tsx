import { FormEvent, useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { Experience, RestaurantListItem } from "../types";

const occasionOptions = [
  "date night",
  "friends night",
  "family dinner",
  "celebration",
  "casual lunch",
  "solo meal",
  "business meal",
  "special occasion"
];

const socialOptions = [
  "romantic",
  "friends",
  "family",
  "solo",
  "group",
  "professional"
];

const ratingOptions = [1, 2, 3, 4, 5];

type CategoryRatings = {
  food: number;
  service: number;
  atmosphere: number;
  value: number;
};

export default function NewExperiencePage() {
  const navigate = useNavigate();

  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loadingRestaurants, setLoadingRestaurants] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [form, setForm] = useState({
    restaurant_id: "",
    occasion: "",
    social_context: "",
    notes: "",
    overall_rating: 4
  });

  const [categoryRatings, setCategoryRatings] = useState<CategoryRatings>({
    food: 4,
    service: 4,
    atmosphere: 4,
    value: 4
  });

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurants() {
      try {
        setError("");
        setLoadingRestaurants(true);
        const restaurantData = await apiRequest<RestaurantListItem[]>("/restaurants");
        if (!cancelled) {
          const sorted = [...restaurantData].sort((a, b) => a.name.localeCompare(b.name));
          setRestaurants(sorted);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load restaurants for this form.");
        }
      } finally {
        if (!cancelled) {
          setLoadingRestaurants(false);
        }
      }
    }

    void loadRestaurants();

    return () => {
      cancelled = true;
    };
  }, []);

  const selectedRestaurant = useMemo(
    () => restaurants.find((restaurant) => String(restaurant.id) === form.restaurant_id) || null,
    [restaurants, form.restaurant_id]
  );

  function setCategoryRating(category: keyof CategoryRatings, value: number) {
    setCategoryRatings((current) => ({
      ...current,
      [category]: value
    }));
  }

  function buildTitle() {
    const restaurantName = selectedRestaurant?.name || "Dining experience";
    const occasionLabel = form.occasion || "Visit";
    return `${restaurantName} — ${occasionLabel}`;
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");
    setIsSubmitting(true);

    try {
      await apiRequest<Experience>("/experiences", {
        method: "POST",
        body: {
          restaurant_id: form.restaurant_id ? Number(form.restaurant_id) : null,
          title: buildTitle(),
          occasion: form.occasion || null,
          social_context: form.social_context || null,
          notes: form.notes.trim() || null,
          overall_rating: form.overall_rating,
          menu_item_ids: [],
          ratings: [
            { category: "food", score: categoryRatings.food },
            { category: "service", score: categoryRatings.service },
            { category: "atmosphere", score: categoryRatings.atmosphere },
            { category: "value", score: categoryRatings.value }
          ]
        }
      });

      setSuccess("Your experience has been saved.");
      setTimeout(() => {
        navigate("/experiences");
      }, 700);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save this experience.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">New experience</p>
        <h1 className="page-title">Log a dining experience</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Capture the essentials from a real meal using a guided form that is faster, clearer, and easier to complete.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Experience details"
          subtitle="Tell SAVR what happened during the outing"
          actions={<Badge tone="accent">Log</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.45rem" }}>Step 1</p>
              <strong>Where did you go?</strong>

              <div className="form-row" style={{ marginTop: "0.8rem" }}>
                <label htmlFor="restaurant_id">Restaurant</label>
                <select
                  id="restaurant_id"
                  value={form.restaurant_id}
                  onChange={(e) => setForm({ ...form, restaurant_id: e.target.value })}
                >
                  <option value="">
                    {loadingRestaurants ? "Loading restaurants..." : "Select a venue"}
                  </option>
                  {restaurants.map((restaurant) => (
                    <option key={restaurant.id} value={restaurant.id}>
                      {restaurant.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.45rem" }}>Step 2</p>
              <strong>What kind of outing was it?</strong>

              <div className="form-row" style={{ marginTop: "0.8rem" }}>
                <label>Occasion</label>
                <div className="segmented-option-grid">
                  {occasionOptions.map((option) => (
                    <button
                      key={option}
                      type="button"
                      className={[
                        "segmented-option",
                        form.occasion === option ? "segmented-option--active" : ""
                      ]
                        .filter(Boolean)
                        .join(" ")}
                      onClick={() => setForm({ ...form, occasion: option })}
                    >
                      {option}
                    </button>
                  ))}
                </div>
              </div>

              <div className="form-row" style={{ marginTop: "1rem" }}>
                <label>Social context</label>
                <div className="segmented-option-grid">
                  {socialOptions.map((option) => (
                    <button
                      key={option}
                      type="button"
                      className={[
                        "segmented-option",
                        form.social_context === option ? "segmented-option--active" : ""
                      ]
                        .filter(Boolean)
                        .join(" ")}
                      onClick={() => setForm({ ...form, social_context: option })}
                    >
                      {option}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.45rem" }}>Step 3</p>
              <strong>How did it go overall?</strong>

              <div className="form-row" style={{ marginTop: "0.8rem" }}>
                <label>Overall rating</label>
                <div className="rating-selector-row">
                  {ratingOptions.map((value) => (
                    <button
                      key={value}
                      type="button"
                      className={[
                        "rating-selector",
                        form.overall_rating === value ? "rating-selector--active" : ""
                      ]
                        .filter(Boolean)
                        .join(" ")}
                      onClick={() => setForm({ ...form, overall_rating: value })}
                    >
                      {value}
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-2" style={{ marginTop: "1rem" }}>
                {(["food", "service", "atmosphere", "value"] as const).map((category) => (
                  <div className="form-row" key={category}>
                    <label>{category.charAt(0).toUpperCase() + category.slice(1)}</label>
                    <div className="rating-selector-row rating-selector-row--compact">
                      {ratingOptions.map((value) => (
                        <button
                          key={`${category}-${value}`}
                          type="button"
                          className={[
                            "rating-selector",
                            categoryRatings[category] === value ? "rating-selector--active" : ""
                          ]
                            .filter(Boolean)
                            .join(" ")}
                          onClick={() => setCategoryRating(category, value)}
                        >
                          {value}
                        </button>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.45rem" }}>Step 4</p>
              <strong>Anything worth remembering?</strong>

              <div className="form-row" style={{ marginTop: "0.8rem" }}>
                <label htmlFor="notes">Notes</label>
                <textarea
                  id="notes"
                  rows={5}
                  value={form.notes}
                  placeholder="What stood out about the meal, drinks, service, or atmosphere?"
                  onChange={(e) => setForm({ ...form, notes: e.target.value })}
                />
                <small className="muted">
                  Keep this short. A few useful details are better than a long paragraph.
                </small>
              </div>
            </div>

            <div className="button-row">
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Saving..." : "Save experience"}
              </Button>
              <Link to="/experiences">
                <Button variant="ghost">Back to history</Button>
              </Link>
            </div>
          </form>
        </Card>

        <div className="grid" style={{ gap: "1rem" }}>
          <Card
            title="Live summary"
            subtitle="A quick preview of the experience you are about to save"
            actions={<Badge tone="success">Preview</Badge>}
          >
            <div className="list">
              <div className="item">
                <strong>Venue</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {selectedRestaurant?.name || "No restaurant selected yet."}
                </p>
              </div>

              <div className="item">
                <strong>Occasion</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {form.occasion || "Not selected yet."}
                </p>
              </div>

              <div className="item">
                <strong>Social context</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {form.social_context || "Not selected yet."}
                </p>
              </div>

              <div className="item">
                <strong>Overall rating</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {form.overall_rating}/5
                </p>
              </div>
            </div>
          </Card>

          <Card
            title="Why this works better"
            subtitle="A more guided logging experience reduces friction and mistakes"
            actions={<Badge>Guided</Badge>}
          >
            <div className="list">
              <div className="item">
                <strong>Less typing</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Occasion, social context, and ratings are now selection-based instead of text-heavy.
                </p>
              </div>

              <div className="item">
                <strong>Better consistency</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Structured inputs make the saved dining history easier to compare across visits.
                </p>
              </div>

              <div className="item">
                <strong>Faster completion</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  The form now focuses on only the information that matters most for future recommendations.
                </p>
              </div>
            </div>
          </Card>
        </div>
      </section>
    </div>
  );
}
