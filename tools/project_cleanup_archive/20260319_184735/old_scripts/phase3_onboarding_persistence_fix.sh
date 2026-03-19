#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" && -d "$ROOT_DIR/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
  BACKEND_DIR="$ROOT_DIR/backend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" && -d "$ROOT_DIR/backend/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
  BACKEND_DIR="$ROOT_DIR/backend/backend"
else
  echo "Error: could not find frontend/src and backend/app from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

cat > "$BACKEND_DIR/app/schemas/onboarding.py" <<'EOF'
from typing import Optional

from pydantic import BaseModel, Field


class OnboardingRequest(BaseModel):
    dietary_restrictions: list[str] = Field(default_factory=list)
    cuisine_preferences: list[str] = Field(default_factory=list)
    texture_preferences: list[str] = Field(default_factory=list)
    dining_pace_preferences: list[str] = Field(default_factory=list)
    social_preferences: list[str] = Field(default_factory=list)
    drink_preferences: list[str] = Field(default_factory=list)
    atmosphere_preferences: list[str] = Field(default_factory=list)
    favorite_dining_experiences: list[str] = Field(default_factory=list)
    favorite_restaurants: list[str] = Field(default_factory=list)
    bio: Optional[str] = None
    spice_tolerance: Optional[str] = None
    price_sensitivity: Optional[str] = None


class OnboardingResponse(BaseModel):
    message: str
    onboarding_completed: bool


class OnboardingStateResponse(BaseModel):
    dietary_restrictions: list[str] = Field(default_factory=list)
    cuisine_preferences: list[str] = Field(default_factory=list)
    texture_preferences: list[str] = Field(default_factory=list)
    dining_pace_preferences: list[str] = Field(default_factory=list)
    social_preferences: list[str] = Field(default_factory=list)
    drink_preferences: list[str] = Field(default_factory=list)
    atmosphere_preferences: list[str] = Field(default_factory=list)
    favorite_dining_experiences: list[str] = Field(default_factory=list)
    favorite_restaurants: list[str] = Field(default_factory=list)
    bio: Optional[str] = None
    spice_tolerance: Optional[str] = None
    price_sensitivity: Optional[str] = None
    onboarding_completed: bool = False
EOF

cat > "$BACKEND_DIR/app/services/onboarding_service.py" <<'EOF'
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.onboarding import OnboardingRequest, OnboardingStateResponse


class OnboardingService:
    def __init__(self, db: Session):
        self.db = db
        self.user_repository = UserRepository(db)

    def save_onboarding(self, user: User, payload: OnboardingRequest) -> User:
        self.user_repository.upsert_preferences(
            user_id=user.id,
            dietary_restrictions=payload.dietary_restrictions,
            cuisine_preferences=payload.cuisine_preferences,
            texture_preferences=payload.texture_preferences,
            dining_pace_preferences=payload.dining_pace_preferences,
            social_preferences=payload.social_preferences,
            drink_preferences=payload.drink_preferences,
            atmosphere_preferences=payload.atmosphere_preferences,
            spice_tolerance=payload.spice_tolerance,
            price_sensitivity=payload.price_sensitivity,
        )

        self.user_repository.upsert_profile(
            user_id=user.id,
            bio=payload.bio,
            favorite_dining_experiences=payload.favorite_dining_experiences,
            favorite_restaurants=payload.favorite_restaurants,
        )

        updated_user = self.user_repository.mark_onboarding_complete(user.id)
        return updated_user

    def get_onboarding_state(self, user: User) -> OnboardingStateResponse:
        hydrated_user = self.user_repository.get_by_id(user.id)

        preference = hydrated_user.preference if hydrated_user else None
        profile = hydrated_user.profile if hydrated_user else None

        return OnboardingStateResponse(
            dietary_restrictions=list(preference.dietary_restrictions or []) if preference else [],
            cuisine_preferences=list(preference.cuisine_preferences or []) if preference else [],
            texture_preferences=list(preference.texture_preferences or []) if preference else [],
            dining_pace_preferences=list(preference.dining_pace_preferences or []) if preference else [],
            social_preferences=list(preference.social_preferences or []) if preference else [],
            drink_preferences=list(preference.drink_preferences or []) if preference else [],
            atmosphere_preferences=list(preference.atmosphere_preferences or []) if preference else [],
            favorite_dining_experiences=list(profile.favorite_dining_experiences or []) if profile else [],
            favorite_restaurants=list(profile.favorite_restaurants or []) if profile else [],
            bio=profile.bio if profile else None,
            spice_tolerance=preference.spice_tolerance if preference else None,
            price_sensitivity=preference.price_sensitivity if preference else None,
            onboarding_completed=bool(hydrated_user.onboarding_completed) if hydrated_user else False,
        )
EOF

cat > "$BACKEND_DIR/app/api/routes/onboarding.py" <<'EOF'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.schemas.onboarding import (
    OnboardingRequest,
    OnboardingResponse,
    OnboardingStateResponse,
)
from app.services.onboarding_service import OnboardingService

router = APIRouter()


@router.get("", response_model=OnboardingStateResponse)
def get_onboarding(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return OnboardingService(db).get_onboarding_state(current_user)


@router.post("", response_model=OnboardingResponse)
def submit_onboarding(
    payload: OnboardingRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    updated_user = OnboardingService(db).save_onboarding(current_user, payload)
    return OnboardingResponse(
        message="Onboarding saved successfully",
        onboarding_completed=updated_user.onboarding_completed,
    )
EOF

cat > "$FRONTEND_DIR/src/types.ts" <<'EOF'
export type AuthUser = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  onboarding_completed: boolean;
};

export type UserProfileResponse = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  is_active: boolean;
  onboarding_completed: boolean;
  created_at: string;
};

export type TokenResponse = {
  access_token: string;
  token_type: string;
};

export type RestaurantListItem = {
  id: number;
  name: string;
  description: string | null;
  city: string;
  price_tier: string;
  atmosphere: string | null;
  pace: string | null;
  social_style: string | null;
  serves_alcohol: boolean;
};

export type Tag = {
  id: number;
  name: string;
  category: string;
};

export type MenuItem = {
  id: number;
  restaurant_id: number;
  name: string;
  category: string;
  price: number | null;
  description: string | null;
  is_signature: boolean;
  tags: Tag[];
};

export type RestaurantDetail = RestaurantListItem & {
  tags: Tag[];
  menu_items: MenuItem[];
};

export type OnboardingPayload = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string | null;
  spice_tolerance: string | null;
  price_sensitivity: string | null;
};

export type OnboardingResponse = {
  message: string;
  onboarding_completed: boolean;
};

export type OnboardingState = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string | null;
  spice_tolerance: string | null;
  price_sensitivity: string | null;
  onboarding_completed: boolean;
};

export type ScoreBreakdownItem = {
  label: string;
  points: number;
};

export type RecommendationRequestSummary = {
  outing_type?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus: boolean;
  atmosphere: string[];
};

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  rank?: number;
  fit_label?: string;
  reasons: string[];
  explanation?: string | null;
  confidence_level?: "high" | "medium" | "exploratory" | string;
  matched_signals?: string[];
  penalized_signals?: string[];
  score_breakdown?: ScoreBreakdownItem[];
  suggested_dishes: string[];
  suggested_drinks: string[];
};

export type RecommendationResponse = {
  mode: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: RecommendationRequestSummary;
  results: RecommendationItem[];
};

export type ExperienceRating = {
  id: number;
  category: string;
  score: number;
};

export type Experience = {
  id: number;
  user_id: number;
  restaurant_id: number | null;
  title: string | null;
  occasion: string | null;
  social_context: string | null;
  notes: string | null;
  overall_rating: number | null;
  created_at: string;
  ratings: ExperienceRating[];
};
EOF

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
  const [submittedJson, setSubmittedJson] = useState("");
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
          setMessage("Loaded your saved SAVR profile.");
        }
      } catch (err) {
        if (!cancelled) {
          setRestaurantOptions([]);
          setError(
            err instanceof Error
              ? err.message
              : "Failed to load saved onboarding data"
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

  const previewStats = useMemo(
    () => [
      { label: "Cuisine picks", value: form.cuisine_preferences.length },
      { label: "Drink picks", value: form.drink_preferences.length },
      { label: "Atmosphere picks", value: form.atmosphere_preferences.length },
      { label: "Favorite venues", value: form.favorite_restaurants.length }
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
    setMessage("Reverted form to your last saved onboarding state.");
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
      setSubmittedJson(JSON.stringify(payload, null, 2));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save onboarding");
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isHydrating) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading your saved SAVR profile...</div>
      </div>
    );
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Profile setup</p>
        <h1 className="page-title">Build your SAVR dining profile</h1>
        <p className="muted" style={{ maxWidth: "820px", marginBottom: 0 }}>
          Choose the dining signals that best describe your taste, pace, social style,
          and atmosphere preferences. This version now reloads your real saved profile
          from the backend so edits persist when you come back.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2 onboarding-grid">
        <Card
          title="Preference studio"
          subtitle="Guided selections that shape recommendation quality"
          actions={<Badge tone="accent">Phase 3</Badge>}
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

              <Button type="button" variant="ghost" onClick={resetToSavedState}>
                Reset to saved profile
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

echo "Phase 3 onboarding persistence fixes applied successfully."
echo "Updated backend: app/schemas/onboarding.py, app/services/onboarding_service.py, app/api/routes/onboarding.py"
echo "Updated frontend: src/types.ts, src/pages/OnboardingPage.tsx"
