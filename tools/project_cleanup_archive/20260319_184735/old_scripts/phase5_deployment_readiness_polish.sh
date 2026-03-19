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
import {
  OnboardingPayload,
  OnboardingResponse,
  OnboardingState,
  RestaurantListItem
} from "../types";

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

function toFormState(source: OnboardingState | null | undefined): OnboardingFormState {
  return {
    dietary_restrictions: [...(source?.dietary_restrictions ?? [])],
    cuisine_preferences: [...(source?.cuisine_preferences ?? [])],
    texture_preferences: [...(source?.texture_preferences ?? [])],
    dining_pace_preferences: [...(source?.dining_pace_preferences ?? [])],
    social_preferences: [...(source?.social_preferences ?? [])],
    drink_preferences: [...(source?.drink_preferences ?? [])],
    atmosphere_preferences: [...(source?.atmosphere_preferences ?? [])],
    favorite_dining_experiences: [...(source?.favorite_dining_experiences ?? [])],
    favorite_restaurants: [...(source?.favorite_restaurants ?? [])],
    bio: source?.bio ?? "",
    spice_tolerance: source?.spice_tolerance ?? "",
    price_sensitivity: source?.price_sensitivity ?? ""
  };
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
  const [savedState, setSavedState] = useState<OnboardingFormState>(emptyForm);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [isLoadingRestaurants, setIsLoadingRestaurants] = useState(true);
  const [isHydrating, setIsHydrating] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function hydrate() {
      try {
        const [restaurants, onboardingState] = await Promise.all([
          apiRequest<RestaurantListItem[]>("/restaurants"),
          apiRequest<OnboardingState>("/onboarding")
        ]);

        if (cancelled) {
          return;
        }

        const restaurantNames = restaurants.map((restaurant) => restaurant.name);
        const nextForm = toFormState(onboardingState);

        setRestaurantOptions(restaurantNames);
        setSavedState(nextForm);
        setForm(nextForm);

        if (onboardingState.onboarding_completed) {
          setMessage("Your SAVR profile has been loaded successfully.");
        }
      } catch (err) {
        if (!cancelled) {
          setRestaurantOptions([]);
          setError(
            err instanceof Error
              ? err.message
              : "We could not load your saved profile right now."
          );
        }
      } finally {
        if (!cancelled) {
          setIsLoadingRestaurants(false);
          setIsHydrating(false);
        }
      }
    }

    void hydrate();

    return () => {
      cancelled = true;
    };
  }, []);

  const completionStats = useMemo(
    () => [
      { label: "Cuisine", value: form.cuisine_preferences.length },
      { label: "Atmosphere", value: form.atmosphere_preferences.length },
      { label: "Drinks", value: form.drink_preferences.length },
      { label: "Favorites", value: form.favorite_restaurants.length }
    ],
    [form]
  );

  function toggleArrayField(
    field: keyof Pick<
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
    >,
    value: string
  ) {
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

  function resetToSavedState() {
    setForm({
      ...savedState,
      dietary_restrictions: [...savedState.dietary_restrictions],
      cuisine_preferences: [...savedState.cuisine_preferences],
      texture_preferences: [...savedState.texture_preferences],
      dining_pace_preferences: [...savedState.dining_pace_preferences],
      social_preferences: [...savedState.social_preferences],
      drink_preferences: [...savedState.drink_preferences],
      atmosphere_preferences: [...savedState.atmosphere_preferences],
      favorite_dining_experiences: [...savedState.favorite_dining_experiences],
      favorite_restaurants: [...savedState.favorite_restaurants]
    });
    setMessage("Your form has been reset to the last saved version.");
    setError("");
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

      const persisted = await apiRequest<OnboardingState>("/onboarding");
      const persistedForm = toFormState(persisted);

      setSavedState(persistedForm);
      setForm(persistedForm);

      await refreshUser();

      setMessage(response.message);
    } catch (err) {
      setError(err instanceof Error ? err.message : "We could not save your profile.");
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isHydrating) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading your SAVR profile...</div>
      </div>
    );
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">SAVR profile</p>
        <h1 className="page-title">Shape your dining preferences</h1>
        <p className="muted" style={{ maxWidth: "820px", marginBottom: 0 }}>
          Tell SAVR what kinds of meals, spaces, moods, and social settings fit you best
          so recommendations feel more relevant and more personal.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2 onboarding-grid">
        <Card
          title="Your dining profile"
          subtitle="Update the signals SAVR uses to personalize recommendations"
          actions={<Badge tone="accent">Profile</Badge>}
        >
          <form className="form" onSubmit={handleSubmit}>
            <div className="list">
              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Taste and cravings
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Cuisine preferences"
                    hint="Choose the cuisines you most often enjoy."
                    options={[...optionCatalog.cuisine_preferences]}
                    selected={form.cuisine_preferences}
                    onToggle={(value) => toggleArrayField("cuisine_preferences", value)}
                  />

                  <MultiSelectField
                    label="Texture preferences"
                    hint="Choose the textures and food qualities you tend to look for."
                    options={[...optionCatalog.texture_preferences]}
                    selected={form.texture_preferences}
                    onToggle={(value) => toggleArrayField("texture_preferences", value)}
                  />
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Pace and setting
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Dining pace"
                    hint="Select the rhythm you prefer for meals and outings."
                    options={[...optionCatalog.dining_pace_preferences]}
                    selected={form.dining_pace_preferences}
                    onToggle={(value) => toggleArrayField("dining_pace_preferences", value)}
                  />

                  <MultiSelectField
                    label="Social preferences"
                    hint="Choose the social situations that most often describe your dining plans."
                    options={[...optionCatalog.social_preferences]}
                    selected={form.social_preferences}
                    onToggle={(value) => toggleArrayField("social_preferences", value)}
                  />

                  <MultiSelectField
                    label="Atmosphere preferences"
                    hint="Pick the moods and environments that feel right for you."
                    options={[...optionCatalog.atmosphere_preferences]}
                    selected={form.atmosphere_preferences}
                    onToggle={(value) => toggleArrayField("atmosphere_preferences", value)}
                  />
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: "0.55rem" }}>
                  Restrictions and drink style
                </p>
                <div className="grid" style={{ gap: "1rem" }}>
                  <MultiSelectField
                    label="Dietary restrictions"
                    hint="Select any restrictions or requirements SAVR should respect."
                    options={[...optionCatalog.dietary_restrictions]}
                    selected={form.dietary_restrictions}
                    onToggle={(value) => toggleArrayField("dietary_restrictions", value)}
                  />

                  <MultiSelectField
                    label="Drink preferences"
                    hint="Choose the drink styles you usually want included in a dining experience."
                    options={[...optionCatalog.drink_preferences]}
                    selected={form.drink_preferences}
                    onToggle={(value) => toggleArrayField("drink_preferences", value)}
                  />

                  <div className="grid grid-2">
                    <SelectField
                      id="spice_tolerance"
                      label="Spice tolerance"
                      value={form.spice_tolerance}
                      placeholder="Select your spice tolerance"
                      options={spiceOptions}
                      onChange={(value) =>
                        setForm((current) => ({ ...current, spice_tolerance: value }))
                      }
                    />

                    <SelectField
                      id="price_sensitivity"
                      label="Budget comfort"
                      value={form.price_sensitivity}
                      placeholder="Select your usual budget range"
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
                    hint="Choose the kinds of outings you want SAVR to remember and prioritize."
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
                        ? "Loading available restaurants..."
                        : restaurantOptions.length > 0
                          ? "Select the restaurants you already like most."
                          : "No restaurants are currently available to select."
                    }
                    options={restaurantOptions}
                    selected={form.favorite_restaurants}
                    onToggle={(value) => toggleArrayField("favorite_restaurants", value)}
                  />

                  <div className="form-row">
                    <label htmlFor="bio">Dining note</label>
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
                      A short note helps SAVR understand your style beyond the selected options.
                    </small>
                  </div>
                </div>
              </div>
            </div>

            <div className="button-row">
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Saving..." : "Save profile"}
              </Button>

              <Button type="button" variant="ghost" onClick={resetToSavedState}>
                Reset to saved
              </Button>
            </div>
          </form>
        </Card>

        <div className="grid" style={{ gap: "1rem" }}>
          <Card
            title="Profile completeness"
            subtitle="A simple view of how much preference detail you have added"
            actions={<Badge tone="success">Summary</Badge>}
          >
            <div className="grid grid-2">
              {completionStats.map((stat) => (
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
            title="Why this matters"
            subtitle="A more complete profile helps recommendations feel sharper and more personal"
            actions={<Badge>Tips</Badge>}
          >
            <div className="list">
              <div className="item">
                <strong>More accurate restaurant matching</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Cuisine, atmosphere, and pace selections help SAVR narrow the results more intelligently.
                </p>
              </div>

              <div className="item">
                <strong>Better dining context</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Social and drink preferences help the system understand the kind of outing you are planning.
                </p>
              </div>

              <div className="item">
                <strong>Stronger long-term recommendations</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Favorites and profile notes give SAVR more memory to build on as you keep using the platform.
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

cat > "$FRONTEND_DIR/src/pages/DashboardPage.tsx" <<'EOF'
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingState } from "../types";

function formatLabel(value: string) {
  return value
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function renderSignalList(values: string[], emptyText: string) {
  if (values.length === 0) {
    return <p className="muted" style={{ marginBottom: 0 }}>{emptyText}</p>;
  }

  return (
    <div className="dashboard-chip-row">
      {values.slice(0, 6).map((value) => (
        <span key={value} className="dashboard-chip">
          {formatLabel(value)}
        </span>
      ))}
    </div>
  );
}

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "Guest";

  const [profileState, setProfileState] = useState<OnboardingState | null>(null);
  const [profileError, setProfileError] = useState("");
  const [isLoadingProfile, setIsLoadingProfile] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadProfileSnapshot() {
      try {
        const state = await apiRequest<OnboardingState>("/onboarding");
        if (!cancelled) {
          setProfileState(state);
        }
      } catch (err) {
        if (!cancelled) {
          setProfileError(
            err instanceof Error ? err.message : "We could not load your profile summary."
          );
        }
      } finally {
        if (!cancelled) {
          setIsLoadingProfile(false);
        }
      }
    }

    void loadProfileSnapshot();

    return () => {
      cancelled = true;
    };
  }, []);

  const quickPanels = useMemo(
    () => [
      {
        title: "Profile status",
        value: profileState?.onboarding_completed ? "Ready" : "Incomplete",
        subtitle: profileState?.onboarding_completed
          ? "Your SAVR profile is active and can be refined anytime."
          : "Finish your profile to improve your recommendation quality.",
        tone: profileState?.onboarding_completed ? ("success" as const) : ("accent" as const)
      },
      {
        title: "Cuisine preferences",
        value: String(profileState?.cuisine_preferences.length ?? 0),
        subtitle: "Saved cuisine signals currently helping shape your results.",
        tone: "accent" as const
      },
      {
        title: "Atmosphere preferences",
        value: String(profileState?.atmosphere_preferences.length ?? 0),
        subtitle: "Saved mood and setting signals available for matching.",
        tone: "default" as const
      }
    ],
    [profileState]
  );

  const workflowSteps = [
    {
      title: "Review your profile",
      description:
        "Make sure your taste, pace, drink, and atmosphere selections reflect the kind of dining experience you actually want."
    },
    {
      title: "Explore restaurants",
      description:
        "Browse the restaurant catalog and confirm your favorites align with the venues available in the system."
    },
    {
      title: "Generate recommendations",
      description:
        "Use the recommendation workflow after your profile is current so the system has stronger context."
    }
  ];

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div className="grid" style={{ gap: "1rem" }}>
          <div>
            <p className="navbar-eyebrow">Welcome</p>
            <h1 className="page-title">Welcome back, {firstName}</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Use this space to review your profile, check what SAVR already knows about
              your dining style, and move into recommendations when you are ready.
            </p>
          </div>

          <div>
            <Badge>SAVR</Badge>
            <Badge tone="accent">Profile-aware</Badge>
            <Badge tone="success">Ready to explore</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Find recommendations</Button>
            </Link>
            <Link to="/restaurants">
              <Button variant="ghost">Browse restaurants</Button>
            </Link>
            <Link to="/onboarding">
              <Button variant="secondary">Edit profile</Button>
            </Link>
          </div>
        </div>
      </section>

      <section className="grid grid-3">
        {quickPanels.map((panel) => (
          <Card
            key={panel.title}
            title={panel.title}
            subtitle={panel.subtitle}
            actions={<Badge tone={panel.tone}>{panel.title}</Badge>}
          >
            <p className="kpi">{panel.value}</p>
          </Card>
        ))}
      </section>

      <section className="grid grid-2">
        <Card
          title="Your saved profile"
          subtitle="A quick summary of the preferences currently guiding SAVR"
          actions={<Badge tone="accent">Profile</Badge>}
        >
          {isLoadingProfile ? (
            <p className="muted" style={{ marginBottom: 0 }}>Loading your profile...</p>
          ) : profileError ? (
            <div className="error">{profileError}</div>
          ) : (
            <div className="list">
              <div className="item">
                <strong>Cuisine preferences</strong>
                {renderSignalList(
                  profileState?.cuisine_preferences ?? [],
                  "No cuisine preferences saved yet."
                )}
              </div>

              <div className="item">
                <strong>Drink preferences</strong>
                {renderSignalList(
                  profileState?.drink_preferences ?? [],
                  "No drink preferences saved yet."
                )}
              </div>

              <div className="item">
                <strong>Atmosphere preferences</strong>
                {renderSignalList(
                  profileState?.atmosphere_preferences ?? [],
                  "No atmosphere preferences saved yet."
                )}
              </div>

              <div className="item">
                <strong>Favorite restaurants</strong>
                {renderSignalList(
                  profileState?.favorite_restaurants ?? [],
                  "No favorite restaurants saved yet."
                )}
              </div>

              <div className="item">
                <strong>Dining note</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {profileState?.bio?.trim() || "No dining note saved yet."}
                </p>
              </div>
            </div>
          )}
        </Card>

        <Card
          title="Suggested next steps"
          subtitle="A simple path for users exploring the product for the first time"
          actions={<Badge tone="success">Guide</Badge>}
        >
          <div className="list">
            {workflowSteps.map((step, index) => (
              <div className="item" key={step.title}>
                <p className="navbar-eyebrow" style={{ marginBottom: "0.35rem" }}>
                  Step {index + 1}
                </p>
                <strong>{step.title}</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {step.description}
                </p>
              </div>
            ))}
          </div>

          <hr />

          <div className="button-row">
            <Link to="/onboarding">
              <Button variant="ghost">Review profile</Button>
            </Link>
            <Link to="/recommendations">
              <Button>Start exploring</Button>
            </Link>
          </div>
        </Card>
      </section>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" <<'EOF'
import { useLocation } from "react-router-dom";

type NavbarProps = {
  userName?: string;
};

const titleMap: Record<
  string,
  { eyebrow: string; title: string; subtitle: string }
> = {
  "/dashboard": {
    eyebrow: "Home",
    title: "Your SAVR dashboard",
    subtitle:
      "Review your saved dining preferences, check profile readiness, and continue into recommendations."
  },
  "/onboarding": {
    eyebrow: "Profile",
    title: "Update your dining profile",
    subtitle:
      "Tell SAVR more about your tastes, habits, and ideal dining atmosphere."
  },
  "/recommendations": {
    eyebrow: "Recommendations",
    title: "Find your next dining match",
    subtitle:
      "Explore dining recommendations shaped by your profile, preferences, and context."
  },
  "/restaurants": {
    eyebrow: "Restaurants",
    title: "Browse available venues",
    subtitle:
      "Review the restaurant catalog and discover places that may fit your dining style."
  },
  "/experiences": {
    eyebrow: "Experiences",
    title: "Track dining memories",
    subtitle:
      "Review and log dining experiences to help strengthen future recommendations."
  }
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content = titleMap[location.pathname] ?? {
    eyebrow: "Workspace",
    title: "SAVR",
    subtitle: "A cleaner dining discovery workspace designed for real user testing."
  };

  const today = new Date().toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric"
  });

  return (
    <header className="app-navbar">
      <div className="navbar-copy">
        <p className="navbar-eyebrow">{content.eyebrow}</p>
        <h2 className="navbar-title">{content.title}</h2>
        <p className="navbar-subtitle">{content.subtitle}</p>
      </div>

      <div className="navbar-right">
        <div className="navbar-date-chip">{today}</div>

        <div className="navbar-meta-card">
          <span className="status-dot" />
          <div>
            <p className="navbar-meta-label">Signed in</p>
            <strong>{userName || "Guest user"}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
EOF

cat > "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" <<'EOF'
import { NavLink } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "DB" },
  { to: "/onboarding", label: "Profile", short: "PF" },
  { to: "/recommendations", label: "Recommendations", short: "RC" },
  { to: "/restaurants", label: "Restaurants", short: "RS" },
  { to: "/experiences", label: "Experiences", short: "EX" }
];

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">SV</div>

        <div>
          <p className="sidebar-eyebrow">Personal dining guide</p>
          <h1 className="sidebar-brand">SAVR</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Current user</p>
          <span className="sidebar-online-pill">Online</span>
        </div>

        <strong className="sidebar-user-name">{userName || "Guest user"}</strong>

        <p className="muted">
          Explore restaurants, shape your profile, and discover more relevant dining experiences.
        </p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              ["sidebar-link", isActive ? "sidebar-link--active" : ""]
                .filter(Boolean)
                .join(" ")
            }
          >
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <button
          className="button ghost sidebar-logout"
          type="button"
          onClick={onLogout}
        >
          Logout
        </button>
      </div>
    </aside>
  );
}
EOF

python3 - <<PY
from pathlib import Path

styles_path = Path(r"$FRONTEND_DIR/src/styles.css")
text = styles_path.read_text()

marker = "/* PHASE 5 DEPLOYMENT READINESS POLISH */"
if marker not in text:
    text += """

/* PHASE 5 DEPLOYMENT READINESS POLISH */
.sidebar-footer {
  margin-top: auto;
  display: grid;
  gap: 0.85rem;
}

.sidebar-logout {
  width: 100%;
}

.page-title {
  letter-spacing: -0.02em;
}

.success,
.error {
  border-radius: 1rem;
}

.card .muted {
  line-height: 1.55;
}
"""
    styles_path.write_text(text)
PY

echo "Phase 5 deployment-readiness polish applied successfully in: $FRONTEND_DIR"
