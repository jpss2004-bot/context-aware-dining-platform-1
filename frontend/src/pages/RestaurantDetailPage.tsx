import { useEffect, useMemo, useState } from "react";
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
