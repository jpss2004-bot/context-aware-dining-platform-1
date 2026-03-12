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

cat > "$FRONTEND_DIR/src/pages/OnboardingPage.tsx" <<'EOF'
import { FormEvent, useEffect, useMemo, useState } from "react";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingPayload, OnboardingResponse, RestaurantListItem } from "../types";

type OnboardingFormState = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string;
  spice_tolerance: string;
  price_sensitivity: string;
};

const emptyForm: OnboardingFormState = {
  dietary_restrictions: [],
  cuisine_preferences: [],
  texture_preferences: [],
  dining_pace_preferences: [],
  social_preferences: [],
  drink_preferences: [],
  atmosphere_preferences: [],
  favorite_dining_experiences: [],
  favorite_restaurants: [],
  bio: "",
  spice_tolerance: "",
  price_sensitivity: ""
};

const optionCatalog = {
  dietary_restrictions: [
    "vegetarian",
    "vegan",
    "gluten-free",
    "dairy-free",
    "halal",
    "kosher",
    "nut-free",
    "shellfish-free"
  ],
  cuisine_preferences: [
    "italian",
    "mexican",
    "japanese",
    "korean",
    "thai",
    "indian",
    "mediterranean",
    "comfort-food",
    "seafood",
    "steakhouse",
    "brunch",
    "dessert"
  ],
  texture_preferences: [
    "crispy",
    "creamy",
    "smoky",
    "fresh",
    "rich",
    "light",
    "charred",
    "tender",
    "crunchy",
    "saucy"
  ],
  dining_pace_preferences: [
    "quick",
    "casual",
    "balanced",
    "leisurely",
    "slow-and-social"
  ],
  social_preferences: [
    "solo",
    "date-night",
    "friends",
    "family",
    "group-celebration",
    "business-casual"
  ],
  drink_preferences: [
    "cocktails",
    "wine",
    "beer",
    "mocktails",
    "coffee",
    "tea",
    "spirits",
    "dessert-drinks"
  ],
  atmosphere_preferences: [
    "cozy",
    "romantic",
    "upscale",
    "lively",
    "quiet",
    "modern",
    "outdoor",
    "view-driven",
    "music-forward"
  ],
  favorite_dining_experiences: [
    "brunch catch-up",
    "pasta night",
    "cocktail date night",
    "birthday dinner",
    "tasting menu",
    "patio evening",
    "late-night bites",
    "comfort-food reset",
    "celebration dinner",
    "casual lunch"
  ]
} as const;

const spiceOptions = ["none", "mild", "medium", "hot", "very-hot"];
const priceOptions = ["$", "$$", "$$$", "$$$$"];

type MultiSelectFieldProps = {
  label: string;
  hint?: string;
  options: string[];
  selected: string[];
  onToggle: (value: string) => void;
};

function formatLabel(value: string) {
  return value
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function MultiSelectField({
  label,
  hint,
  options,
  selected,
  onToggle
}: MultiSelectFieldProps) {
  return (
    <div className="form-row">
      <label>{label}</label>
      {hint ? <small className="muted">{hint}</small> : null}
      <div className="multi-select-grid">
        {options.map((option) => {
          const active = selected.includes(option);
          return (
            <button
              key={option}
              type="button"
              className={[
                "multi-select-chip",
                active ? "multi-select-chip--active" : ""
              ]
                .filter(Boolean)
                .join(" ")}
              onClick={() => onToggle(option)}
            >
              {formatLabel(option)}
            </button>
          );
        })}
      </div>
    </div>
  );
}

type SelectFieldProps = {
  id: string;
  label: string;
  value: string;
  placeholder: string;
  options: string[];
  onChange: (value: string) => void;
};

function SelectField({
  id,
  label,
  value,
  placeholder,
  options,
  onChange
}: SelectFieldProps) {
  return (
    <div className="form-row">
      <label htmlFor={id}>{label}</label>
      <select id={id} value={value} onChange={(e) => onChange(e.target.value)}>
        <option value="">{placeholder}</option>
        {options.map((option) => (
          <option key={option} value={option}>
            {formatLabel(option)}
          </option>
        ))}
      </select>
    </div>
  );
}

export default function OnboardingPage() {
  const { refreshUser } = useAuth();

  const [form, setForm] = useState<OnboardingFormState>(emptyForm);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [submittedJson, setSubmittedJson] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [isLoadingRestaurants, setIsLoadingRestaurants] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurants() {
      try {
        const restaurants = await apiRequest<RestaurantListItem[]>("/restaurants");
        if (!cancelled) {
          setRestaurantOptions(restaurants.map((restaurant) => restaurant.name));
        }
      } catch {
        if (!cancelled) {
          setRestaurantOptions([]);
        }
      } finally {
        if (!cancelled) {
          setIsLoadingRestaurants(false);
        }
      }
    }

    void loadRestaurants();

    return () => {
      cancelled = true;
    };
  }, []);

  const previewStats = useMemo(
    () => [
      { label: "Cuisine picks", value: form.cuisine_preferences.length },
      { label: "Drink picks", value: form.drink_preferences.length },
      { label: "Atmosphere picks", value: form.atmosphere_preferences.length },
      { label: "Favorite venues", value: form.favorite_restaurants.length }
    ],
    [form]
  );

  function toggleArrayField(field: keyof Pick<
    OnboardingFormState,
    | "dietary_restrictions"
    | "cuisine_preferences"
    | "texture_preferences"
    | "dining_pace_preferences"
    | "social_preferences"
    | "drink_preferences"
    | "atmosphere_preferences"
    | "favorite_dining_experiences"
    | "favorite_restaurants"
  >, value: string) {
    setForm((current) => {
      const existing = current[field];
      const next = existing.includes(value)
        ? existing.filter((item) => item !== value)
        : [...existing, value];

      return {
        ...current,
        [field]: next
      };
    });
  }

  function resetForm() {
    setForm(emptyForm);
    setMessage("");
    setError("");
    setSubmittedJson("");
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setMessage("");
    setIsSubmitting(true);

    const payload: OnboardingPayload = {
      dietary_restrictions: form.dietary_restrictions,
      cuisine_preferences: form.cuisine_preferences,
      texture_preferences: form.texture_preferences,
      dining_pace_preferences: form.dining_pace_preferences,
      social_preferences: form.social_preferences,
      drink_preferences: form.drink_preferences,
      atmosphere_preferences: form.atmosphere_preferences,
      favorite_dining_experiences: form.favorite_dining_experiences,
      favorite_restaurants: form.favorite_restaurants,
      bio: form.bio.trim() || null,
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
        <h1 className="page-title">Build your SAVR dining profile</h1>
        <p className="muted" style={{ maxWidth: "820px", marginBottom: 0 }}>
          Choose the dining signals that best describe your taste, pace, social style,
          and atmosphere preferences. This version is selection-based to make onboarding
          much faster and easier to complete.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2 onboarding-grid">
        <Card
          title="Preference studio"
          subtitle="Guided selections that shape recommendation quality"
          actions={<Badge tone="accent">Phase 2</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="list">
              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Taste profile
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Cuisine preferences"
                    hint="Select one or more cuisine styles you usually enjoy."
                    options={[...optionCatalog.cuisine_preferences]}
                    selected={form.cuisine_preferences}
                    onToggle={(value) => toggleArrayField("cuisine_preferences", value)}
                  />

                  <MultiSelectField
                    label="Texture preferences"
                    hint="Pick textures and sensory qualities you usually gravitate toward."
                    options={[...optionCatalog.texture_preferences]}
                    selected={form.texture_preferences}
                    onToggle={(value) => toggleArrayField("texture_preferences", value)}
                  />
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Dining behavior
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Dining pace"
                    hint="Choose how you like the night to feel from a timing perspective."
                    options={[...optionCatalog.dining_pace_preferences]}
                    selected={form.dining_pace_preferences}
                    onToggle={(value) => toggleArrayField("dining_pace_preferences", value)}
                  />

                  <MultiSelectField
                    label="Social preferences"
                    hint="Choose the kinds of social contexts you most often dine in."
                    options={[...optionCatalog.social_preferences]}
                    selected={form.social_preferences}
                    onToggle={(value) => toggleArrayField("social_preferences", value)}
                  />

                  <MultiSelectField
                    label="Atmosphere preferences"
                    hint="Select the moods and environments that match your ideal experience."
                    options={[...optionCatalog.atmosphere_preferences]}
                    selected={form.atmosphere_preferences}
                    onToggle={(value) => toggleArrayField("atmosphere_preferences", value)}
                  />
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Food and drink constraints
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Dietary restrictions"
                    hint="Select any restrictions the recommendation engine should respect."
                    options={[...optionCatalog.dietary_restrictions]}
                    selected={form.dietary_restrictions}
                    onToggle={(value) => toggleArrayField("dietary_restrictions", value)}
                  />

                  <MultiSelectField
                    label="Drink preferences"
                    hint="Select the drink styles you usually want included in your experience."
                    options={[...optionCatalog.drink_preferences]}
                    selected={form.drink_preferences}
                    onToggle={(value) => toggleArrayField("drink_preferences", value)}
                  />

                  <div className="grid grid-2">
                    <SelectField
                      id="spice_tolerance"
                      label="Spice tolerance"
                      value={form.spice_tolerance}
                      placeholder="Select spice tolerance"
                      options={spiceOptions}
                      onChange={(value) =>
                        setForm((current) => ({ ...current, spice_tolerance: value }))
                      }
                    />

                    <SelectField
                      id="price_sensitivity"
                      label="Price sensitivity"
                      value={form.price_sensitivity}
                      placeholder="Select budget comfort"
                      options={priceOptions}
                      onChange={(value) =>
                        setForm((current) => ({ ...current, price_sensitivity: value }))
                      }
                    />
                  </div>
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Dining memory
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Favorite dining experiences"
                    hint="Choose the types of outings you most want SAVR to remember."
                    options={[...optionCatalog.favorite_dining_experiences]}
                    selected={form.favorite_dining_experiences}
                    onToggle={(value) =>
                      toggleArrayField("favorite_dining_experiences", value)
                    }
                  />

                  <MultiSelectField
                    label="Favorite restaurants"
                    hint={
                      isLoadingRestaurants
                        ? "Loading your available restaurant list..."
                        : restaurantOptions.length > 0
                          ? "Choose one or more restaurants from the live restaurant catalog."
                          : "No restaurant list was available, so this will stay empty for now."
                    }
                    options={restaurantOptions}
                    selected={form.favorite_restaurants}
                    onToggle={(value) => toggleArrayField("favorite_restaurants", value)}
                  />

                  <div className="form-row">
                    <label htmlFor="bio">Dining bio</label>
                    <textarea
                      id="bio"
                      rows={4}
                      value={form.bio}
                      placeholder="Describe the kind of dining experience you usually want SAVR to optimize for."
                      onChange={(e) =>
                        setForm((current) => ({ ...current, bio: e.target.value }))
                      }
                    />
                    <small className="muted">
                      Keep this short and preference-focused. This gives extra context to your profile.
                    </small>
                  </div>
                </div>
              </div>
            </div>

            <div className="button-row">
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Saving profile..." : "Save SAVR profile"}
              </Button>

              <Button type="button" variant="ghost" onClick={resetForm}>
                Reset selections
              </Button>
            </div>
          </form>
        </Card>

        <div className="grid" style={{ gap: "1rem" }}>
          <Card
            title="Selection summary"
            subtitle="Quick view of how much detail your profile currently contains"
            actions={<Badge tone="success">Live preview</Badge>}
          >
            <div className="grid grid-2">
              {previewStats.map((stat) => (
                <div key={stat.label} className="item">
                  <p className="muted" style={{ marginBottom: "0.25rem" }}>
                    {stat.label}
                  </p>
                  <strong style={{ fontSize: "1.15rem" }}>{stat.value}</strong>
                </div>
              ))}
            </div>
          </Card>

          <Card
            title="Current profile snapshot"
            subtitle="This shows the exact payload being prepared for the backend"
            actions={<Badge>JSON view</Badge>}
          >
            <pre className="code-block">
{JSON.stringify(
  {
    dietary_restrictions: form.dietary_restrictions,
    cuisine_preferences: form.cuisine_preferences,
    texture_preferences: form.texture_preferences,
    dining_pace_preferences: form.dining_pace_preferences,
    social_preferences: form.social_preferences,
    drink_preferences: form.drink_preferences,
    atmosphere_preferences: form.atmosphere_preferences,
    favorite_dining_experiences: form.favorite_dining_experiences,
    favorite_restaurants: form.favorite_restaurants,
    bio: form.bio || null,
    spice_tolerance: form.spice_tolerance || null,
    price_sensitivity: form.price_sensitivity || null
  },
  null,
  2
)}
            </pre>
          </Card>

          {submittedJson ? (
            <Card
              title="Last submitted payload"
              subtitle="Captured after a successful save"
              actions={<Badge tone="accent">Saved</Badge>}
            >
              <pre className="code-block">{submittedJson}</pre>
            </Card>
          ) : null}
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

marker = "/* PHASE 2 ONBOARDING UI REWORK */"
if marker not in text:
    text += """

/* PHASE 2 ONBOARDING UI REWORK */
.onboarding-grid {
  align-items: start;
}

.multi-select-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  margin-top: 0.65rem;
}

.multi-select-chip {
  border: 1px solid rgba(148, 163, 184, 0.2);
  background: rgba(15, 23, 42, 0.45);
  color: var(--text-main);
  padding: 0.72rem 0.95rem;
  border-radius: 999px;
  transition:
    transform 150ms ease,
    border-color 150ms ease,
    background-color 150ms ease,
    box-shadow 150ms ease;
}

.multi-select-chip:hover {
  transform: translateY(-1px);
  border-color: rgba(96, 165, 250, 0.34);
  background: rgba(30, 41, 59, 0.75);
}

.multi-select-chip--active {
  border-color: rgba(96, 165, 250, 0.44);
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.22), rgba(139, 92, 246, 0.18));
  box-shadow: 0 10px 22px rgba(15, 23, 42, 0.28);
}

textarea {
  width: 100%;
  min-height: 110px;
  resize: vertical;
  border-radius: 0.95rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(8, 15, 28, 0.84);
  color: var(--text-main);
  padding: 0.9rem 1rem;
  outline: none;
  transition: border-color 160ms ease, box-shadow 160ms ease, transform 160ms ease;
}

textarea:focus {
  border-color: rgba(96, 165, 250, 0.42);
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.12);
}

.code-block {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  border-radius: 1rem;
  padding: 1rem;
  background: rgba(8, 15, 28, 0.9);
  border: 1px solid rgba(148, 163, 184, 0.14);
  color: #dbeafe;
  font-size: 0.9rem;
  line-height: 1.5;
  overflow-x: auto;
}
"""
    styles_path.write_text(text)
PY

echo "Phase 2 onboarding UI rework applied successfully in: $FRONTEND_DIR"
