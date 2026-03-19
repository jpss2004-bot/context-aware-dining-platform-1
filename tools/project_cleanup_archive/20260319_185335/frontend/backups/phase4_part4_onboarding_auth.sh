#!/bin/zsh
set -e

echo "applying phase 4 onboarding + auth refinement..."

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

const sections = [
  {
    title: "Taste profile",
    subtitle: "Cuisine and texture preferences",
    fields: ["cuisine_preferences", "texture_preferences"]
  },
  {
    title: "Dining behavior",
    subtitle: "How you like a night out to feel",
    fields: [
      "dining_pace_preferences",
      "social_preferences",
      "atmosphere_preferences"
    ]
  },
  {
    title: "Food and drink constraints",
    subtitle: "Restrictions, drinks, spice, and budget",
    fields: [
      "dietary_restrictions",
      "drink_preferences",
      "spice_tolerance",
      "price_sensitivity"
    ]
  },
  {
    title: "Dining memory",
    subtitle: "Favorite places and past experiences",
    fields: [
      "favorite_dining_experiences",
      "favorite_restaurants",
      "bio"
    ]
  }
];

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
        <h1 className="page-title">Refine your dining identity</h1>
        <p className="muted" style={{ maxWidth: "820px", marginBottom: 0 }}>
          This onboarding flow still writes directly to your working backend, but it
          now feels more like a guided preference studio. Use comma-separated values
          where needed.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2">
        <Card
          title="Preference profile"
          subtitle="Structured signals that drive recommendation quality"
          actions={<Badge tone="accent">Onboarding</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="list">
              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>
                  Taste profile
                </p>
                <div className="grid grid-2">
                  <div className="form-row">
                    <label htmlFor="cuisine_preferences">Cuisine preferences</label>
                    <input
                      id="cuisine_preferences"
                      value={form.cuisine_preferences}
                      onChange={(e) =>
                        setForm({ ...form, cuisine_preferences: e.target.value })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="texture_preferences">Texture preferences</label>
                    <input
                      id="texture_preferences"
                      value={form.texture_preferences}
                      onChange={(e) =>
                        setForm({ ...form, texture_preferences: e.target.value })
                      }
                    />
                  </div>
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>
                  Dining behavior
                </p>
                <div className="grid grid-2">
                  <div className="form-row">
                    <label htmlFor="dining_pace_preferences">Dining pace preferences</label>
                    <input
                      id="dining_pace_preferences"
                      value={form.dining_pace_preferences}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          dining_pace_preferences: e.target.value
                        })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="social_preferences">Social preferences</label>
                    <input
                      id="social_preferences"
                      value={form.social_preferences}
                      onChange={(e) =>
                        setForm({ ...form, social_preferences: e.target.value })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="atmosphere_preferences">Atmosphere preferences</label>
                    <input
                      id="atmosphere_preferences"
                      value={form.atmosphere_preferences}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          atmosphere_preferences: e.target.value
                        })
                      }
                    />
                  </div>
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>
                  Food and drink constraints
                </p>
                <div className="grid grid-2">
                  <div className="form-row">
                    <label htmlFor="dietary_restrictions">Dietary restrictions</label>
                    <input
                      id="dietary_restrictions"
                      value={form.dietary_restrictions}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          dietary_restrictions: e.target.value
                        })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="drink_preferences">Drink preferences</label>
                    <input
                      id="drink_preferences"
                      value={form.drink_preferences}
                      onChange={(e) =>
                        setForm({ ...form, drink_preferences: e.target.value })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="spice_tolerance">Spice tolerance</label>
                    <input
                      id="spice_tolerance"
                      value={form.spice_tolerance}
                      onChange={(e) =>
                        setForm({ ...form, spice_tolerance: e.target.value })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="price_sensitivity">Price sensitivity</label>
                    <input
                      id="price_sensitivity"
                      value={form.price_sensitivity}
                      onChange={(e) =>
                        setForm({ ...form, price_sensitivity: e.target.value })
                      }
                    />
                  </div>
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>
                  Dining memory
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <div className="form-row">
                    <label htmlFor="favorite_dining_experiences">
                      Favorite dining experiences
                    </label>
                    <input
                      id="favorite_dining_experiences"
                      value={form.favorite_dining_experiences}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          favorite_dining_experiences: e.target.value
                        })
                      }
                    />
                  </div>

                  <div className="form-row">
                    <label htmlFor="favorite_restaurants">Favorite restaurants</label>
                    <input
                      id="favorite_restaurants"
                      value={form.favorite_restaurants}
                      onChange={(e) =>
                        setForm({ ...form, favorite_restaurants: e.target.value })
                      }
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
                </div>
              </div>
            </div>

            <div className="button-row">
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Saving..." : "Save onboarding"}
              </Button>
            </div>
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

          <div className="item">
            <strong>Section map</strong>
            <div className="list" style={{ marginTop: "0.8rem" }}>
              {sections.map((section) => (
                <div key={section.title}>
                  <strong>{section.title}</strong>
                  <p className="muted" style={{ margin: "0.2rem 0 0" }}>
                    {section.subtitle}
                  </p>
                </div>
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

import Badge from "../components/ui/Badge";
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
        subtitle="Sign in to access your dining profile, onboarding, recommendation studio, and saved experience history."
        actions={<Badge tone="accent">Secure access</Badge>}
      >
        <div className="item">
          <strong>What you unlock</strong>
          <div style={{ marginTop: "0.8rem" }}>
            <Badge>Recommendations</Badge>
            <Badge tone="accent">Restaurant discovery</Badge>
            <Badge tone="success">Dining memory</Badge>
          </div>
        </div>

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

import Badge from "../components/ui/Badge";
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
        subtitle="Set up your account to save dining preferences, recommendation history, and dining experiences."
        actions={<Badge tone="accent">New profile</Badge>}
      >
        <div className="item">
          <strong>What this account supports</strong>
          <div style={{ marginTop: "0.8rem" }}>
            <Badge>Onboarding memory</Badge>
            <Badge tone="accent">Recommendation modes</Badge>
            <Badge tone="success">Experience logging</Badge>
          </div>
        </div>

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

echo "phase 4 part 4 complete"
