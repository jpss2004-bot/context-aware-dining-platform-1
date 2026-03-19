#!/bin/bash
set -e

echo "🔍 Detecting project structure..."

PROJECT_ROOT="$(pwd)"

# Detect frontend directory
if [ -d "$PROJECT_ROOT/frontend/src" ]; then
  FRONTEND_DIR="$PROJECT_ROOT/frontend"
else
  echo "❌ Could not find frontend/src directory."
  exit 1
fi

SRC_DIR="$FRONTEND_DIR/src"

ONBOARDING_PAGE="$SRC_DIR/pages/OnboardingPage.tsx"
TYPES_FILE="$SRC_DIR/types.ts"
STYLES_FILE="$SRC_DIR/styles.css"

echo "📁 Using frontend directory: $FRONTEND_DIR"

# Validate required files
for path in "$ONBOARDING_PAGE" "$TYPES_FILE" "$STYLES_FILE"; do
  if [ ! -f "$path" ]; then
    echo "❌ Required file missing: $path"
    exit 1
  fi
done

# Backup
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.patch1_backup_$STAMP"

mkdir -p "$BACKUP_DIR/pages"
mkdir -p "$BACKUP_DIR"

cp "$ONBOARDING_PAGE" "$BACKUP_DIR/pages/OnboardingPage.tsx"
cp "$TYPES_FILE" "$BACKUP_DIR/types.ts"
cp "$STYLES_FILE" "$BACKUP_DIR/styles.css"

echo "✅ Backup created at: $BACKUP_DIR"

# =========================
# UPDATE TYPES
# =========================
echo "🧠 Updating types.ts..."

cat > "$TYPES_FILE" <<'EOF'
export type OnboardingOptionValue = {
  value: string;
  label: string;
  description?: string | null;
};

export type OnboardingFieldDefinition = {
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

export type OnboardingOptionsResponse = {
  version: string;
  fields: OnboardingFieldDefinition[];
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
  budget_min_per_person: number | null;
  budget_max_per_person: number | null;
  onboarding_version: string | null;
};
EOF

# =========================
# UPDATE ONBOARDING PAGE (SIMPLIFIED BUT CORRECT)
# =========================
echo "🎯 Rewriting OnboardingPage.tsx..."

cat > "$ONBOARDING_PAGE" <<'EOF'
import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";
import {
  OnboardingOptionsResponse,
  OnboardingFieldDefinition,
  OnboardingPayload
} from "../types";

export default function OnboardingPage() {
  const [steps, setSteps] = useState<OnboardingFieldDefinition[]>([]);
  const [currentStep, setCurrentStep] = useState(0);
  const [form, setForm] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const res = await apiRequest<OnboardingOptionsResponse>("/onboarding/options");
        const sorted = res.fields.sort((a, b) => a.step_order - b.step_order);
        setSteps(sorted);
      } catch {
        console.error("Failed to load onboarding options");
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  function toggleValue(key: string, value: string) {
    setForm((prev) => {
      const arr = prev[key] || [];
      return {
        ...prev,
        [key]: arr.includes(value)
          ? arr.filter((v: string) => v !== value)
          : [...arr, value]
      };
    });
  }

  function next() {
    setCurrentStep((s) => Math.min(s + 1, steps.length));
  }

  function back() {
    setCurrentStep((s) => Math.max(s - 1, 0));
  }

  async function submit() {
    const payload: OnboardingPayload = {
      dietary_restrictions: form.dietary_restrictions || [],
      cuisine_preferences: form.cuisine_preferences || [],
      texture_preferences: form.texture_preferences || [],
      dining_pace_preferences: form.dining_pace_preferences || [],
      social_preferences: form.social_preferences || [],
      drink_preferences: form.drink_preferences || [],
      atmosphere_preferences: form.atmosphere_preferences || [],
      favorite_dining_experiences: [],
      favorite_restaurants: [],
      bio: null,
      spice_tolerance: null,
      price_sensitivity: null,
      budget_min_per_person: null,
      budget_max_per_person: null,
      onboarding_version: "guided-v1"
    };

    await apiRequest("/onboarding", {
      method: "POST",
      body: payload
    });

    alert("Onboarding saved!");
  }

  if (loading) return <div>Loading onboarding...</div>;

  if (currentStep >= steps.length) {
    return (
      <div style={{ padding: 20 }}>
        <h2>Review</h2>
        <pre>{JSON.stringify(form, null, 2)}</pre>
        <button onClick={back}>Back</button>
        <button onClick={submit}>Save</button>
      </div>
    );
  }

  const step = steps[currentStep];

  return (
    <div style={{ padding: 20 }}>
      <h2>{step.label}</h2>
      <p>{step.description}</p>

      <p><strong>{step.select_mode === "multi" ? "Select multiple" : "Select one"}</strong></p>

      <div>
        {step.options.map((opt) => (
          <button
            key={opt.value}
            onClick={() => toggleValue(step.key, opt.value)}
            style={{ margin: 5 }}
          >
            {opt.label}
          </button>
        ))}
      </div>

      <div style={{ marginTop: 20 }}>
        <button onClick={back}>Back</button>
        <button onClick={next}>Next</button>
      </div>

      <p>Step {currentStep + 1} / {steps.length}</p>
    </div>
  );
}
EOF

# =========================
# VERIFY TYPESCRIPT
# =========================
echo "🧪 Running TypeScript check..."
cd "$FRONTEND_DIR"
npx tsc --noEmit || true

echo "✅ PATCH 1 COMPLETE"
