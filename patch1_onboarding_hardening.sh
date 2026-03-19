#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
ONBOARDING_FILE="$FRONTEND_DIR/src/pages/OnboardingPage.tsx"
STYLES_FILE="$FRONTEND_DIR/src/styles.css"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch1_onboarding_hardening_backup_$STAMP"

if [ ! -f "$ONBOARDING_FILE" ]; then
  echo "Could not find $ONBOARDING_FILE"
  echo "Run this from the project root."
  exit 1
fi

if [ ! -f "$STYLES_FILE" ]; then
  echo "Could not find $STYLES_FILE"
  echo "Run this from the project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src/pages" "$BACKUP_DIR/frontend/src"
cp "$ONBOARDING_FILE" "$BACKUP_DIR/frontend/src/pages/OnboardingPage.tsx"
cp "$STYLES_FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch1_onboarding_hardening..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path
import sys

onboarding_path = Path("frontend/src/pages/OnboardingPage.tsx")
styles_path = Path("frontend/src/styles.css")

text = onboarding_path.read_text()
styles = styles_path.read_text()

def replace_once(source: str, old: str, new: str, label: str) -> str:
    if old not in source:
        raise SystemExit(f"Expected snippet for {label} not found.")
    return source.replace(old, new, 1)

text = replace_once(
    text,
    'export default function OnboardingPage() {\n  const { refreshUser } = useAuth();',
    'export default function OnboardingPage() {\n  const { refreshUser, user } = useAuth();',
    "useAuth destructure"
)

helper_anchor = '''const favoriteExperienceOptions = [
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
'''

helper_block = '''const favoriteExperienceOptions = [
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
'''

text = replace_once(text, helper_anchor, helper_block, "draft helper insertion")

state_anchor = '''  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [isHydrating, setIsHydrating] = useState(true);
  const [optionsResponse, setOptionsResponse] = useState<OnboardingOptionsResponse>(fallbackOnboardingOptions);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
'''

state_block = '''  const [restaurantOptions, setRestaurantOptions] = useState<string[]>([]);
  const [isHydrating, setIsHydrating] = useState(true);
  const [optionsResponse, setOptionsResponse] = useState<OnboardingOptionsResponse>(fallbackOnboardingOptions);
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [restoredDraftAt, setRestoredDraftAt] = useState<string | null>(null);

  const draftStorageKey = useMemo(
    () => getDraftStorageKey(user?.id, location.pathname),
    [user?.id, location.pathname]
  );
'''

text = replace_once(text, state_anchor, state_block, "state block")

hydrate_anchor = '''        const restaurantNames = restaurants.map((restaurant) => restaurant.name);
        const nextForm = toFormState(onboardingState);

        setRestaurantOptions(restaurantNames);
        setSavedState(cloneFormState(nextForm));
        setForm(nextForm);
        setOptionsResponse(onboardingOptions);
'''

hydrate_block = '''        const restaurantNames = restaurants.map((restaurant) => restaurant.name);
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
'''

text = replace_once(text, hydrate_anchor, hydrate_block, "hydrate restore logic")
text = replace_once(text, '  }, []);', '  }, [draftStorageKey]);', "hydrate dependencies")

memo_anchor = '''  const totalScreens = wizardSteps.length + 1;
  const currentStep = wizardSteps[currentStepIndex];
  const isReviewStep = currentStepIndex >= wizardSteps.length;
  const progressPercent = Math.max(8, Math.round(((currentStepIndex + 1) / totalScreens) * 100));
'''

memo_block = '''  const totalScreens = wizardSteps.length + 1;
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

    if (parsedMin !== null and parsedMax !== null and parsedMin > parsedMax):
        pass
    return ""
  }, [form.budget_min_per_person, form.budget_max_per_person]);

  const hasUnsavedChanges = useMemo(
    () => comparableFormSnapshot(form) !== comparableFormSnapshot(savedState),
    [form, savedState]
  );
'''

# fix the small Pythonic placeholder after insertion
memo_block = memo_block.replace(
    '''    if (parsedMin !== null and parsedMax !== null and parsedMin > parsedMax):
        pass
    return ""''',
    '''    if (parsedMin !== null && parsedMax !== null && parsedMin > parsedMax) {
      return "Minimum budget cannot be greater than maximum budget.";
    }

    return "";'''
)

text = replace_once(text, memo_anchor, memo_block, "budget and draft memos")

effects_anchor = '''  const completionStats = useMemo(
    () => [
      { label: "Cuisine", value: form.cuisine_preferences.length },
      { label: "Atmosphere", value: form.atmosphere_preferences.length },
      { label: "Drinks", value: form.drink_preferences.length },
      { label: "Favorites", value: form.favorite_restaurants.length }
    ],
    [form]
  );

  function toggleArrayField(field: ChoiceFieldKey, value: string) {
'''

effects_block = '''  const completionStats = useMemo(
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
'''

text = replace_once(text, effects_anchor, effects_block, "draft effects")

reset_anchor = '''  function resetToSavedState() {
    const restored = cloneFormState(savedState);
    setForm(restored);
    setCurrentStepIndex(0);
    setMessage("Your onboarding form has been reset to the last saved version.");
    setError("");
  }
'''

reset_block = '''  function resetToSavedState() {
    const restored = cloneFormState(savedState);
    setForm(restored);
    setCurrentStepIndex(0);
    setRestoredDraftAt(null);
    clearOnboardingDraft(draftStorageKey);
    setMessage("Your onboarding form has been reset to the last saved version.");
    setError("");
  }
'''

text = replace_once(text, reset_anchor, reset_block, "reset clear draft")

submit_anchor = '''      setSavedState(cloneFormState(persistedForm));
      setForm(persistedForm);

      await refreshUser();

      const nextMessage = response.message || "Your SAVR profile has been updated.";
'''

submit_block = '''      setSavedState(cloneFormState(persistedForm));
      setForm(persistedForm);
      setRestoredDraftAt(null);
      clearOnboardingDraft(draftStorageKey);

      await refreshUser();

      const nextMessage = response.message || "Your SAVR profile has been updated.";
'''

text = replace_once(text, submit_anchor, submit_block, "submit clear draft")

message_anchor = '''      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-2 onboarding-grid">
'''

message_block = '''      <div className="sr-only" aria-live="polite">
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
'''

text = replace_once(text, message_anchor, message_block, "draft banner")

progress_anchor = '''          <div className="wizard-progress-shell" aria-label="Onboarding progress">
            <div className="wizard-progress-meta">
              <span>{isReviewStep ? "Review and save" : "Guided onboarding"}</span>
              <strong>{progressPercent}%</strong>
            </div>
            <div className="wizard-progress-track" aria-hidden="true">
              <div className="wizard-progress-fill" style={{ width: `${progressPercent}%` }} />
            </div>
          </div>
'''

progress_block = '''          <div className="wizard-progress-shell" aria-label="Onboarding progress">
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
'''

text = replace_once(text, progress_anchor, progress_block, "draft note")

budget_anchor = '''                  <div className="form-row">
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
                </div>
              ) : null}
'''

budget_block = '''                  <div className="form-row">
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
'''

text = replace_once(text, budget_anchor, budget_block, "budget inline error")

actions_anchor = '''              {!isReviewStep && currentStep.optional ? (
                <Button type="button" variant="secondary" onClick={goNext} disabled={isSubmitting}>
                  Skip for now
                </Button>
              ) : null}

              {!isReviewStep ? (
                <Button type="button" onClick={goNext} disabled={isSubmitting}>
                  {currentStepIndex === wizardSteps.length - 1 ? "Review profile" : "Continue"}
                </Button>
              ) : (
                <Button type="button" onClick={handleSubmit} disabled={isSubmitting}>
                  {isSubmitting ? "Saving..." : "Save profile"}
                </Button>
              )}
'''

actions_block = '''              {!isReviewStep && currentStep.optional ? (
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
'''

text = replace_once(text, actions_anchor, actions_block, "action disable rules")

guide_anchor = '''              <div className="item">
                <strong>Automatic redirect after save</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  New users return to the dashboard after onboarding, while profile edits return to the profile page.
                </p>
              </div>
'''

guide_block = '''              <div className="item">
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
'''

text = replace_once(text, guide_anchor, guide_block, "guide copy")

if ".onboarding-draft-banner" not in styles:
    styles += '''

.onboarding-draft-banner {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  padding: 1rem 1.1rem;
  border-radius: 18px;
  border: 1px solid rgba(86, 115, 66, 0.2);
  background: rgba(125, 156, 102, 0.08);
}

.onboarding-draft-banner .button-row {
  flex-wrap: wrap;
  justify-content: flex-end;
}

.wizard-draft-note {
  margin: 0.75rem 0 0;
  font-size: 0.92rem;
  color: var(--color-text-muted, #5f6b61);
}

.wizard-inline-error {
  margin: 0;
  color: #9f2d2d;
  font-size: 0.92rem;
  font-weight: 600;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

@media (max-width: 900px) {
  .onboarding-draft-banner {
    flex-direction: column;
    align-items: flex-start;
  }
}
'''

onboarding_path.write_text(text)
styles_path.write_text(styles)
PY

echo
echo "Patch 1 applied successfully."
echo "Files changed:"
echo " - frontend/src/pages/OnboardingPage.tsx"
echo " - frontend/src/styles.css"
echo
echo "Manual test targets:"
echo "1) Reload mid-onboarding and confirm draft/step restore"
echo "2) Enter min budget greater than max and confirm Continue/Save is blocked"
echo "3) Reset to saved and confirm local draft clears"
echo "4) Save onboarding and confirm redirect + no restored draft banner on return"
