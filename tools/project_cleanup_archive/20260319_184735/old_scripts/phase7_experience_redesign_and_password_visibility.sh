#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
else
  echo "Error: could not find frontend/src from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

mkdir -p "$FRONTEND_DIR/src/components/forms"

cat > "$FRONTEND_DIR/src/components/forms/PasswordField.tsx" <<'EOF'
import { InputHTMLAttributes, useId, useState } from "react";

type PasswordFieldProps = Omit<InputHTMLAttributes<HTMLInputElement>, "type"> & {
  label: string;
  hint?: string;
};

export default function PasswordField({
  label,
  hint,
  id,
  className,
  ...props
}: PasswordFieldProps) {
  const generatedId = useId();
  const inputId = id || generatedId;
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div className="form-row">
      <label htmlFor={inputId}>{label}</label>

      <div className={["password-input-shell", className ?? ""].filter(Boolean).join(" ")}>
        <input
          {...props}
          id={inputId}
          type={isVisible ? "text" : "password"}
          className="password-input-shell__input"
        />
        <button
          type="button"
          className="password-toggle"
          onClick={() => setIsVisible((current) => !current)}
          aria-label={isVisible ? "Hide password" : "Show password"}
        >
          {isVisible ? "Hide" : "Show"}
        </button>
      </div>

      {hint ? <small className="muted">{hint}</small> : null}
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/LoginPage.tsx" <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import PasswordField from "../components/forms/PasswordField";
import { useAuth } from "../context/AuthContext";

const PASSWORD_HINT = "Passwords must be between 8 and 128 characters.";

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
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
        className="auth-card auth-card--focused"
        title="Welcome back to SAVR"
        subtitle="Log in to continue exploring restaurants, updating your profile, and saving dining experiences."
        actions={<Badge tone="accent">Login</Badge>}
      >
        {error ? <div className="error">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              autoComplete="email"
            />
          </div>

          <PasswordField
            label="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            autoComplete="current-password"
            hint={PASSWORD_HINT}
          />

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Signing in..." : "Log in"}
          </Button>
        </form>

        <div className="auth-switch-card">
          <strong>Don’t have an account yet?</strong>
          <p className="muted" style={{ marginBottom: "0.85rem" }}>
            Create your SAVR account to build your profile and start receiving personalized recommendations.
          </p>
          <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/register">
            Create my account
          </Link>
        </div>
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/RegisterPage.tsx" <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import PasswordField from "../components/forms/PasswordField";
import { useAuth } from "../context/AuthContext";

const PASSWORD_HINT = "Passwords must be between 8 and 128 characters.";

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
      setSuccess("Account created successfully. Redirecting you to login...");
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
        className="auth-card auth-card--focused"
        title="Create your SAVR account"
        subtitle="Set up your account so you can build your dining profile, save experiences, and explore recommendations."
        actions={<Badge tone="accent">New account</Badge>}
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
                placeholder="First name"
                autoComplete="given-name"
              />
            </div>

            <div className="form-row">
              <label htmlFor="last_name">Last name</label>
              <input
                id="last_name"
                value={form.last_name}
                onChange={(e) => setForm({ ...form, last_name: e.target.value })}
                placeholder="Last name"
                autoComplete="family-name"
              />
            </div>
          </div>

          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              placeholder="Enter your email"
              autoComplete="email"
            />
          </div>

          <PasswordField
            label="Password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            placeholder="Create a password"
            autoComplete="new-password"
            hint={PASSWORD_HINT}
          />

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Creating account..." : "Create my account"}
          </Button>
        </form>

        <div className="auth-switch-card">
          <strong>Already have an account?</strong>
          <p className="muted" style={{ marginBottom: "0.85rem" }}>
            Log in with your existing SAVR account instead of creating a new one.
          </p>
          <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/login">
            Go to login
          </Link>
        </div>
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/components/dining/ExperienceCard.tsx" <<'EOF'
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

function formatCategoryLabel(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

export default function ExperienceCard({ experience }: ExperienceCardProps) {
  return (
    <Card
      className="experience-card"
      title={experience.title || "Dining experience"}
      subtitle={`Saved ${formatDate(experience.created_at)}`}
      actions={
        experience.overall_rating !== null ? (
          <Badge tone="success">{experience.overall_rating}/5</Badge>
        ) : (
          <Badge>Unrated</Badge>
        )
      }
    >
      <div className="experience-card__meta">
        {experience.occasion ? <Badge>{experience.occasion}</Badge> : null}
        {experience.social_context ? (
          <Badge tone="accent">{experience.social_context}</Badge>
        ) : null}
      </div>

      <p className="muted experience-card__notes">
        {experience.notes || "No notes were added for this experience."}
      </p>

      {experience.ratings.length > 0 ? (
        <div className="experience-card__ratings">
          {experience.ratings.map((rating) => (
            <div key={rating.id} className="experience-rating-pill">
              <span>{formatCategoryLabel(rating.category)}</span>
              <strong>{rating.score}/5</strong>
            </div>
          ))}
        </div>
      ) : null}
    </Card>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/ExperiencesPage.tsx" <<'EOF'
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import ExperienceCard from "../components/dining/ExperienceCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { Experience } from "../types";

export default function ExperiencesPage() {
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadExperiences() {
      try {
        setError("");
        setLoading(true);
        const experienceData = await apiRequest<Experience[]>("/experiences");
        if (!cancelled) {
          setExperiences(experienceData);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load your SAVR history.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadExperiences();

    return () => {
      cancelled = true;
    };
  }, []);

  const summary = useMemo(() => {
    const total = experiences.length;
    const rated = experiences.filter((experience) => experience.overall_rating !== null);
    const average =
      rated.length > 0
        ? (
            rated.reduce((sum, experience) => sum + (experience.overall_rating ?? 0), 0) /
            rated.length
          ).toFixed(1)
        : "—";

    return {
      total,
      rated: rated.length,
      average
    };
  }, [experiences]);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Experiences</p>
        <h1 className="page-title">Your dining history</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Review your saved outings, track what worked, and continue building a stronger dining memory for SAVR.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-3">
        <Card
          title="Saved entries"
          subtitle="Total number of dining experiences currently stored"
          actions={<Badge tone="accent">History</Badge>}
        >
          <p className="kpi">{summary.total}</p>
        </Card>

        <Card
          title="Rated entries"
          subtitle="Experiences that include an overall score"
          actions={<Badge tone="success">Ratings</Badge>}
        >
          <p className="kpi">{summary.rated}</p>
        </Card>

        <Card
          title="Average rating"
          subtitle="Average score across rated experiences"
          actions={<Badge>Average</Badge>}
        >
          <p className="kpi">{summary.average}</p>
        </Card>
      </section>

      <div className="button-row">
        <Link to="/experiences/new">
          <Button>Log a new experience</Button>
        </Link>
        <Link to="/recommendations">
          <Button variant="ghost">Go to recommendations</Button>
        </Link>
      </div>

      <Card
        title="Saved dining memories"
        subtitle="Browse your saved entries in one place"
        actions={<Badge>{experiences.length} entries</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading your dining history</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling your saved experiences from the backend.
            </p>
          </div>
        ) : experiences.length === 0 ? (
          <div className="item">
            <strong>No experiences saved yet</strong>
            <p className="muted" style={{ marginBottom: "1rem" }}>
              Start by logging your first restaurant visit so SAVR can begin learning from your real dining outcomes.
            </p>
            <Link to="/experiences/new">
              <Button>Log your first experience</Button>
            </Link>
          </div>
        ) : (
          <div className="grid grid-2">
            {experiences.map((experience) => (
              <ExperienceCard key={experience.id} experience={experience} />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/NewExperiencePage.tsx" <<'EOF'
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
EOF

python3 - <<PY
from pathlib import Path

styles_path = Path(r"$FRONTEND_DIR/src/styles.css")
text = styles_path.read_text()

marker = "/* PHASE 7 EXPERIENCE REDESIGN AND PASSWORD VISIBILITY */"
if marker not in text:
    text += """

/* PHASE 7 EXPERIENCE REDESIGN AND PASSWORD VISIBILITY */
.auth-card--focused .ui-card__body {
  display: grid;
  gap: 1rem;
}

.auth-switch-card {
  border: 1px solid rgba(148, 163, 184, 0.14);
  background: rgba(15, 23, 42, 0.54);
  border-radius: 1rem;
  padding: 1rem;
}

.password-input-shell {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 0.65rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(8, 15, 28, 0.84);
  border-radius: 0.95rem;
  padding: 0.2rem 0.25rem 0.2rem 0.95rem;
}

.password-input-shell:focus-within {
  border-color: rgba(96, 165, 250, 0.42);
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.12);
}

.password-input-shell__input {
  border: 0;
  outline: none;
  background: transparent;
  padding: 0.72rem 0;
  color: var(--text-main);
  width: 100%;
}

.password-toggle {
  border: 0;
  background: rgba(37, 99, 235, 0.14);
  color: #dbeafe;
  border-radius: 0.8rem;
  padding: 0.62rem 0.82rem;
  font-weight: 700;
}

.password-toggle:hover {
  background: rgba(37, 99, 235, 0.24);
}

.segmented-option-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.65rem;
}

.segmented-option {
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(15, 23, 42, 0.62);
  color: var(--text-main);
  border-radius: 999px;
  padding: 0.68rem 0.9rem;
  transition:
    transform 150ms ease,
    border-color 150ms ease,
    background-color 150ms ease;
}

.segmented-option:hover {
  transform: translateY(-1px);
  border-color: rgba(96, 165, 250, 0.32);
}

.segmented-option--active {
  border-color: rgba(96, 165, 250, 0.42);
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.22), rgba(139, 92, 246, 0.16));
}

.rating-selector-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.55rem;
}

.rating-selector-row--compact .rating-selector {
  min-width: 2.5rem;
}

.rating-selector {
  min-width: 2.9rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(15, 23, 42, 0.62);
  color: var(--text-main);
  border-radius: 0.85rem;
  padding: 0.7rem 0.82rem;
  font-weight: 700;
}

.rating-selector--active {
  border-color: rgba(96, 165, 250, 0.42);
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.24), rgba(139, 92, 246, 0.18));
}

.experience-card__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.45rem;
}

.experience-card__notes {
  line-height: 1.6;
}

.experience-card__ratings {
  display: flex;
  flex-wrap: wrap;
  gap: 0.55rem;
}

.experience-rating-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  border-radius: 999px;
  padding: 0.46rem 0.75rem;
  background: rgba(15, 23, 42, 0.72);
  border: 1px solid rgba(148, 163, 184, 0.14);
}

@media (max-width: 760px) {
  .password-input-shell {
    grid-template-columns: 1fr;
    padding: 0.4rem 0.5rem 0.55rem;
  }

  .password-input-shell__input {
    padding-bottom: 0.3rem;
  }

  .password-toggle {
    width: 100%;
  }
}
"""
    styles_path.write_text(text)
PY

echo "Phase 7 experience redesign and password visibility applied successfully in: $FRONTEND_DIR"
echo "Updated files:"
echo " - src/components/forms/PasswordField.tsx"
echo " - src/pages/LoginPage.tsx"
echo " - src/pages/RegisterPage.tsx"
echo " - src/pages/ExperiencesPage.tsx"
echo " - src/pages/NewExperiencePage.tsx"
echo " - src/components/dining/ExperienceCard.tsx"
echo " - src/styles.css"
