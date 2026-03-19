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

export type Tag = {
  id: number;
  name: string;
  category: string;
};

export type VenueEvent = {
  id: number;
  restaurant_id: number;
  name: string;
  event_type: string;
  description: string | null;
  day_of_week: string | null;
  event_date: string | null;
  recurrence: string | null;
  start_time: string | null;
  end_time: string | null;
  is_active: boolean;
};

export type MenuItem = {
  id: number;
  restaurant_id: number;
  name: string;
  category: string;
  price: number | null;
  description: string | null;
  is_signature: boolean;
  meal_period?: string | null;
  recommendation_hint?: string | null;
  is_dish_highlight?: boolean;
  tags: Tag[];
};

export type RestaurantListItem = {
  id: number;
  name: string;
  description: string | null;
  city: string;
  town?: string | null;
  region?: string | null;
  address?: string | null;
  category?: string | null;
  subcategory?: string | null;
  price_tier: string;
  price_min_per_person?: number | null;
  price_max_per_person?: number | null;
  atmosphere: string | null;
  pace: string | null;
  social_style: string | null;
  serves_alcohol: boolean;
  offers_dine_in?: boolean | null;
  offers_takeout?: boolean | null;
  offers_delivery?: boolean | null;
  accepts_reservations?: boolean | null;
  supports_brunch?: boolean | null;
  supports_lunch?: boolean | null;
  supports_dinner?: boolean | null;
  supports_dessert?: boolean | null;
  supports_coffee?: boolean | null;
  is_fast_food?: boolean | null;
  is_family_friendly?: boolean | null;
  is_date_night?: boolean | null;
  is_student_friendly?: boolean | null;
  is_quick_bite?: boolean | null;
  has_live_music?: boolean | null;
  has_trivia_night?: boolean | null;
  event_notes?: string | null;
  source_url?: string | null;
  source_notes?: string | null;
};

export type RestaurantDetail = RestaurantListItem & {
  tags: Tag[];
  menu_items: MenuItem[];
  events: VenueEvent[];
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
  budget_min_per_person?: number | null;
  budget_max_per_person?: number | null;
  onboarding_version?: string | null;
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
  budget_min_per_person?: number | null;
  budget_max_per_person?: number | null;
  onboarding_version?: string | null;
  onboarding_completed: boolean;
};

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
  active_event_matches?: string[];
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
