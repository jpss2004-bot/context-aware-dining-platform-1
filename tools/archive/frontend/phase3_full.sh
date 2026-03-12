#!/bin/zsh
set -e

echo "writing phase 3 files..."

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

  return date.toLocaleDateString();
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
      ) : null}
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
  const [loadingDetail, setLoadingDetail] = useState(false);

  useEffect(() => {
    void loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      setError("");
      const data = await apiRequest<RestaurantListItem[]>("/restaurants");
      setRestaurants(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurants");
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
        <p className="muted" style={{ maxWidth: "760px" }}>
          Explore the seeded restaurant catalog, review core metadata, and open a
          detail view that exposes tags and menu items from the backend.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Available restaurants"
          subtitle="Browse the backend-loaded catalog"
          actions={<Badge>{restaurants.length} loaded</Badge>}
        >
          {restaurants.length === 0 ? (
            <div className="item">No restaurants available yet.</div>
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
            ) : null
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
        <p className="muted" style={{ maxWidth: "760px" }}>
          Create a polished dining log entry, store the context behind a meal, and
          strengthen future recommendation quality.
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

            <div className="form-row">
              <label htmlFor="title">Title</label>
              <input
                id="title"
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
              />
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
              <label htmlFor="overall_rating">Overall rating</label>
              <input
                id="overall_rating"
                value={form.overall_rating}
                onChange={(e) => setForm({ ...form, overall_rating: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label htmlFor="notes">Notes</label>
              <textarea
                id="notes"
                value={form.notes}
                onChange={(e) => setForm({ ...form, notes: e.target.value })}
              />
            </div>

            <Button type="submit">Save experience</Button>
          </form>
        </Card>

        <Card
          title="Saved experiences"
          subtitle="Your recorded dining history"
          actions={<Badge>{experiences.length} saved</Badge>}
        >
          {experiences.length === 0 ? (
            <div className="item">No experiences logged yet.</div>
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

cat > src/pages/OnboardingPage.tsx <<'EOF'
import { FormEvent, useMemo, useState } from "react";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
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

  const previewStats = useMemo(
    () => [
      { label: "Cuisine tags", value: splitList(form.cuisine_preferences).length },
      { label: "Drink tags", value: splitList(form.drink_preferences).length },
      { label: "Atmosphere tags", value: splitList(form.atmosphere_preferences).length }
    ],
    [form]
  );

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
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile setup</p>
        <h1 className="page-title">Let&apos;s get to know your dining style</h1>
        <p className="muted" style={{ maxWidth: "760px" }}>
          Enter comma-separated values where needed. This page still writes directly
          to your working backend, but the experience is now structured like a
          cleaner preference wizard.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Preference profile"
          subtitle="The recommendation engine relies on this signal set"
          actions={<Badge tone="accent">Onboarding</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="dietary_restrictions">Dietary restrictions</label>
                <input
                  id="dietary_restrictions"
                  value={form.dietary_restrictions}
                  onChange={(e) => setForm({ ...form, dietary_restrictions: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="cuisine_preferences">Cuisine preferences</label>
                <input
                  id="cuisine_preferences"
                  value={form.cuisine_preferences}
                  onChange={(e) => setForm({ ...form, cuisine_preferences: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="texture_preferences">Texture preferences</label>
                <input
                  id="texture_preferences"
                  value={form.texture_preferences}
                  onChange={(e) => setForm({ ...form, texture_preferences: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="dining_pace_preferences">Dining pace preferences</label>
                <input
                  id="dining_pace_preferences"
                  value={form.dining_pace_preferences}
                  onChange={(e) => setForm({ ...form, dining_pace_preferences: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="social_preferences">Social preferences</label>
                <input
                  id="social_preferences"
                  value={form.social_preferences}
                  onChange={(e) => setForm({ ...form, social_preferences: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="drink_preferences">Drink preferences</label>
                <input
                  id="drink_preferences"
                  value={form.drink_preferences}
                  onChange={(e) => setForm({ ...form, drink_preferences: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="atmosphere_preferences">Atmosphere preferences</label>
                <input
                  id="atmosphere_preferences"
                  value={form.atmosphere_preferences}
                  onChange={(e) => setForm({ ...form, atmosphere_preferences: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="favorite_restaurants">Favorite restaurants</label>
                <input
                  id="favorite_restaurants"
                  value={form.favorite_restaurants}
                  onChange={(e) => setForm({ ...form, favorite_restaurants: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="spice_tolerance">Spice tolerance</label>
                <input
                  id="spice_tolerance"
                  value={form.spice_tolerance}
                  onChange={(e) => setForm({ ...form, spice_tolerance: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label htmlFor="price_sensitivity">Price sensitivity</label>
                <input
                  id="price_sensitivity"
                  value={form.price_sensitivity}
                  onChange={(e) => setForm({ ...form, price_sensitivity: e.target.value })}
                />
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="favorite_dining_experiences">Favorite dining experiences</label>
              <input
                id="favorite_dining_experiences"
                value={form.favorite_dining_experiences}
                onChange={(e) => setForm({ ...form, favorite_dining_experiences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label htmlFor="bio">Bio</label>
              <textarea
                id="bio"
                value={form.bio}
                onChange={(e) => setForm({ ...form, bio: e.target.value })}
              />
            </div>

            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Saving..." : "Save onboarding"}
            </Button>
          </form>
        </Card>

        <Card
          title="Profile preview"
          subtitle="Quick view of the signal quality you are sending to the backend"
          actions={<Badge>{submittedJson ? "Updated" : "Draft"}</Badge>}
        >
          <div className="grid grid-3">
            {previewStats.map((item) => (
              <div className="item" key={item.label}>
                <p className="navbar-eyebrow" style={{ marginBottom: "0.35rem" }}>
                  {item.label}
                </p>
                <p className="kpi">{item.value}</p>
              </div>
            ))}
          </div>

          <div className="item">
            <strong>Current highlights</strong>
            <div style={{ marginTop: "0.8rem" }}>
              {splitList(form.cuisine_preferences).map((item) => (
                <Badge key={`cuisine-${item}`}>{item}</Badge>
              ))}
              {splitList(form.drink_preferences).map((item) => (
                <Badge key={`drink-${item}`} tone="accent">
                  {item}
                </Badge>
              ))}
              {splitList(form.atmosphere_preferences).map((item) => (
                <Badge key={`atmosphere-${item}`} tone="success">
                  {item}
                </Badge>
              ))}
            </div>
          </div>

          {submittedJson ? (
            <div className="item">
              <strong>Last submitted payload</strong>
              <pre
                className="json-box"
                style={{
                  margin: "0.8rem 0 0",
                  overflowX: "auto",
                  whiteSpace: "pre-wrap",
                  color: "#cbd5e1"
                }}
              >
                {submittedJson}
              </pre>
            </div>
          ) : (
            <div className="item">
              <strong>No submission yet</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Save onboarding to store the payload and refresh your user profile.
              </p>
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
EOF

cat > src/pages/LoginPage.tsx <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("jp@example.com");
  const [password, setPassword] = useState("StrongPass123");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await login({ email, password });
      navigate("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <Card
        className="auth-card"
        title="Welcome back"
        subtitle="Sign in to access your dining profile, onboarding, and recommendations."
      >
        {error ? <div className="error">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
            />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
            />
          </div>

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Signing in..." : "Login"}
          </Button>
        </form>

        <div className="item">
          <strong>Need an account?</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            <Link to="/register">Create one here</Link>
          </p>
        </div>
      </Card>
    </div>
  );
}
EOF

cat > src/pages/RegisterPage.tsx <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();

  const [form, setForm] = useState({
    first_name: "",
    last_name: "",
    email: "",
    password: ""
  });
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");
    setIsSubmitting(true);

    try {
      await register(form);
      setSuccess("Account created successfully. You can now log in.");
      setTimeout(() => navigate("/login"), 900);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <Card
        className="auth-card"
        title="Create account"
        subtitle="Set up your account to save dining preferences and recommendation history."
      >
        {error ? <div className="error">{error}</div> : null}
        {success ? <div className="success">{success}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="grid grid-2">
            <div className="form-row">
              <label htmlFor="first_name">First name</label>
              <input
                id="first_name"
                value={form.first_name}
                onChange={(e) => setForm({ ...form, first_name: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label htmlFor="last_name">Last name</label>
              <input
                id="last_name"
                value={form.last_name}
                onChange={(e) => setForm({ ...form, last_name: e.target.value })}
              />
            </div>
          </div>

          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
            />
          </div>

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Creating..." : "Register"}
          </Button>
        </form>

        <div className="item">
          <strong>Already have an account?</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            <Link to="/login">Go to login</Link>
          </p>
        </div>
      </Card>
    </div>
  );
}
EOF

echo "running build..."
npm run build

echo "phase 3 complete"
echo "run the frontend with: npm run dev"
