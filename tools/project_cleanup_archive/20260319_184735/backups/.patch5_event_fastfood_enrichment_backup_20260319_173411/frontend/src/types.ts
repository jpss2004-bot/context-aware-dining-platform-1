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
