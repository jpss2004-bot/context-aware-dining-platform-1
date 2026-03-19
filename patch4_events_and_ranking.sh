#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
BACKEND_DIR="$ROOT/backend"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch4_events_and_ranking_backup_$STAMP"

FILES=(
  "$BACKEND_DIR/app/services/recommendation_service.py"
  "$FRONTEND_DIR/src/pages/RestaurantDetailPage.tsx"
  "$FRONTEND_DIR/src/components/dining/RecommendationCard.tsx"
  "$FRONTEND_DIR/src/styles.css"
)

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file"
    echo "Run this from the project root."
    exit 1
  fi
done

mkdir -p \
  "$BACKUP_DIR/backend/app/services" \
  "$BACKUP_DIR/frontend/src/pages" \
  "$BACKUP_DIR/frontend/src/components/dining" \
  "$BACKUP_DIR/frontend/src"

cp "$BACKEND_DIR/app/services/recommendation_service.py" \
  "$BACKUP_DIR/backend/app/services/recommendation_service.py"
cp "$FRONTEND_DIR/src/pages/RestaurantDetailPage.tsx" \
  "$BACKUP_DIR/frontend/src/pages/RestaurantDetailPage.tsx"
cp "$FRONTEND_DIR/src/components/dining/RecommendationCard.tsx" \
  "$BACKUP_DIR/frontend/src/components/dining/RecommendationCard.tsx"
cp "$FRONTEND_DIR/src/styles.css" \
  "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch4_events_and_ranking..."
echo "Resolved backend directory: $BACKEND_DIR"
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

service_path = Path("backend/app/services/recommendation_service.py")
detail_path = Path("frontend/src/pages/RestaurantDetailPage.tsx")
card_path = Path("frontend/src/components/dining/RecommendationCard.tsx")
styles_path = Path("frontend/src/styles.css")

service = service_path.read_text()
detail = detail_path.read_text()
card = card_path.read_text()
styles = styles_path.read_text()

def replace_once(source: str, old: str, new: str, label: str) -> str:
    if old not in source:
        raise SystemExit(f"Expected snippet for {label} not found.")
    return source.replace(old, new, 1)

service = replace_once(
    service,
    '    ENGINE_VERSION = "phase3-intelligence-v1"',
    '    ENGINE_VERSION = "phase5-events-v1"',
    "engine constant"
)

service = service.replace('engine_version="phase4-presets-v1"', 'engine_version=self.ENGINE_VERSION')

old_event_block = '''    def _event_label(self, event) -> str:
        parts = [event.name]
        if getattr(event, "day_of_week", None):
            parts.append(f"({event.day_of_week.title()})")
        return " ".join(parts)

    def _event_is_current(self, event) -> bool:
        if not getattr(event, "is_active", False):
            return False

        event_date = getattr(event, "event_date", None)
        recurrence = self._normalize_text(getattr(event, "recurrence", None))
        day_of_week = self._normalize_text(getattr(event, "day_of_week", None))
        today = datetime.now(timezone.utc).date()
        today_name = datetime.now(timezone.utc).strftime("%A").lower()

        if event_date is not None:
            return event_date >= today

        if day_of_week and day_of_week == today_name:
            return True

        if recurrence in {"weekly", "biweekly", "monthly", "recurring"}:
            return True

        return day_of_week != "" or recurrence != ""

    def _apply_event_signal_scoring(
        self,
        restaurant: Restaurant,
        outing_type: Optional[str],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int, int, list[str]]:
        points = 0.0
        strong_matches = 0
        contradictions = 0
        event_matches: list[str] = []

        current_events = [
            event for event in getattr(restaurant, "events", [])
            if self._event_is_current(event)
        ]

        for event in current_events:
            normalized_type = self._normalize_text(getattr(event, "event_type", None))
            normalized_name = self._normalize_text(getattr(event, "name", None))
            label = self._event_label(event)

            if requires_live_music is True and ("live music" in normalized_type or "live music" in normalized_name):
                points += 1.6
                strong_matches += 1
                event_matches.append(label)
                self._append_reason(reasons, f"Boosted by an active venue event ({label})")
                self._append_signal(matched_signals, f"event match ({label})")

            if requires_trivia is True and ("trivia" in normalized_type or "trivia" in normalized_name):
                points += 1.6
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Boosted by an active venue event ({label})")
                self._append_signal(matched_signals, f"event match ({label})")

            if self._normalize_text(outing_type) == "drinks-night" and any(
                keyword in normalized_type or keyword in normalized_name
                for keyword in ["live music", "trivia", "themed"]
            ):
                points += 0.8
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Supports a more social outing through an active event ({label})")
                self._append_signal(matched_signals, f"social event support ({label})")

        if points != 0:
            self._add_breakdown(breakdown, "active events", points)

        return points, strong_matches, contradictions, event_matches
'''

new_event_block = '''    def _event_label(self, event) -> str:
        parts = [event.name]

        if getattr(event, "day_of_week", None):
            parts.append(f"({event.day_of_week.title()})")
        elif getattr(event, "event_date", None):
            parts.append(f"({event.event_date.isoformat()})")

        return " ".join(parts)

    def _event_is_current(self, event) -> bool:
        if not getattr(event, "is_active", False):
            return False

        event_date = getattr(event, "event_date", None)
        recurrence = self._normalize_text(getattr(event, "recurrence", None))
        day_of_week = self._normalize_text(getattr(event, "day_of_week", None))

        today_dt = datetime.now(timezone.utc)
        today = today_dt.date()
        today_name = today_dt.strftime("%A").lower()

        if event_date is not None:
            days_until = (event_date - today).days
            return -1 <= days_until <= 21

        if day_of_week and day_of_week == today_name:
            return True

        if recurrence in {"weekly", "biweekly", "monthly", "recurring"}:
            return True

        return day_of_week != "" or recurrence != ""

    def _is_music_event(self, normalized_type: str, normalized_name: str) -> bool:
        return any(
            keyword in normalized_type or keyword in normalized_name
            for keyword in ["live music", "music", "open mic", "karaoke", "acoustic", "band"]
        )

    def _is_trivia_event(self, normalized_type: str, normalized_name: str) -> bool:
        return any(
            keyword in normalized_type or keyword in normalized_name
            for keyword in ["trivia", "quiz", "pub quiz"]
        )

    def _is_social_event(self, normalized_type: str, normalized_name: str) -> bool:
        return any(
            keyword in normalized_type or keyword in normalized_name
            for keyword in ["live music", "music", "trivia", "themed", "comedy", "karaoke"]
        )

    def _apply_event_signal_scoring(
        self,
        restaurant: Restaurant,
        outing_type: Optional[str],
        requires_live_music: Optional[bool],
        requires_trivia: Optional[bool],
        reasons: list[str],
        matched_signals: list[str],
        breakdown: dict[str, float],
    ) -> tuple[float, int, int, list[str]]:
        points = 0.0
        strong_matches = 0
        contradictions = 0
        event_matches: list[str] = []

        current_events = [
            event for event in getattr(restaurant, "events", [])
            if self._event_is_current(event)
        ]

        has_live_music_event = False
        has_trivia_event = False

        for event in current_events:
            normalized_type = self._normalize_text(getattr(event, "event_type", None))
            normalized_name = self._normalize_text(getattr(event, "name", None))
            label = self._event_label(event)

            is_music = self._is_music_event(normalized_type, normalized_name)
            is_trivia = self._is_trivia_event(normalized_type, normalized_name)
            is_social = self._is_social_event(normalized_type, normalized_name)

            has_live_music_event = has_live_music_event or is_music
            has_trivia_event = has_trivia_event or is_trivia

            if requires_live_music is True and is_music:
                points += 1.8
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Boosted by an active venue event ({label})")
                self._append_signal(matched_signals, f"event match ({label})")

            if requires_trivia is True and is_trivia:
                points += 1.8
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Boosted by an active venue event ({label})")
                self._append_signal(matched_signals, f"event match ({label})")

            if self._normalize_text(outing_type) == "drinks-night" and is_social:
                points += 0.9
                strong_matches += 1
                if label not in event_matches:
                    event_matches.append(label)
                self._append_reason(reasons, f"Supports a more social outing through an active event ({label})")
                self._append_signal(matched_signals, f"social event support ({label})")

        if requires_live_music is True and not has_live_music_event and restaurant.has_live_music:
            points += 0.7
            strong_matches += 1
            self._append_reason(reasons, "Supports live music through venue metadata.")
            self._append_signal(matched_signals, "live music venue flag")

        if requires_trivia is True and not has_trivia_event and restaurant.has_trivia_night:
            points += 0.7
            strong_matches += 1
            self._append_reason(reasons, "Supports trivia through venue metadata.")
            self._append_signal(matched_signals, "trivia venue flag")

        if self._normalize_text(outing_type) == "drinks-night" and not event_matches and (
            restaurant.has_live_music or restaurant.has_trivia_night
        ):
            points += 0.35
            self._append_reason(reasons, "Supports a social outing through venue entertainment signals.")
            self._append_signal(matched_signals, "social entertainment flag")

        if points != 0:
            self._add_breakdown(breakdown, "active events", points)

        return points, strong_matches, contradictions, event_matches
'''

service = replace_once(service, old_event_block, new_event_block, "event scoring block")
service_path.write_text(service)

detail_path.write_text("""import { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { MenuItem, RestaurantDetail, VenueEvent } from "../types";

function formatEventTiming(event: VenueEvent): string {
  const parts: string[] = [];

  if (event.day_of_week) {
    parts.push(event.day_of_week);
  }

  if (event.event_date) {
    parts.push(event.event_date);
  }

  if (event.start_time || event.end_time) {
    parts.push([event.start_time, event.end_time].filter(Boolean).join(" - "));
  }

  if (event.recurrence) {
    parts.push(event.recurrence);
  }

  return parts.join(" • ");
}

function getEventStatus(event: VenueEvent): "active" | "upcoming" | "recurring" | "inactive" {
  if (!event.is_active) return "inactive";
  if (event.event_date) return "upcoming";
  if (event.recurrence || event.day_of_week) return "recurring";
  return "active";
}

function sortEvents(events: VenueEvent[]) {
  const weight = (event: VenueEvent) => {
    const status = getEventStatus(event);
    if (status === "active") return 0;
    if (status === "upcoming") return 1;
    if (status === "recurring") return 2;
    return 3;
  };

  return [...events].sort((a, b) => {
    const primary = weight(a) - weight(b);
    if (primary !== 0) return primary;

    const dateA = a.event_date || "";
    const dateB = b.event_date || "";
    if (dateA !== dateB) return dateA.localeCompare(dateB);

    return a.name.localeCompare(b.name);
  });
}

function formatPrice(value: number | null | undefined) {
  if (typeof value !== "number") return "-";
  return `$${value.toFixed(2)}`;
}

export default function RestaurantDetailPage() {
  const { restaurantId } = useParams<{ restaurantId: string }>();

  const [restaurant, setRestaurant] = useState<RestaurantDetail | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadRestaurant() {
      if (!restaurantId) {
        setError("No restaurant was selected.");
        setLoading(false);
        return;
      }

      try {
        setError("");
        setLoading(true);
        const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
        if (!cancelled) {
          setRestaurant(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "We could not load this venue.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadRestaurant();

    return () => {
      cancelled = true;
    };
  }, [restaurantId]);

  const summaryText = useMemo(() => {
    if (!restaurant) {
      return "Open a venue from the restaurant catalog to inspect its menu, tags, atmosphere, and recommendation signals.";
    }

    return restaurant.description || "No summary is available for this venue yet.";
  }, [restaurant]);

  const highlightedMenuItems = useMemo<MenuItem[]>(
    () =>
      restaurant?.menu_items.filter(
        (item) => item.is_dish_highlight || item.is_signature || Boolean(item.recommendation_hint)
      ) || [],
    [restaurant]
  );

  const orderedEvents = useMemo(() => sortEvents(restaurant?.events || []), [restaurant?.events]);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Restaurant detail</p>
        <h1 className="page-title">{restaurant?.name || "Venue overview"}</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Dedicated venue pages make it easier to inspect a restaurant without crowding the full restaurant listing page.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <div className="button-row">
        <Link to="/restaurants">
          <Button variant="ghost">Back to restaurants</Button>
        </Link>
        <Link to="/recommendations">
          <Button variant="secondary">Go to recommendations</Button>
        </Link>
      </div>

      <Card
        title={restaurant?.name || "Venue detail"}
        subtitle={summaryText}
        actions={restaurant ? <Badge tone="accent">{restaurant.price_tier}</Badge> : <Badge>Preview</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading venue detail</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling restaurant information from the backend.
            </p>
          </div>
        ) : !restaurant ? (
          <div className="item">
            <strong>No venue selected</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Return to the restaurant list and choose a venue.
            </p>
          </div>
        ) : (
          <div className="list">
            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Venue profile</p>
              <strong>Atmosphere and positioning</strong>
              <p className="muted">
                {restaurant.city} • {restaurant.price_tier} • {restaurant.atmosphere || "No atmosphere"} • {restaurant.pace || "No pace"} • {restaurant.social_style || "No social style"}
              </p>
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                {restaurant.is_fast_food ? <Badge tone="warning">Fast food</Badge> : null}
                {restaurant.has_live_music ? <Badge tone="accent">Live music</Badge> : null}
                {restaurant.has_trivia_night ? <Badge tone="accent">Trivia</Badge> : null}
                {restaurant.tags.map((tag) => (
                  <Badge key={`${tag.category}-${tag.name}`}>{tag.category}: {tag.name}</Badge>
                ))}
              </div>
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Venue events</p>
              <strong>Current, upcoming, and recurring event signals</strong>
              {orderedEvents.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No structured venue events are currently saved for this restaurant.
                </p>
              ) : (
                <div className="event-card-grid" style={{ marginTop: "0.8rem" }}>
                  {orderedEvents.map((event) => {
                    const status = getEventStatus(event);
                    return (
                      <div key={event.id} className="event-detail-card">
                        <div style={{ display: "flex", justifyContent: "space-between", gap: "0.6rem", flexWrap: "wrap" }}>
                          <strong>{event.name}</strong>
                          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                            <Badge tone={event.is_active ? "success" : "default"}>
                              {event.is_active ? "Active" : "Inactive"}
                            </Badge>
                            <Badge tone={status === "upcoming" ? "accent" : status === "recurring" ? "warning" : "default"}>
                              {status}
                            </Badge>
                          </div>
                        </div>
                        <p className="muted" style={{ margin: "0.45rem 0" }}>
                          {event.description || "No event description available."}
                        </p>
                        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                          <Badge tone="accent">{event.event_type}</Badge>
                          {formatEventTiming(event) ? <Badge>{formatEventTiming(event)}</Badge> : null}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Recommended menu signals</p>
              <strong>Highlighted dishes and strong order candidates</strong>
              {highlightedMenuItems.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No highlighted dish metadata was returned for this venue.
                </p>
              ) : (
                <div className="list" style={{ marginTop: "0.8rem" }}>
                  {highlightedMenuItems.map((item) => (
                    <div className="item" key={`highlight-${item.id}`}>
                      <div style={{ display: "flex", justifyContent: "space-between", gap: "0.75rem", flexWrap: "wrap" }}>
                        <strong>{item.name}</strong>
                        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                          {item.is_signature ? <Badge tone="success">Signature</Badge> : null}
                          {item.is_dish_highlight ? <Badge tone="accent">Recommended</Badge> : null}
                        </div>
                      </div>
                      <p className="muted" style={{ margin: "0.45rem 0" }}>
                        {item.category} • Price: {formatPrice(item.price)}
                      </p>
                      <p style={{ marginBottom: item.recommendation_hint ? "0.45rem" : 0 }}>
                        {item.description || "No description"}
                      </p>
                      {item.recommendation_hint ? (
                        <p className="muted" style={{ marginBottom: 0 }}>
                          Why it stands out: {item.recommendation_hint}
                        </p>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="item">
              <p className="navbar-eyebrow" style={{ marginBottom: "0.4rem" }}>Full menu</p>
              <strong>Menu items</strong>
              {restaurant.menu_items.length === 0 ? (
                <p className="muted" style={{ marginBottom: 0 }}>
                  No menu items were returned for this venue.
                </p>
              ) : (
                <div className="list" style={{ marginTop: "0.8rem" }}>
                  {restaurant.menu_items.map((item) => (
                    <div className="item" key={item.id}>
                      <strong>{item.name}</strong>
                      <p className="muted">
                        {item.category} • Price: {formatPrice(item.price)} • {item.is_signature ? "Signature item" : "Standard item"}
                      </p>
                      <p style={{ marginBottom: item.tags.length > 0 ? "0.8rem" : 0 }}>
                        {item.description || "No description"}
                      </p>
                      {item.tags.length > 0 ? (
                        <div>
                          {item.tags.map((tag) => (
                            <Badge key={`${item.id}-${tag.id}`} tone="accent">
                              {tag.name}
                            </Badge>
                          ))}
                        </div>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
""")

card_path.write_text("""import { useState } from "react";

import Badge from "../ui/Badge";
import Button from "../ui/Button";
import Card from "../ui/Card";
import { ScoreBreakdownItem } from "../../types";

type RecommendationCardProps = {
  title: string;
  restaurantName?: string;
  score?: number;
  rank?: number;
  fitLabel?: string;
  explanation?: string;
  confidenceLevel?: string;
  tags?: string[];
  matchedSignals?: string[];
  penalizedSignals?: string[];
  scoreBreakdown?: ScoreBreakdownItem[];
  suggestedDishes?: string[];
  suggestedDrinks?: string[];
  activeEventMatches?: string[];
  ctaLabel?: string;
  onClick?: () => void;
};

function formatScore(score?: number) {
  if (score === undefined || score === null || Number.isNaN(score)) {
    return null;
  }

  const clamped = Math.max(0, Math.min(score, 1));
  return `${Math.round(clamped * 100)}% match`;
}

function confidenceTone(confidenceLevel?: string): "default" | "accent" | "success" | "warning" {
  switch ((confidenceLevel || "").toLowerCase()) {
    case "high":
      return "success";
    case "medium":
      return "accent";
    case "exploratory":
      return "warning";
    default:
      return "default";
  }
}

function confidenceLabel(confidenceLevel?: string): string | null {
  if (!confidenceLevel) {
    return null;
  }

  if (confidenceLevel === "high") {
    return "High confidence";
  }

  if (confidenceLevel === "medium") {
    return "Medium confidence";
  }

  if (confidenceLevel === "exploratory") {
    return "Exploratory";
  }

  return confidenceLevel;
}

function fitTone(fitLabel?: string): "default" | "accent" | "success" | "warning" {
  switch ((fitLabel || "").toLowerCase()) {
    case "excellent fit":
      return "success";
    case "strong fit":
      return "accent";
    case "possible fit":
      return "warning";
    default:
      return "default";
  }
}

function formatBreakdownPoints(points: number): string {
  return `${points >= 0 ? "+" : ""}${points.toFixed(2)}`;
}

export default function RecommendationCard({
  title,
  restaurantName,
  score,
  rank,
  fitLabel,
  explanation,
  confidenceLevel,
  tags = [],
  matchedSignals = [],
  penalizedSignals = [],
  scoreBreakdown = [],
  suggestedDishes = [],
  suggestedDrinks = [],
  activeEventMatches = [],
  ctaLabel = "View recommendation",
  onClick
}: RecommendationCardProps) {
  const [expanded, setExpanded] = useState(false);
  const scoreLabel = formatScore(score);
  const confidence = confidenceLabel(confidenceLevel);

  return (
    <Card
      className="recommendation-card"
      title={rank ? `#${rank} • ${title}` : title}
      subtitle={restaurantName || "Curated dining recommendation"}
      actions={
        <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
          {scoreLabel ? <Badge tone="success">{scoreLabel}</Badge> : <Badge>Match pending</Badge>}
          {fitLabel ? <Badge tone={fitTone(fitLabel)}>{fitLabel}</Badge> : null}
          {confidence ? <Badge tone={confidenceTone(confidenceLevel)}>{confidence}</Badge> : null}
        </div>
      }
    >
      <div className="grid" style={{ gap: "0.9rem" }}>
        <p className="muted" style={{ margin: 0 }}>
          {explanation || "A recommendation is ready, but no explanation was provided yet."}
        </p>

        {tags.length > 0 ? (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            {tags.map((tag) => (
              <Badge key={tag} tone="accent">
                {tag}
              </Badge>
            ))}
          </div>
        ) : (
          <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
            <Badge>Context-aware</Badge>
            <Badge tone="accent">Dining fit</Badge>
          </div>
        )}

        <div className="button-row" style={{ marginTop: 0 }}>
          <Button variant="ghost" onClick={() => setExpanded((prev) => !prev)}>
            {expanded ? "Hide scoring detail" : "Show scoring detail"}
          </Button>

          {onClick ? (
            <Button variant="ghost" onClick={onClick}>
              {ctaLabel}
            </Button>
          ) : null}
        </div>

        {expanded ? (
          <div className="grid" style={{ gap: "0.85rem" }}>
            {activeEventMatches.length > 0 ? (
              <div className="item">
                <strong>Event matches</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {activeEventMatches.map((eventMatch) => (
                    <Badge key={eventMatch} tone="accent">
                      {eventMatch}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {suggestedDishes.length > 0 ? (
              <div className="item">
                <strong>Suggested dishes</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {suggestedDishes.map((dish) => (
                    <Badge key={dish} tone="success">
                      {dish}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {suggestedDrinks.length > 0 ? (
              <div className="item">
                <strong>Suggested drinks</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {suggestedDrinks.map((drink) => (
                    <Badge key={drink} tone="accent">
                      {drink}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {matchedSignals.length > 0 ? (
              <div className="item">
                <strong>Matched signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {matchedSignals.map((signal) => (
                    <Badge key={signal} tone="success">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {penalizedSignals.length > 0 ? (
              <div className="item">
                <strong>Penalized signals</strong>
                <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap", marginTop: "0.55rem" }}>
                  {penalizedSignals.map((signal) => (
                    <Badge key={signal} tone="warning">
                      {signal}
                    </Badge>
                  ))}
                </div>
              </div>
            ) : null}

            {scoreBreakdown.length > 0 ? (
              <div className="item">
                <strong>Score breakdown</strong>
                <div style={{ display: "grid", gap: "0.45rem", marginTop: "0.6rem" }}>
                  {scoreBreakdown.map((entry) => (
                    <div
                      key={`${entry.label}-${entry.points}`}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        gap: "1rem",
                        padding: "0.55rem 0.7rem",
                        borderRadius: "0.75rem",
                        background: "rgba(15, 23, 42, 0.35)",
                        border: "1px solid rgba(148, 163, 184, 0.15)"
                      }}
                    >
                      <span>{entry.label}</span>
                      <strong>{formatBreakdownPoints(entry.points)}</strong>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>
    </Card>
  );
}
""")

if ".event-card-grid" not in styles:
    styles += """

.event-card-grid {
  display: grid;
  gap: 0.9rem;
}

.event-detail-card {
  padding: 0.95rem 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(15, 23, 42, 0.32);
}
"""
styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Running backend compile check..."
(
  cd "$BACKEND_DIR"
  if [ -f ".venv/bin/python" ]; then
    .venv/bin/python -m compileall app
  else
    python3 -m compileall app
  fi
)

echo
echo "Patch 4 applied successfully."
echo "Files changed:"
echo " - backend/app/services/recommendation_service.py"
echo " - frontend/src/pages/RestaurantDetailPage.tsx"
echo " - frontend/src/components/dining/RecommendationCard.tsx"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) run backend and frontend"
echo "2) open /restaurants/:restaurantId and confirm events render with status badges"
echo "3) test a venue with recurring or dated events"
echo "4) run recommendation flows that request live music or trivia"
echo "5) confirm results cards show event matches and dish/drink hints inside expanded detail"
echo "6) confirm no route or contract regressions"
