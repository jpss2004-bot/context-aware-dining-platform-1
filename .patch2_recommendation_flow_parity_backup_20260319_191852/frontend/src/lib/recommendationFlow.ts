import { apiRequest } from "./api";

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  rank?: number;
  fit_label?: string;
  reasons?: string[];
  explanation?: string | null;
  confidence_level?: string;
  matched_signals?: string[];
  penalized_signals?: string[];
  score_breakdown?: { label: string; points: number }[];
  suggested_dishes?: string[];
  suggested_drinks?: string[];
  active_event_matches?: string[];
};

export type RecommendationResponse = {
  mode: string;
  engine_version?: string;
  generated_at?: string;
  request_summary?: Record<string, unknown>;
  results: RecommendationItem[];
};

export type PresetSelectionPayload = {
  outing_type?: string | null;
  mood?: string | null;
  budget?: string | null;
  pace?: string | null;
  social_context?: string | null;
  preferred_cuisines: string[];
  drinks_focus?: boolean | null;
  atmosphere: string[];
  towns?: string[];
  include_tags?: string[];
  exclude_tags?: string[];
  family_friendly?: boolean | null;
  student_friendly?: boolean | null;
  date_night?: boolean | null;
  quick_bite?: boolean | null;
  fast_food?: boolean | null;
  requires_dine_in?: boolean | null;
  requires_takeout?: boolean | null;
  requires_delivery?: boolean | null;
  requires_reservations?: boolean | null;
  requires_live_music?: boolean | null;
  requires_trivia?: boolean | null;
  include_dish_hints?: boolean | null;
};

export type PresetResponse = {
  preset_id: string;
  owner_type: "system" | "user" | string;
  owner_user_id?: number | null;
  is_editable: boolean;
  name: string;
  description?: string | null;
  selection_payload: PresetSelectionPayload;
  created_at?: string | null;
  updated_at?: string | null;
};

export type PresetApplyResponse = {
  preset: PresetResponse;
  builder_payload: PresetSelectionPayload;
  banner_message: string;
  can_customize: boolean;
};

export type StoredRecommendationResult = {
  mode: "build" | "describe" | "surprise";
  createdAt: string;
  request?: unknown;
  response: RecommendationResponse;
};

export const RESULT_STORAGE_KEY = "savr:recommendation-flow-result:v3";

export function saveRecommendationResult(result: StoredRecommendationResult) {
  sessionStorage.setItem(RESULT_STORAGE_KEY, JSON.stringify(result));
}

export function loadRecommendationResult(): StoredRecommendationResult | null {
  try {
    const raw = sessionStorage.getItem(RESULT_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as StoredRecommendationResult;
  } catch {
    return null;
  }
}

export function clearRecommendationResult() {
  sessionStorage.removeItem(RESULT_STORAGE_KEY);
}

export async function runBuildNight(body: {
  outing_type: string;
  budget?: string;
  pace?: string;
  social_context?: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
}) {
  return apiRequest<RecommendationResponse>("/recommendations/build-your-night", {
    method: "POST",
    body
  });
}

export async function runDescribeNight(body: { prompt: string }) {
  return apiRequest<RecommendationResponse>("/recommendations/describe-your-night", {
    method: "POST",
    body
  });
}

export async function runSurpriseMe(body: { include_drinks: boolean }) {
  return apiRequest<RecommendationResponse>("/recommendations/surprise-me", {
    method: "POST",
    body
  });
}

export async function listPresets() {
  return apiRequest<PresetResponse[]>("/presets");
}

export async function applyPreset(presetId: string) {
  return apiRequest<PresetApplyResponse>(`/presets/${presetId}/apply`, {
    method: "POST"
  });
}

export async function createPreset(body: {
  name: string;
  description?: string | null;
  selection_payload: PresetSelectionPayload;
}) {
  return apiRequest<PresetResponse>("/presets", {
    method: "POST",
    body
  });
}

export async function deletePreset(presetId: string) {
  return apiRequest<{ message: string; deleted_preset_id: string }>(`/presets/${presetId}`, {
    method: "DELETE"
  });
}

export function normalizeRecommendationScore(score: number, maxScore: number) {
  if (!Number.isFinite(score) || !Number.isFinite(maxScore) || maxScore <= 0) {
    return undefined;
  }
  const value = score / maxScore;
  return Math.max(0, Math.min(value, 1));
}
