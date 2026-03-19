import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

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

type OnboardingOptionValue = {
  value: string;
  label: string;
  description?: string | null;
};

type OnboardingFieldDefinition = {
  key: string;
  label: string;
  description: string;
  help_text?: string | null;
  select_mode: "single" | "multi" | "range" | string;
  optional: boolean;
  allow_skip: boolean;
  ui_control: string;
  step_order: number;
  options: OnboardingOptionValue[];
};

type OnboardingOptionsResponse = {
  version: string;
  fields: OnboardingFieldDefinition[];
};

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
  budget_min_per_person: string;
  budget_max_per_person: string;
  onboarding_version: string;
};

type ChoiceFieldKey =
  | "dietary_restrictions"
  | "cuisine_preferences"
  | "texture_preferences"
  | "dining_pace_preferences"
  | "social_preferences"
  | "drink_preferences"
  | "atmosphere_preferences"
  | "favorite_dining_experiences"
  | "favorite_restaurants";

type CustomStepDefinition = {
  key: "favorite_dining_experiences" | "favorite_restaurants" | "bio";
  label: string;
  description: string;
  help_text?: string;
  select_mode: "multi" | "text";
  optional: boolean;
  allow_skip: boolean;
  step_order: number;
};

type WizardStep = OnboardingFieldDefinition | CustomStepDefinition;

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
  price_sensitivity: "",
  budget_min_per_person: "",
  budget_max_per_person: "",
  onboarding_version: ""
};

const fallbackOnboardingOptions: OnboardingOptionsResponse = {
  version: "guided-v1",
  fields: [
    {
      key: "cuisine_preferences",
      label: "Cuisine preferences",
      description: "Choose the food styles you most want SAVR to prioritize.",
      help_text: "Choose one or more. Pick the cuisines that really matter to you.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 1,
      options: [
        { value: "italian", label: "Italian" },
        { value: "mexican", label: "Mexican" },
        { value: "japanese", label: "Japanese" },
        { value: "korean", label: "Korean" },
        { value: "thai", label: "Thai" },
        { value: "indian", label: "Indian" },
        { value: "mediterranean", label: "Mediterranean" },
        { value: "comfort food", label: "Comfort food" },
        { value: "seafood", label: "Seafood" },
        { value: "brunch", label: "Brunch" },
        { value: "dessert", label: "Dessert" },
        { value: "fast food", label: "Fast food" }
      ]
    },
    {
      key: "atmosphere_preferences",
      label: "Atmosphere preferences",
      description: "Choose the kinds of spaces you naturally enjoy.",
      help_text: "Choose one or more. These describe the vibe, not the food.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 2,
      options: [
        { value: "cozy", label: "Cozy" },
        { value: "romantic", label: "Romantic" },
        { value: "upscale", label: "Upscale" },
        { value: "lively", label: "Lively" },
        { value: "quiet", label: "Quiet" },
        { value: "casual", label: "Casual" },
        { value: "scenic", label: "Scenic" },
        { value: "family friendly", label: "Family friendly" },
        {
          value: "live music",
          label: "Live music",
          description: "Useful when performances matter to the outing."
        },
        {
          value: "trivia",
          label: "Trivia night",
          description: "Useful when recurring trivia events matter to the outing."
        }
      ]
    },
    {
      key: "dining_pace_preferences",
      label: "Dining pace",
      description: "Choose whether you usually want a quick stop, balanced meal, or slower experience.",
      help_text: "Choose one or more. This helps separate quick bites from slower sit-down meals.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 3,
      options: [
        { value: "quick", label: "Quick bite" },
        { value: "steady", label: "Balanced pace" },
        { value: "slow", label: "Slow experience" }
      ]
    },
    {
      key: "social_preferences",
      label: "Who you usually dine with",
      description: "This helps rank better for solo meals, dates, families, and group outings.",
      help_text: "Choose one or more. Select the social contexts that matter most often.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 4,
      options: [
        { value: "solo", label: "Solo" },
        { value: "date", label: "Date night" },
        { value: "friends", label: "Friends / group outing" },
        { value: "family", label: "Family" },
        { value: "students", label: "Students / budget-conscious" }
      ]
    },
    {
      key: "drink_preferences",
      label: "Drink preferences",
      description: "Choose drink categories that matter during recommendations.",
      help_text: "Choose one or more.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 5,
      options: [
        { value: "coffee", label: "Coffee" },
        { value: "mocktails", label: "Mocktails" },
        { value: "cocktails", label: "Cocktails" },
        { value: "wine", label: "Wine" },
        { value: "beer", label: "Beer" }
      ]
    },
    {
      key: "dietary_restrictions",
      label: "Dietary restrictions",
      description: "Only choose restrictions that should actively filter recommendations.",
      help_text: "Optional. Leave this empty if you have no dietary restrictions.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 6,
      options: [
        { value: "vegetarian", label: "Vegetarian" },
        { value: "vegan", label: "Vegan" },
        { value: "gluten free", label: "Gluten free" },
        { value: "dairy free", label: "Dairy free" },
        { value: "halal", label: "Halal" },
        { value: "nut aware", label: "Nut aware" }
      ]
    },
    {
      key: "price_sensitivity",
      label: "Budget comfort",
      description: "Pick the overall budget feel that suits you most often.",
      help_text: "Choose one. This is your general price comfort level.",
      select_mode: "single",
      optional: true,
      allow_skip: true,
      ui_control: "radio",
      step_order: 7,
      options: [
        {
          value: "budget",
          label: "Budget-conscious",
          description: "Usually looking for lower-cost options."
        },
        {
          value: "balanced",
          label: "Balanced",
          description: "Comfortable with moderate prices."
        },
        {
          value: "premium",
          label: "Premium",
          description: "Comfortable paying more for the right experience."
        }
      ]
    },
    {
      key: "budget_range",
      label: "Numeric budget range",
      description: "Set your typical spend per person in dollars.",
      help_text: "Optional. Use numbers if you want more precision.",
      select_mode: "range",
      optional: true,
      allow_skip: true,
      ui_control: "range",
      step_order: 8,
      options: []
    }
  ]
};

const favoriteExperienceOptions = [
  "brunch catch-up",
  "quick student bite",
  "date night dinner",
  "live music night",
  "trivia night",
  "coffee catch-up",
  "family dinner",
  "late-night comfort food",
  "patio evening",
  "celebration dinner"
];

type OnboardingDraftState = {
  form: OnboardingFormState;
  currentStepIndex: number;
  savedAt: string;
  sourcePath: string;
};

const ONBOARDING_DRAFT_STORAGE_PREFIX = "savr:onboarding-draft:v1";

function getDraftStorageKey(userId: number | undefined, pathname: string) {
  const scope = pathname === "/onboarding" ? "onboarding" : "profile-preferences";
  return `${ONBOARDING_DRAFT_STORAGE_PREFIX}:${userId ?? "unknown"}:${scope}`;
}

function comparableFormSnapshot(form: OnboardingFormState): string {
  return JSON.stringify(cloneFormState(form));
}

function readOnboardingDraft(key: string): OnboardingDraftState | null {
  if (typeof window === "undefined") return null;

  try {
    const raw = window.sessionStorage.getItem(key);
    if (!raw) return null;

    const parsed = JSON.parse(raw) as Partial<OnboardingDraftState>;
    if (!parsed || typeof parsed !== "object" || !parsed.form) return null;

    return {
      form: cloneFormState({
        ...emptyForm,
        ...(parsed.form as OnboardingFormState)
      }),
      currentStepIndex:
        typeof parsed.currentStepIndex === "number" && Number.isFinite(parsed.currentStepIndex)
          ? Math.max(0, parsed.currentStepIndex)
          : 0,
      savedAt: typeof parsed.savedAt === "string" ? parsed.savedAt : "",
      sourcePath: typeof parsed.sourcePath === "string" ? parsed.sourcePath : ""
    };
  } catch {
    return null;
  }
}

function writeOnboardingDraft(key: string, draft: OnboardingDraftState) {
  if (typeof window === "undefined") return;
  window.sessionStorage.setItem(
    key,
    JSON.stringify({
      form: cloneFormState(draft.form),
      currentStepIndex: draft.currentStepIndex,
      savedAt: draft.savedAt,
      sourcePath: draft.sourcePath
    })
  );
}

function clearOnboardingDraft(key: string) {
  if (typeof window === "undefined") return;
  window.sessionStorage.removeItem(key);
}

function formatDraftTimestamp(value: string | null): string {
  if (!value) return "this browser session";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "this browser session";
  return date.toLocaleString();
}

function formatLabel(value: string) {
  return value
    .split(/[-_]/g)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function formatCountLabel(step: WizardStep): string {
  if (step.select_mode === "single") return "Choose one";
  if (step.select_mode === "multi") return "Choose one or more";
  if (step.select_mode === "range") return "Optional numeric range";
  return step.optional ? "Optional" : "Required";
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
    price_sensitivity: source?.price_sensitivity ?? "",
    budget_min_per_person:
      typeof (source as OnboardingState & { budget_min_per_person?: number | null })?.budget_min_per_person === "number"
        ? String((source as OnboardingState & { budget_min_per_person?: number | null }).budget_min_per_person)
        : "",
    budget_max_per_person:
      typeof (source as OnboardingState & { budget_max_per_person?: number | null })?.budget_max_per_person === "number"
        ? String((source as OnboardingState & { budget_max_per_person?: number | null }).budget_max_per_person)
        : "",
    onboarding_version:
      (source as OnboardingState & { onboarding_version?: string | null })?.onboarding_version || ""
  };
}

function cloneFormState(source: OnboardingFormState): OnboardingFormState {
  return {
    ...source,
    dietary_restrictions: [...source.dietary_restrictions],
    cuisine_preferences: [...source.cuisine_preferences],
    texture_preferences: [...source.texture_preferences],
    dining_pace_preferences: [...source.dining_pace_preferences],
    social_preferences: [...source.social_preferences],
    drink_preferences: [...source.drink_preferences],
    atmosphere_preferences: [...source.atmosphere_preferences],
    favorite_dining_experiences: [...source.favorite_dining_experiences],
    favorite_restaurants: [...source.favorite_restaurants]
  };
}

function parseNumberOrNull(value: string): number | null {
  if (!value.trim()) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function buildSummaryText(step: WizardStep, form: OnboardingFormState): string {
  switch (step.key) {
    case "budget_range": {
      const min = form.budget_min_per_person.trim();
      const max = form.budget_max_per_person.trim();
      if (!min && !max) return "No numeric budget set yet.";
      if (min && max) return `$${min} - $${max} per person`;
      if (min) return `From $${min} per person`;
      return `Up to $${max} per person`;
    }
    case "price_sensitivity":
      return form.price_sensitivity ? formatLabel(form.price_sensitivity) : "Nothing selected yet.";
    case "bio":
      return form.bio.trim() ? "Dining note added." : "No note added yet.";
    case "favorite_dining_experiences":
      return form.favorite_dining_experiences.length > 0
        ? `${form.favorite_dining_experiences.length} experience preferences selected.`
        : "No favorite experience styles selected yet.";
    case "favorite_restaurants":
      return form.favorite_restaurants.length > 0
        ? `${form.favorite_restaurants.length} favorite restaurants selected.`
        : "No favorite restaurants selected yet.";
    default: {
      const values = form[step.key as keyof OnboardingFormState];
      if (Array.isArray(values)) {
        return values.length > 0 ? `${values.length} selected.` : "Nothing selected yet.";
      }
      return "Nothing selected yet.";
    }
  }
}

function StepChoiceCard({
  active,
  label,
  description,
  onClick
}: {
  active: boolean;
  label: string;
  description?: string | null;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      className={active ? "wizard-choice-card wizard-choice-card--active" : "wizard-choice-card"}
      onClick={onClick}
      aria-pressed={active}
    >
      <span className="wizard-choice-card__label">{label}</span>
      {description ? <span className="wizard-choice-card__description">{description}</span> : null}
      <span className="wizard-choice-card__state">{active ? "Selected" : "Tap to select"}</span>
    </button>
  );
}

function ReviewGroup({
  title,
  values,
  emptyText
}: {
  title: string;
  values: string[];
  emptyText: string;
}) {
  return (
    <div className="wizard-review-group">
      <strong>{title}</strong>
      {values.length === 0 ? (
        <p className="muted" style={{ marginBottom: 0 }}>{emptyText}</p>
      ) : (
        <div className="wizard-review-chip-row">
          {values.map((value) => (
            <span key={value} className="wizard-review-chip">
              {formatLabel(value)}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

export default function OnboardingPage() {
  const { refreshUser, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [form, setForm] = useState<OnboardingFormState>(emptyForm);
  const [savedState, setSavedState] = useState<OnboardingFormState>(emptyForm);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [isHydrating, setIsHydrating] = useState(true);
  const [optionsResponse, setOptionsResponse] = useState<OnboardingOptionsResponse>(fallbackOnboardingOptions);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [restoredDraftAt, setRestoredDraftAt] = useState<string | null>(null);

  const draftStorageKey = useMemo(
    () => getDraftStorageKey(user?.id, location.pathname),
    [user?.id, location.pathname]
  );

  useEffect(() => {
    let cancelled = false;

    async function hydrate() {
      try {
        setError("");

        const [restaurants, onboardingState, onboardingOptions] = await Promise.all([
          apiRequest<RestaurantListItem[]>("/restaurants"),
          apiRequest<OnboardingState>("/onboarding"),
          apiRequest<OnboardingOptionsResponse>("/onboarding/options")
        ]);

        if (cancelled) return;

        const restaurantNames = restaurants.map((restaurant) => restaurant.name);
        const nextForm = toFormState(onboardingState);
        const draft = readOnboardingDraft(draftStorageKey);

        const shouldRestoreDraft =
          !!draft && comparableFormSnapshot(draft.form) !== comparableFormSnapshot(nextForm);

        setRestaurantOptions(restaurantNames);
        setSavedState(cloneFormState(nextForm));
        setForm(shouldRestoreDraft && draft ? cloneFormState(draft.form) : nextForm);
        setOptionsResponse(onboardingOptions);
        setCurrentStepIndex(shouldRestoreDraft && draft ? draft.currentStepIndex : 0);
        setRestoredDraftAt(shouldRestoreDraft && draft ? draft.savedAt : null);

        if (shouldRestoreDraft) {
          setMessage("We restored your unsaved onboarding draft from this browser session.");
        }
      } catch (err) {
        if (!cancelled) {
          setRestaurantOptions([]);
          setOptionsResponse(fallbackOnboardingOptions);
          setError(
            err instanceof Error
              ? err.message
              : "We could not load your saved profile right now."
          );
        }
      } finally {
        if (!cancelled) setIsHydrating(false);
      }
    }

    void hydrate();
    return () => {
      cancelled = true;
    };
  }, [draftStorageKey]);

  const wizardSteps = useMemo<WizardStep[]>(() => {
    const backendSteps = [...optionsResponse.fields].sort((a, b) => a.step_order - b.step_order);

    const customSteps: CustomStepDefinition[] = [
      {
        key: "favorite_dining_experiences",
        label: "Favorite experience types",
        description: "Choose the dining moments you want SAVR to remember and prioritize.",
        help_text: "Choose one or more.",
        select_mode: "multi",
        optional: true,
        allow_skip: true,
        step_order: 90
      },
      {
        key: "favorite_restaurants",
        label: "Favorite restaurants",
        description: "Mark the places you already know you like.",
        help_text: "Optional. This helps SAVR learn your existing taste baseline.",
        select_mode: "multi",
        optional: true,
        allow_skip: true,
        step_order: 91
      },
      {
        key: "bio",
        label: "A short note about your ideal dining style",
        description: "Add a short note so SAVR understands your preferences in plain language too.",
        help_text: "Optional. Keep it short and practical.",
        select_mode: "text",
        optional: true,
        allow_skip: true,
        step_order: 92
      }
    ];

    return [...backendSteps, ...customSteps];
  }, [optionsResponse]);

  const totalScreens = wizardSteps.length + 1;
  const currentStep = wizardSteps[currentStepIndex];
  const isReviewStep = currentStepIndex >= wizardSteps.length;
  const progressPercent = Math.max(8, Math.round(((currentStepIndex + 1) / totalScreens) * 100));

  const budgetError = useMemo(() => {
    const min = form.budget_min_per_person.trim();
    const max = form.budget_max_per_person.trim();

    if (!min && !max) return "";
    if (min && Number(min) < 0) return "Minimum budget cannot be negative.";
    if (max && Number(max) < 0) return "Maximum budget cannot be negative.";

    const parsedMin = min ? Number(min) : null;
    const parsedMax = max ? Number(max) : null;

    if (min && !Number.isFinite(parsedMin)) return "Minimum budget must be a valid number.";
    if (max && !Number.isFinite(parsedMax)) return "Maximum budget must be a valid number.";

    if (parsedMin !== null && parsedMax !== null && parsedMin > parsedMax) {
      return "Minimum budget cannot be greater than maximum budget.";
    }

    return "";
  }, [form.budget_min_per_person, form.budget_max_per_person]);

  const hasUnsavedChanges = useMemo(
    () => comparableFormSnapshot(form) !== comparableFormSnapshot(savedState),
    [form, savedState]
  );

  const completionStats = useMemo(
    () => [
      { label: "Cuisine", value: form.cuisine_preferences.length },
      { label: "Atmosphere", value: form.atmosphere_preferences.length },
      { label: "Drinks", value: form.drink_preferences.length },
      { label: "Favorites", value: form.favorite_restaurants.length }
    ],
    [form]
  );

  useEffect(() => {
    setCurrentStepIndex((current) => Math.min(current, wizardSteps.length));
  }, [wizardSteps.length]);

  useEffect(() => {
    if (isHydrating) return;

    if (hasUnsavedChanges) {
      writeOnboardingDraft(draftStorageKey, {
        form: cloneFormState(form),
        currentStepIndex,
        savedAt: new Date().toISOString(),
        sourcePath: location.pathname
      });
      return;
    }

    clearOnboardingDraft(draftStorageKey);
  }, [draftStorageKey, form, currentStepIndex, hasUnsavedChanges, isHydrating, location.pathname]);

  useEffect(() => {
    if (!hasUnsavedChanges) return;

    const handleBeforeUnload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = "";
    };

    window.addEventListener("beforeunload", handleBeforeUnload);
    return () => window.removeEventListener("beforeunload", handleBeforeUnload);
  }, [hasUnsavedChanges]);

  function toggleArrayField(field: ChoiceFieldKey, value: string) {
    setForm((current) => {
      const existing = current[field];
      const next = existing.includes(value)
        ? existing.filter((item) => item !== value)
        : [...existing, value];

      return { ...current, [field]: next };
    });
  }

  function setSingleField(field: "price_sensitivity", value: string) {
    setForm((current) => ({
      ...current,
      [field]: current[field] === value ? "" : value
    }));
  }

  function resetToSavedState() {
    const restored = cloneFormState(savedState);
    setForm(restored);
    setCurrentStepIndex(0);
    setRestoredDraftAt(null);
    clearOnboardingDraft(draftStorageKey);
    setMessage("Your onboarding form has been reset to the last saved version.");
    setError("");
  }

  function goNext() {
    setCurrentStepIndex((current) => Math.min(current + 1, wizardSteps.length));
  }

  function goBack() {
    setCurrentStepIndex((current) => Math.max(current - 1, 0));
  }

  async function handleSubmit() {
    setError("");
    setMessage("");
    setIsSubmitting(true);

    const payload = {
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
      price_sensitivity: form.price_sensitivity || null,
      budget_min_per_person: parseNumberOrNull(form.budget_min_per_person),
      budget_max_per_person: parseNumberOrNull(form.budget_max_per_person),
      onboarding_version: optionsResponse.version || "guided-v1"
    } as OnboardingPayload & {
      budget_min_per_person?: number | null;
      budget_max_per_person?: number | null;
      onboarding_version?: string | null;
    };

    try {
      const response = await apiRequest<OnboardingResponse>("/onboarding", {
        method: "POST",
        body: payload
      });

      const persisted = await apiRequest<OnboardingState>("/onboarding");
      const persistedForm = toFormState(persisted);

      setSavedState(cloneFormState(persistedForm));
      setForm(persistedForm);
      setRestoredDraftAt(null);
      clearOnboardingDraft(draftStorageKey);

      await refreshUser();

      const nextMessage = response.message || "Your SAVR profile has been updated.";
      setMessage(nextMessage);

      const redirectTarget =
        location.pathname === "/onboarding" ? "/dashboard" : "/profile";

      window.setTimeout(() => {
        navigate(redirectTarget);
      }, 650);
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
        <h1 className="page-title">Build your taste profile step by step</h1>
        <p className="muted" style={{ maxWidth: "820px", marginBottom: 0 }}>
          One clear decision at a time. You can go back, skip optional steps, and
          nothing you choose here is lost as you move through the flow.
        </p>
      </section>

      <div className="sr-only" aria-live="polite">
        {error || message || (hasUnsavedChanges ? "You have unsaved onboarding changes." : "")}
      </div>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      {restoredDraftAt ? (
        <div className="onboarding-draft-banner" role="status">
          <div>
            <strong>Unsaved draft restored</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              We restored local onboarding changes from {formatDraftTimestamp(restoredDraftAt)}.
              Review them and save when ready, or discard them to return to your last saved profile.
            </p>
          </div>

          <div className="button-row">
            <Button type="button" variant="ghost" onClick={resetToSavedState}>
              Discard local draft
            </Button>
          </div>
        </div>
      ) : null}

      <section className="grid grid-2 onboarding-grid">
        <Card
          title={isReviewStep ? "Review your SAVR profile" : currentStep.label}
          subtitle={
            isReviewStep
              ? "Check the signals SAVR will use, then save when everything looks right."
              : currentStep.description
          }
          actions={
            <Badge tone="accent">
              Step {Math.min(currentStepIndex + 1, totalScreens)} / {totalScreens}
            </Badge>
          }
        >
          <div className="wizard-progress-shell" aria-label="Onboarding progress">
            <div className="wizard-progress-meta">
              <span>{isReviewStep ? "Review and save" : "Guided onboarding"}</span>
              <strong>{progressPercent}%</strong>
            </div>
            <div className="wizard-progress-track" aria-hidden="true">
              <div className="wizard-progress-fill" style={{ width: `${progressPercent}%` }} />
            </div>
            {hasUnsavedChanges ? (
              <p className="wizard-draft-note">Draft saved locally in this browser session.</p>
            ) : null}
          </div>

          {!isReviewStep ? (
            <div className="wizard-step-hero wizard-step-hero--animated">
              <div className="wizard-step-badges">
                <span className="wizard-step-badge">{formatCountLabel(currentStep)}</span>
                {currentStep.optional ? (
                  <span className="wizard-step-badge wizard-step-badge--soft">Optional</span>
                ) : null}
              </div>

              {currentStep.help_text ? (
                <p className="muted wizard-step-help">{currentStep.help_text}</p>
              ) : null}

              {currentStep.key === "price_sensitivity" ? (
                <div className="wizard-choice-grid">
                  {currentStep.options.map((option) => (
                    <StepChoiceCard
                      key={option.value}
                      active={form.price_sensitivity === option.value}
                      label={option.label}
                      description={option.description}
                      onClick={() => setSingleField("price_sensitivity", option.value)}
                    />
                  ))}
                </div>
              ) : null}

              {currentStep.key === "budget_range" ? (
                <div className="wizard-range-grid">
                  <div className="form-row">
                    <label htmlFor="budget_min_per_person">Minimum per person</label>
                    <input
                      id="budget_min_per_person"
                      type="number"
                      min="0"
                      step="1"
                      inputMode="numeric"
                      value={form.budget_min_per_person}
                      placeholder="e.g. 15"
                      onChange={(e) =>
                        setForm((current) => ({
                          ...current,
                          budget_min_per_person: e.target.value
                        }))
                      }
                    />
                    <small className="muted">Leave blank if you do not want to set a minimum.</small>
                  </div>

                  <div className="form-row">
                    <label htmlFor="budget_max_per_person">Maximum per person</label>
                    <input
                      id="budget_max_per_person"
                      type="number"
                      min="0"
                      step="1"
                      inputMode="numeric"
                      value={form.budget_max_per_person}
                      placeholder="e.g. 40"
                      onChange={(e) =>
                        setForm((current) => ({
                          ...current,
                          budget_max_per_person: e.target.value
                        }))
                      }
                    />
                    <small className="muted">Use real dollar values instead of icons only.</small>
                  </div>
                  {budgetError ? (
                    <p className="wizard-inline-error" role="alert">
                      {budgetError}
                    </p>
                  ) : null}
                </div>
              ) : null}

              {currentStep.key === "favorite_dining_experiences" ? (
                <div className="wizard-choice-grid">
                  {favoriteExperienceOptions.map((option) => (
                    <StepChoiceCard
                      key={option}
                      active={form.favorite_dining_experiences.includes(option)}
                      label={formatLabel(option)}
                      onClick={() => toggleArrayField("favorite_dining_experiences", option)}
                    />
                  ))}
                </div>
              ) : null}

              {currentStep.key === "favorite_restaurants" ? (
                <div className="wizard-choice-grid">
                  {restaurantOptions.length > 0 ? (
                    restaurantOptions.map((option) => (
                      <StepChoiceCard
                        key={option}
                        active={form.favorite_restaurants.includes(option)}
                        label={option}
                        onClick={() => toggleArrayField("favorite_restaurants", option)}
                      />
                    ))
                  ) : (
                    <div className="item">
                      <strong>No restaurants available yet</strong>
                      <p className="muted" style={{ marginBottom: 0 }}>
                        You can skip this step and still finish onboarding.
                      </p>
                    </div>
                  )}
                </div>
              ) : null}

              {currentStep.key === "bio" ? (
                <div className="form-row">
                  <label htmlFor="bio">Dining note</label>
                  <textarea
                    id="bio"
                    rows={5}
                    value={form.bio}
                    placeholder="Example: I usually want cozy places with a strong main dish, easy conversation, and a price that still feels reasonable for students."
                    onChange={(e) =>
                      setForm((current) => ({
                        ...current,
                        bio: e.target.value
                      }))
                    }
                  />
                  <small className="muted">
                    This is optional, but it helps SAVR understand your preferences in normal language.
                  </small>
                </div>
              ) : null}

              {[
                "dietary_restrictions",
                "cuisine_preferences",
                "texture_preferences",
                "dining_pace_preferences",
                "social_preferences",
                "drink_preferences",
                "atmosphere_preferences"
              ].includes(currentStep.key) ? (
                <div className="wizard-choice-grid">
                  {(currentStep as OnboardingFieldDefinition).options.map((option) => {
                    const values = form[currentStep.key as ChoiceFieldKey];
                    const active = values.includes(option.value);
                    return (
                      <StepChoiceCard
                        key={option.value}
                        active={active}
                        label={option.label}
                        description={option.description}
                        onClick={() => toggleArrayField(currentStep.key as ChoiceFieldKey, option.value)}
                      />
                    );
                  })}
                </div>
              ) : null}

              <div className="wizard-inline-summary">
                <strong>Current step summary</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {buildSummaryText(currentStep, form)}
                </p>
              </div>
            </div>
          ) : (
            <div className="wizard-step-hero wizard-step-hero--animated">
              <div className="wizard-review-grid">
                <ReviewGroup title="Cuisine preferences" values={form.cuisine_preferences} emptyText="No cuisine preferences saved." />
                <ReviewGroup title="Atmosphere preferences" values={form.atmosphere_preferences} emptyText="No atmosphere preferences saved." />
                <ReviewGroup title="Dining pace" values={form.dining_pace_preferences} emptyText="No pace preferences saved." />
                <ReviewGroup title="Social preferences" values={form.social_preferences} emptyText="No social preferences saved." />
                <ReviewGroup title="Drink preferences" values={form.drink_preferences} emptyText="No drink preferences saved." />
                <ReviewGroup title="Dietary restrictions" values={form.dietary_restrictions} emptyText="No dietary restrictions saved." />
                <ReviewGroup title="Favorite experience types" values={form.favorite_dining_experiences} emptyText="No favorite experience types saved." />
                <ReviewGroup title="Favorite restaurants" values={form.favorite_restaurants} emptyText="No favorite restaurants saved." />

                <div className="wizard-review-group">
                  <strong>Budget comfort</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {form.price_sensitivity ? formatLabel(form.price_sensitivity) : "No budget comfort selected."}
                  </p>
                </div>

                <div className="wizard-review-group">
                  <strong>Numeric budget range</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {buildSummaryText(
                      {
                        key: "budget_range",
                        label: "",
                        description: "",
                        help_text: "",
                        select_mode: "range",
                        optional: true,
                        allow_skip: true,
                        ui_control: "range",
                        step_order: 999,
                        options: []
                      },
                      form
                    )}
                  </p>
                </div>

                <div className="wizard-review-group wizard-review-group--full">
                  <strong>Dining note</strong>
                  <p className="muted" style={{ marginBottom: 0 }}>
                    {form.bio.trim() || "No note added."}
                  </p>
                </div>
              </div>
            </div>
          )}

          <div className="wizard-actions">
            <Button type="button" variant="ghost" onClick={goBack} disabled={currentStepIndex === 0 || isSubmitting}>
              Back
            </Button>

            <div className="wizard-actions__right">
              {!isReviewStep && currentStep.optional ? (
                <Button
                  type="button"
                  variant="secondary"
                  onClick={goNext}
                  disabled={isSubmitting || (currentStep.key === "budget_range" && Boolean(budgetError))}
                >
                  Skip for now
                </Button>
              ) : null}

              {!isReviewStep ? (
                <Button
                  type="button"
                  onClick={goNext}
                  disabled={isSubmitting || (currentStep.key === "budget_range" && Boolean(budgetError))}
                >
                  {currentStepIndex === wizardSteps.length - 1 ? "Review profile" : "Continue"}
                </Button>
              ) : (
                <Button type="button" onClick={handleSubmit} disabled={isSubmitting || Boolean(budgetError)}>
                  {isSubmitting ? "Saving..." : "Save profile"}
                </Button>
              )}
            </div>
          </div>
        </Card>

        <div className="grid" style={{ gap: "1rem" }}>
          <Card
            title="Profile completeness"
            subtitle="A quick view of how much preference detail you have added"
            actions={<Badge tone="success">Summary</Badge>}
          >
            <div className="grid grid-2">
              {completionStats.map((stat) => (
                <div key={stat.label} className="item">
                  <p className="muted" style={{ marginBottom: "0.25rem" }}>{stat.label}</p>
                  <strong style={{ fontSize: "1.15rem" }}>{stat.value}</strong>
                </div>
              ))}
            </div>
          </Card>

          <Card
            title="How this onboarding works"
            subtitle="Clearer, lower-friction, and easier to understand"
            actions={<Badge>Guide</Badge>}
          >
            <div className="list">
              <div className="item">
                <strong>One major decision per screen</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Each step focuses on one topic so the flow feels lighter and easier to process.
                </p>
              </div>
              <div className="item">
                <strong>Clear selection rules</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Every step tells you whether it is optional and whether you can choose one or many options.
                </p>
              </div>
              <div className="item">
                <strong>Automatic redirect after save</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  New users return to the dashboard after onboarding, while profile edits return to the profile page.
                </p>
              </div>
              <div className="item">
                <strong>Session-safe local draft</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Unsaved changes are kept in this browser session so a refresh does not force you to restart the profile flow.
                </p>
              </div>
            </div>
          </Card>

          <Card
            title="Quick actions"
            subtitle="Useful while testing the onboarding flow"
            actions={<Badge tone="accent">Tools</Badge>}
          >
            <div className="button-row">
              <Button type="button" variant="secondary" onClick={resetToSavedState}>
                Reset to saved
              </Button>
              <Button type="button" variant="ghost" onClick={() => setCurrentStepIndex(wizardSteps.length)}>
                Jump to review
              </Button>
            </div>
          </Card>
        </div>
      </section>
    </div>
  );
}
