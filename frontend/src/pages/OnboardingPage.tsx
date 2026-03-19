import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

import Button from "../components/ui/Button";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import {
  OnboardingFieldDefinition,
  OnboardingOptionsResponse,
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
  ui_control: "chips" | "textarea";
  step_order: number;
  options: { value: string; label: string; description?: string | null }[];
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

const fallbackOnboardingOptions: OnboardingOptionsResponse = {
  version: "single-flow-v1",
  fields: [
    {
      key: "cuisine_preferences",
      label: "Cuisine preferences",
      description: "Choose the food styles you want SAVR to prioritize first.",
      help_text: "Choose one or more options.",
      select_mode: "multi",
      optional: false,
      allow_skip: false,
      ui_control: "chips",
      step_order: 1,
      options: [
        { value: "italian", label: "Italian" },
        { value: "mexican", label: "Mexican" },
        { value: "japanese", label: "Japanese" },
        { value: "canadian", label: "Canadian" },
        { value: "seafood", label: "Seafood" },
        { value: "cafe", label: "Cafe / Bakery" },
        { value: "pub fare", label: "Pub fare" },
        { value: "fast food", label: "Fast food" }
      ]
    },
    {
      key: "atmosphere_preferences",
      label: "Atmosphere preferences",
      description: "Pick the kinds of spaces and vibes you naturally enjoy.",
      help_text: "Choose one or more options.",
      select_mode: "multi",
      optional: true,
      allow_skip: true,
      ui_control: "chips",
      step_order: 2,
      options: [
        { value: "cozy", label: "Cozy" },
        { value: "casual", label: "Casual" },
        { value: "upscale", label: "Upscale" },
        { value: "family friendly", label: "Family friendly" },
        { value: "live music", label: "Live music" },
        { value: "trivia", label: "Trivia night" }
      ]
    },
    {
      key: "dining_pace_preferences",
      label: "Dining pace",
      description: "Choose whether you usually want a quick stop, balanced meal, or slower experience.",
      help_text: "Choose one or more options.",
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
      description: "This helps rank better for solo meals, dates, families, and groups.",
      help_text: "Choose one or more options.",
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
      help_text: "Choose one or more options.",
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
      description: "Choose restrictions only if they should actively affect recommendations.",
      help_text: "Optional. Choose one or more if needed.",
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
      help_text: "Choose one option.",
      select_mode: "single",
      optional: true,
      allow_skip: true,
      ui_control: "radio",
      step_order: 7,
      options: [
        { value: "budget", label: "Budget-conscious" },
        { value: "balanced", label: "Balanced" },
        { value: "premium", label: "Premium" }
      ]
    },
    {
      key: "budget_range",
      label: "Numeric budget range",
      description: "Set a typical spend per person if you want more precision.",
      help_text: "Optional numeric range.",
      select_mode: "range",
      optional: true,
      allow_skip: true,
      ui_control: "range",
      step_order: 8,
      options: []
    }
  ]
};

type OnboardingDraftState = {
  form: OnboardingFormState;
  currentStepIndex: number;
  savedAt: string;
};

function getDraftStorageKey(userId: number | undefined, pathname: string) {
  const scope = pathname === "/onboarding" ? "onboarding" : "profile-preferences";
  return `savr:onboarding-single-flow:v1:${userId ?? "unknown"}:${scope}`;
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

function comparableFormSnapshot(form: OnboardingFormState): string {
  return JSON.stringify(cloneFormState(form));
}

function readDraft(key: string): OnboardingDraftState | null {
  if (typeof window === "undefined") return null;

  try {
    const raw = window.sessionStorage.getItem(key);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as OnboardingDraftState;
    if (!parsed?.form) return null;

    return {
      form: cloneFormState({
        ...emptyForm,
        ...parsed.form
      }),
      currentStepIndex:
        typeof parsed.currentStepIndex === "number" && Number.isFinite(parsed.currentStepIndex)
          ? Math.max(0, parsed.currentStepIndex)
          : 0,
      savedAt: typeof parsed.savedAt === "string" ? parsed.savedAt : ""
    };
  } catch {
    return null;
  }
}

function writeDraft(key: string, draft: OnboardingDraftState) {
  if (typeof window === "undefined") return;
  window.sessionStorage.setItem(key, JSON.stringify(draft));
}

function clearDraft(key: string) {
  if (typeof window === "undefined") return;
  window.sessionStorage.removeItem(key);
}

function parseNumberOrNull(value: string): number | null {
  if (!value.trim()) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
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
      typeof source?.budget_min_per_person === "number" ? String(source.budget_min_per_person) : "",
    budget_max_per_person:
      typeof source?.budget_max_per_person === "number" ? String(source.budget_max_per_person) : "",
    onboarding_version: source?.onboarding_version ?? ""
  };
}

function isChoiceFieldKey(value: string): value is ChoiceFieldKey {
  return [
    "dietary_restrictions",
    "cuisine_preferences",
    "texture_preferences",
    "dining_pace_preferences",
    "social_preferences",
    "drink_preferences",
    "atmosphere_preferences",
    "favorite_dining_experiences",
    "favorite_restaurants"
  ].includes(value);
}

function formatCountLabel(step: WizardStep): string {
  if (step.select_mode === "single") return "Choose one";
  if (step.select_mode === "multi") return "Choose one or more";
  if (step.select_mode === "range") return "Optional numeric range";
  if (step.select_mode === "text") return "Write your answer";
  return step.optional ? "Optional" : "Required";
}

function formatDraftTimestamp(value: string | null) {
  if (!value) return "this browser session";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "this browser session";
  return date.toLocaleString();
}

function getStepSelections(step: WizardStep, form: OnboardingFormState): string[] {
  if (isChoiceFieldKey(step.key)) {
    return form[step.key];
  }

  if (step.key === "price_sensitivity") {
    return form.price_sensitivity ? [form.price_sensitivity] : [];
  }

  return [];
}

export default function OnboardingPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { refreshUser, user } = useAuth();

  const [form, setForm] = useState<OnboardingFormState>(emptyForm);
  const [savedState, setSavedState] = useState<OnboardingFormState>(emptyForm);
  const [optionsResponse, setOptionsResponse] = useState<OnboardingOptionsResponse>(fallbackOnboardingOptions);
  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [isHydrating, setIsHydrating] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [restoredDraftAt, setRestoredDraftAt] = useState<string | null>(null);

  const draftStorageKey = useMemo(
    () => getDraftStorageKey(user?.id, location.pathname),
    [user?.id, location.pathname]
  );

  const customSteps = useMemo<CustomStepDefinition[]>(
    () => [
      {
        key: "favorite_dining_experiences",
        label: "Favorite dining experiences",
        description: "Pick the outing types that sound most like the experiences you want more of.",
        help_text: "Choose one or more options.",
        select_mode: "multi",
        optional: true,
        allow_skip: true,
        ui_control: "chips",
        step_order: 90,
        options: favoriteExperienceOptions.map((value) => ({
          value,
          label: value
        }))
      },
      {
        key: "favorite_restaurants",
        label: "Favorite restaurants",
        description: "Pick the places you already love so SAVR can learn from them.",
        help_text: "Choose one or more options.",
        select_mode: "multi",
        optional: true,
        allow_skip: true,
        ui_control: "chips",
        step_order: 91,
        options: restaurantOptions.map((value) => ({
          value,
          label: value
        }))
      },
      {
        key: "bio",
        label: "Tell SAVR about your dining style",
        description: "Describe the kind of places, moods, and experiences that make a night feel right for you.",
        help_text: "A short paragraph is enough.",
        select_mode: "text",
        optional: true,
        allow_skip: true,
        ui_control: "textarea",
        step_order: 92,
        options: []
      }
    ],
    [restaurantOptions]
  );

  const wizardSteps = useMemo<WizardStep[]>(
    () =>
      [...optionsResponse.fields, ...customSteps].sort((a, b) => a.step_order - b.step_order),
    [optionsResponse.fields, customSteps]
  );

  const totalScreens = wizardSteps.length + 1;
  const isFinishScreen = currentStepIndex >= wizardSteps.length;
  const currentStep = wizardSteps[Math.min(currentStepIndex, Math.max(0, wizardSteps.length - 1))];
  const progressPercent = Math.max(6, Math.round(((currentStepIndex + 1) / totalScreens) * 100));

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

  const currentStepValidationError = useMemo(() => {
    if (isFinishScreen) return "";
    if (!currentStep) return "";
    if (currentStep.key === "budget_range") return budgetError;

    if (currentStep.select_mode === "text") {
      if (!currentStep.optional && !form.bio.trim()) {
        return "Please write a short answer before continuing.";
      }
      return "";
    }

    const selectedValues = getStepSelections(currentStep, form);

    if (!currentStep.optional && selectedValues.length === 0) {
      return currentStep.select_mode === "single"
        ? "Please choose one option before continuing."
        : "Please choose at least one option before continuing.";
    }

    return "";
  }, [budgetError, currentStep, form, isFinishScreen]);

  useEffect(() => {
    let cancelled = false;

    async function hydrate() {
      try {
        setError("");

        const [options, state, restaurants] = await Promise.all([
          apiRequest<OnboardingOptionsResponse>("/onboarding/options").catch(() => fallbackOnboardingOptions),
          apiRequest<OnboardingState>("/onboarding"),
          apiRequest<RestaurantListItem[]>("/restaurants").catch(() => [])
        ]);

        if (cancelled) return;

        const nextSaved = toFormState(state);
        const draft = readDraft(draftStorageKey);
        const shouldRestoreDraft =
          !!draft && comparableFormSnapshot(draft.form) !== comparableFormSnapshot(nextSaved);

        setOptionsResponse(options);
        setRestaurantOptions((restaurants || []).map((item) => item.name));
        setSavedState(cloneFormState(nextSaved));
        setForm(shouldRestoreDraft && draft ? cloneFormState(draft.form) : cloneFormState(nextSaved));
        setCurrentStepIndex(
          shouldRestoreDraft && draft ? Math.min(draft.currentStepIndex, wizardSteps.length) : 0
        );
        setRestoredDraftAt(shouldRestoreDraft && draft ? draft.savedAt : null);

        if (shouldRestoreDraft) {
          setMessage("We restored your unsaved onboarding draft from this browser session.");
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load onboarding.");
        }
      } finally {
        if (!cancelled) {
          setIsHydrating(false);
        }
      }
    }

    void hydrate();

    return () => {
      cancelled = true;
    };
  }, [draftStorageKey]);

  useEffect(() => {
    if (isHydrating) return;

    if (hasUnsavedChanges) {
      writeDraft(draftStorageKey, {
        form: cloneFormState(form),
        currentStepIndex,
        savedAt: new Date().toISOString()
      });
      return;
    }

    clearDraft(draftStorageKey);
  }, [draftStorageKey, form, currentStepIndex, hasUnsavedChanges, isHydrating]);

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
      const values = current[field];
      const nextValues = values.includes(value)
        ? values.filter((item) => item !== value)
        : [...values, value];

      return {
        ...current,
        [field]: nextValues
      };
    });
  }

  function setSingleField(field: "price_sensitivity", value: string) {
    setForm((current) => ({
      ...current,
      [field]: current[field] === value ? "" : value
    }));
  }

  function goNext() {
    if (currentStepValidationError) {
      setError(currentStepValidationError);
      return;
    }

    setError("");
    setCurrentStepIndex((current) => Math.min(current + 1, totalScreens - 1));
  }

  function goBack() {
    setError("");
    setCurrentStepIndex((current) => Math.max(current - 1, 0));
  }

  function resetToSavedState() {
    setForm(cloneFormState(savedState));
    setCurrentStepIndex(0);
    setRestoredDraftAt(null);
    clearDraft(draftStorageKey);
    setMessage("Your profile flow has been reset to the last saved version.");
    setError("");
  }

  async function handleSubmit() {
    if (budgetError) {
      setError(budgetError);
      return;
    }

    setIsSubmitting(true);
    setError("");
    setMessage("");

    try {
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
        spice_tolerance: form.spice_tolerance.trim() || null,
        price_sensitivity: form.price_sensitivity.trim() || null,
        budget_min_per_person: parseNumberOrNull(form.budget_min_per_person),
        budget_max_per_person: parseNumberOrNull(form.budget_max_per_person),
        onboarding_version: optionsResponse.version || form.onboarding_version || null
      };

      const response = await apiRequest<OnboardingResponse>("/onboarding", {
        method: "POST",
        body: payload
      });

      const persistedForm = cloneFormState({
        ...form,
        onboarding_version: optionsResponse.version || form.onboarding_version
      });

      setSavedState(cloneFormState(persistedForm));
      setForm(persistedForm);
      setRestoredDraftAt(null);
      clearDraft(draftStorageKey);

      await refreshUser();

      setMessage(response.message || "Your profile has been updated.");

      navigate(location.pathname === "/profile/preferences" ? "/profile" : "/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save onboarding.");
    } finally {
      setIsSubmitting(false);
    }
  }

  const answeredSteps = wizardSteps.filter((step) => {
    if (step.key === "budget_range") {
      return Boolean(form.budget_min_per_person.trim() || form.budget_max_per_person.trim());
    }

    if (step.key === "bio") {
      return Boolean(form.bio.trim());
    }

    if (step.key === "price_sensitivity") {
      return Boolean(form.price_sensitivity);
    }

    const selections = getStepSelections(step, form);
    return selections.length > 0;
  }).length;

  return (
    <div className="single-onboarding-shell">
      <div className="single-onboarding-card">
        <div className="single-onboarding-header">
          <p className="single-onboarding-eyebrow">
            {location.pathname === "/profile/preferences" ? "Edit profile" : "Guided onboarding"}
          </p>
          <h1 className="single-onboarding-title">
            {location.pathname === "/profile/preferences"
              ? "Update your dining profile"
              : "Build your dining profile"}
          </h1>
          <p className="single-onboarding-subtitle">
            One step at a time. Answer each prompt clearly and move forward through the guided flow.
          </p>

          <div className="single-onboarding-progress-meta">
            <span>
              Step {Math.min(currentStepIndex + 1, totalScreens)} of {totalScreens}
            </span>
            <strong>{progressPercent}%</strong>
          </div>
          <div className="single-onboarding-progress-track" aria-hidden="true">
            <div className="single-onboarding-progress-fill" style={{ width: `${progressPercent}%` }} />
          </div>
          {hasUnsavedChanges ? (
            <p className="single-onboarding-draft-note">
              Draft saved locally in this browser session.
            </p>
          ) : null}
        </div>

        <div className="sr-only" aria-live="polite">
          {error || message || (hasUnsavedChanges ? "You have unsaved onboarding changes." : "")}
        </div>

        {error ? <div className="error">{error}</div> : null}
        {message ? <div className="success">{message}</div> : null}

        {restoredDraftAt ? (
          <div className="single-onboarding-banner" role="status">
            <div>
              <strong>Unsaved draft restored</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                We restored local changes from {formatDraftTimestamp(restoredDraftAt)}.
              </p>
            </div>

            <div className="button-row">
              <Button type="button" variant="ghost" onClick={resetToSavedState}>
                Discard local draft
              </Button>
            </div>
          </div>
        ) : null}

        {!isFinishScreen && currentStep ? (
          <section className="single-onboarding-stage">
            <div className="single-onboarding-stage-copy">
              <p className="single-onboarding-step-tag">{formatCountLabel(currentStep)}</p>
              <h2>{currentStep.label}</h2>
              <p>{currentStep.description}</p>
              {currentStep.help_text ? (
                <p className="muted" style={{ marginBottom: 0 }}>{currentStep.help_text}</p>
              ) : null}
            </div>

            {currentStep.key === "budget_range" ? (
              <div className="single-onboarding-range-grid">
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
                </div>

                {budgetError ? (
                  <p className="single-onboarding-inline-error" role="alert">
                    {budgetError}
                  </p>
                ) : null}
              </div>
            ) : currentStep.key === "bio" ? (
              <div className="form-row">
                <label htmlFor="bio">Your dining style</label>
                <textarea
                  id="bio"
                  rows={6}
                  value={form.bio}
                  placeholder="Example: I like cozy spots for coffee, lively places for group dinners, and occasionally something special for a date night."
                  onChange={(e) =>
                    setForm((current) => ({
                      ...current,
                      bio: e.target.value
                    }))
                  }
                />
              </div>
            ) : currentStep.select_mode === "single" ? (
              <div className="single-onboarding-choice-grid">
                {currentStep.options.map((option) => {
                  const selected = form.price_sensitivity === option.value;

                  return (
                    <button
                      key={option.value}
                      type="button"
                      className={
                        selected
                          ? "single-onboarding-choice single-onboarding-choice--active"
                          : "single-onboarding-choice"
                      }
                      onClick={() => setSingleField("price_sensitivity", option.value)}
                    >
                      <strong>{option.label}</strong>
                      {option.description ? <p>{option.description}</p> : null}
                    </button>
                  );
                })}
              </div>
            ) : (
              <div className="single-onboarding-choice-grid">
                {currentStep.options.map((option) => {
                  const selected = isChoiceFieldKey(currentStep.key)
                    ? form[currentStep.key].includes(option.value)
                    : false;

                  return (
                    <button
                      key={option.value}
                      type="button"
                      className={
                        selected
                          ? "single-onboarding-choice single-onboarding-choice--active"
                          : "single-onboarding-choice"
                      }
                      onClick={() => {
                        if (isChoiceFieldKey(currentStep.key)) {
                          toggleArrayField(currentStep.key, option.value);
                        }
                      }}
                    >
                      <strong>{option.label}</strong>
                      {option.description ? <p>{option.description}</p> : null}
                    </button>
                  );
                })}
              </div>
            )}
          </section>
        ) : (
          <section className="single-onboarding-stage">
            <div className="single-onboarding-stage-copy">
              <p className="single-onboarding-step-tag">Ready to finish</p>
              <h2>Save your profile</h2>
              <p>
                You have completed {answeredSteps} of {wizardSteps.length} profile steps.
                Save now to update your dining profile and return to the app.
              </p>
            </div>

            <div className="single-onboarding-summary-list">
              <div className="item">
                <strong>Cuisine preferences</strong>
                <p className="muted">{form.cuisine_preferences.length} selected</p>
              </div>
              <div className="item">
                <strong>Atmosphere preferences</strong>
                <p className="muted">{form.atmosphere_preferences.length} selected</p>
              </div>
              <div className="item">
                <strong>Drink preferences</strong>
                <p className="muted">{form.drink_preferences.length} selected</p>
              </div>
              <div className="item">
                <strong>Favorite restaurants</strong>
                <p className="muted">{form.favorite_restaurants.length} selected</p>
              </div>
            </div>
          </section>
        )}

        <div className="single-onboarding-actions">
          <Button
            type="button"
            variant="ghost"
            onClick={goBack}
            disabled={currentStepIndex === 0 || isSubmitting}
          >
            Back
          </Button>

          <div className="button-row">
            {!isFinishScreen && currentStep?.allow_skip ? (
              <Button
                type="button"
                variant="secondary"
                onClick={goNext}
                disabled={isSubmitting || Boolean(currentStepValidationError)}
              >
                Skip for now
              </Button>
            ) : null}

            {!isFinishScreen ? (
              <Button
                type="button"
                onClick={goNext}
                disabled={isSubmitting || Boolean(currentStepValidationError)}
              >
                Continue
              </Button>
            ) : (
              <Button
                type="button"
                onClick={handleSubmit}
                disabled={isSubmitting || Boolean(budgetError)}
              >
                {isSubmitting ? "Saving..." : "Save profile"}
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
