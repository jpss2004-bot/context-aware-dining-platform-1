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
