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

export type ScoreBreakdownItem = {
  label: string;
  points: number;
};

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
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
