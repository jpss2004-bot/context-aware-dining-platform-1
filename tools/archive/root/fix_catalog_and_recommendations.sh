#!/bin/bash
set -euo pipefail

echo "starting full catalog + recommendations fix..."

if [ ! -d "backend/app" ] || [ ! -d "frontend/src" ]; then
  echo "error: run this from the project root that contains backend/ and frontend/"
  exit 1
fi

mkdir -p backend/backups frontend/backups
timestamp=$(date +"%Y%m%d_%H%M%S")

if [ -f "backend/app/db/reset_and_seed_restaurants.py" ]; then
  cp "backend/app/db/reset_and_seed_restaurants.py" "backend/backups/reset_and_seed_restaurants.py.${timestamp}.bak"
fi

if [ -f "frontend/src/pages/RecommendationsPage.tsx" ]; then
  cp "frontend/src/pages/RecommendationsPage.tsx" "frontend/backups/RecommendationsPage.tsx.${timestamp}.bak"
fi

echo "writing canonical restaurant reset + reseed module..."

cat > backend/app/db/reset_and_seed_restaurants.py <<'PY'
from sqlalchemy import delete, func
from sqlalchemy.orm import Session

from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models.restaurant import (
    MenuItem,
    Restaurant,
    Tag,
    experience_menu_items,
    menu_item_tags,
    restaurant_tags,
)
from app.db.seed_real_wolfville import RESTAURANTS, upsert_restaurant


def reset_and_seed() -> None:
    init_db()
    db: Session = SessionLocal()

    try:
        print("clearing restaurant-related tables...")

        db.execute(delete(experience_menu_items))
        db.execute(delete(menu_item_tags))
        db.execute(delete(restaurant_tags))

        db.query(MenuItem).delete(synchronize_session=False)
        db.query(Restaurant).delete(synchronize_session=False)
        db.query(Tag).delete(synchronize_session=False)

        db.commit()

        print("seeding canonical wolfville catalog...")
        for item in RESTAURANTS:
            upsert_restaurant(db, item)

        db.commit()

        restaurant_count = db.query(Restaurant).count()
        menu_count = db.query(MenuItem).count()
        tag_count = db.query(Tag).count()

        duplicate_names = (
            db.query(Restaurant.name, func.count(Restaurant.id))
            .group_by(Restaurant.name)
            .having(func.count(Restaurant.id) > 1)
            .all()
        )

        print(f"seed complete: {restaurant_count} restaurants, {menu_count} menu items, {tag_count} tags")

        if duplicate_names:
            print("duplicate restaurant names still detected:")
            for name, count in duplicate_names:
                print(f" - {name}: {count}")
            raise RuntimeError("duplicate restaurant names remain after reseed")

        print("catalog is clean: no duplicate restaurant names found")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    reset_and_seed()
PY

echo "writing corrected frontend recommendations page..."

cat > frontend/src/pages/RecommendationsPage.tsx <<'TS'
import { FormEvent, useMemo, useState } from "react";

import RecommendationCard from "../components/dining/RecommendationCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RecommendationItem, RecommendationResponse } from "../types";

type Mode = "build" | "describe" | "surprise";

const modeMeta: Record<
  Mode,
  {
    eyebrow: string;
    title: string;
    subtitle: string;
    bullets: string[];
  }
> = {
  build: {
    eyebrow: "Structured mode",
    title: "Build Your Night",
    subtitle:
      "Guide the engine with structured context like outing type, pace, social setting, cuisine, and budget.",
    bullets: [
      "Uses the exact backend request shape.",
      "Best for controlled demos and predictable comparisons.",
      "Lets you tune the strongest recommendation signals."
    ]
  },
  describe: {
    eyebrow: "Prompt mode",
    title: "Describe Your Night",
    subtitle:
      "Write the kind of night you want in natural language and let the system interpret it.",
    bullets: [
      "Best when the vibe matters more than form fields.",
      "Feels closer to a real assistant experience.",
      "Useful for testing natural-language intent parsing."
    ]
  },
  surprise: {
    eyebrow: "Exploration mode",
    title: "Surprise Me",
    subtitle:
      "Get recommendations quickly with minimal friction.",
    bullets: [
      "Fastest path to discovery.",
      "Uses your saved preferences when available.",
      "Good for novelty and low-effort browsing."
    ]
  }
};

function splitList(value: string): string[] {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function emptyToNull(value: string): string | null {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeScore(score?: number): number | undefined {
  if (typeof score !== "number" || Number.isNaN(score)) {
    return undefined;
  }

  return Math.max(0, Math.min(score / 10, 1));
}

function normalizeRecommendation(item: RecommendationItem, index: number) {
  const reasons = item.reasons ?? [];
  const suggestedDishes = item.suggested_dishes ?? [];
  const suggestedDrinks = item.suggested_drinks ?? [];

  const tagValues = [
    ...suggestedDishes.map((dish) => `dish: ${dish}`),
    ...suggestedDrinks.map((drink) => `drink: ${drink}`)
  ].slice(0, 4);

  return {
    id: item.restaurant_id ?? index,
    title: item.restaurant_name ?? `Recommendation ${index + 1}`,
    restaurantName: item.restaurant_name,
    explanation:
      reasons.length > 0
        ? reasons.join(" • ")
        : "This restaurant matched your current dining request.",
    score: normalizeScore(item.score),
    tags: tagValues
  };
}

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [results, setResults] = useState<RecommendationItem[]>([]);

  const [buildForm, setBuildForm] = useState({
    outing_type: "",
    mood: "",
    budget: "",
    pace: "",
    social_context: "",
    preferred_cuisines: "",
    atmosphere: "",
    drinks_focus: false
  });

  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);

  const activeMeta = modeMeta[mode];

  const normalizedResults = useMemo(
    () => results.map((item, index) => normalizeRecommendation(item, index)),
    [results]
  );

  async function runRequest(endpoint: string, payload: Record<string, unknown>) {
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const data = await apiRequest<RecommendationResponse>(endpoint, {
        method: "POST",
        body: payload
      });

      const recs = Array.isArray(data.results) ? data.results : [];

      setResults(recs);
      setSuccess(
        recs.length > 0
          ? `Generated ${recs.length} recommendation${recs.length === 1 ? "" : "s"}.`
          : "Request completed, but no recommendations were returned."
      );
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Failed to generate recommendations.";
      setError(message);
      setResults([]);
    } finally {
      setLoading(false);
    }
  }

  async function handleBuildSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest("/recommendations/build-your-night", {
      outing_type: buildForm.outing_type.trim() || "casual night out",
      mood: emptyToNull(buildForm.mood),
      budget: emptyToNull(buildForm.budget),
      pace: emptyToNull(buildForm.pace),
      social_context: emptyToNull(buildForm.social_context),
      preferred_cuisines: splitList(buildForm.preferred_cuisines),
      drinks_focus: buildForm.drinks_focus,
      atmosphere: splitList(buildForm.atmosphere)
    });
  }

  async function handleDescribeSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest("/recommendations/describe-your-night", {
      prompt: describeText.trim()
    });
  }

  async function handleSurprise() {
    await runRequest("/recommendations/surprise-me", {
      include_drinks: includeDrinks
    });
  }

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendation studio</p>
        <h1 className="page-title">Generate a better dining fit</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Choose the mode that best matches your decision style. Structured inputs
          give you tighter control, prompt mode feels more conversational, and
          surprise mode is the fastest path to discovery.
        </p>
      </section>

      <section className="grid grid-3">
        <button
          type="button"
          className={mode === "build" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("build")}
        >
          <p className="navbar-eyebrow">Structured</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Build Your Night
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want more control over the recommendation signals.
          </p>
        </button>

        <button
          type="button"
          className={mode === "describe" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("describe")}
        >
          <p className="navbar-eyebrow">Natural language</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Describe Your Night
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want to describe the vibe in your own words.
          </p>
        </button>

        <button
          type="button"
          className={mode === "surprise" ? "card recommendation-mode-card active" : "card recommendation-mode-card"}
          onClick={() => setMode("surprise")}
        >
          <p className="navbar-eyebrow">Fast path</p>
          <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>
            Surprise Me
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want novelty with almost no effort.
          </p>
        </button>
      </section>

      <section className="grid grid-2">
        <Card
          title={activeMeta.title}
          subtitle={activeMeta.subtitle}
          actions={<Badge tone="accent">{activeMeta.eyebrow}</Badge>}
        >
          <div className="item">
            <strong>When to use this mode</strong>
            <ul className="muted" style={{ marginBottom: 0 }}>
              {activeMeta.bullets.map((bullet) => (
                <li key={bullet} style={{ marginBottom: "0.4rem" }}>
                  {bullet}
                </li>
              ))}
            </ul>
          </div>

          {error ? <div className="error">{error}</div> : null}
          {success ? <div className="success">{success}</div> : null}

          {mode === "build" ? (
            <form className="form" onSubmit={handleBuildSubmit}>
              <div className="grid grid-2">
                <div className="form-row">
                  <label htmlFor="outing_type">Outing type</label>
                  <input
                    id="outing_type"
                    value={buildForm.outing_type}
                    onChange={(e) =>
                      setBuildForm((prev) => ({ ...prev, outing_type: e.target.value }))
                    }
                    placeholder="Date night, group dinner, casual bite..."
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="mood">Mood</label>
                  <input
                    id="mood"
                    value={buildForm.mood}
                    onChange={(e) =>
                      setBuildForm((prev) => ({ ...prev, mood: e.target.value }))
                    }
                    placeholder="Cozy, energetic, celebratory..."
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="budget">Budget</label>
                  <input
                    id="budget"
                    value={buildForm.budget}
                    onChange={(e) =>
                      setBuildForm((prev) => ({ ...prev, budget: e.target.value }))
                    }
                    placeholder="$, $$, $$$"
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="pace">Pace</label>
                  <input
                    id="pace"
                    value={buildForm.pace}
                    onChange={(e) =>
                      setBuildForm((prev) => ({ ...prev, pace: e.target.value }))
                    }
                    placeholder="fast, moderate, leisurely, slow"
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="social_context">Social context</label>
                  <input
                    id="social_context"
                    value={buildForm.social_context}
                    onChange={(e) =>
                      setBuildForm((prev) => ({
                        ...prev,
                        social_context: e.target.value
                      }))
                    }
                    placeholder="solo, friends, group, date"
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="preferred_cuisines">Preferred cuisines</label>
                  <input
                    id="preferred_cuisines"
                    value={buildForm.preferred_cuisines}
                    onChange={(e) =>
                      setBuildForm((prev) => ({
                        ...prev,
                        preferred_cuisines: e.target.value
                      }))
                    }
                    placeholder="pizza, mediterranean, coffee, beer"
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="atmosphere">Atmosphere</label>
                  <input
                    id="atmosphere"
                    value={buildForm.atmosphere}
                    onChange={(e) =>
                      setBuildForm((prev) => ({
                        ...prev,
                        atmosphere: e.target.value
                      }))
                    }
                    placeholder="cozy, lively, quiet, romantic"
                  />
                </div>

                <div className="form-row">
                  <label htmlFor="drinks_focus">Drink-focused outing</label>
                  <input
                    id="drinks_focus"
                    type="checkbox"
                    checked={buildForm.drinks_focus}
                    onChange={(e) =>
                      setBuildForm((prev) => ({
                        ...prev,
                        drinks_focus: e.target.checked
                      }))
                    }
                  />
                </div>
              </div>

              <div className="button-row">
                <Button type="submit" disabled={loading}>
                  {loading ? "Generating..." : "Generate recommendations"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "describe" ? (
            <form className="form" onSubmit={handleDescribeSubmit}>
              <div className="form-row">
                <label htmlFor="describe_prompt">Describe the night you want</label>
                <textarea
                  id="describe_prompt"
                  value={describeText}
                  onChange={(e) => setDescribeText(e.target.value)}
                  placeholder="I want a cozy dinner spot with good drinks, relaxed pacing, and food that feels memorable without being too formal..."
                />
              </div>

              <div className="button-row">
                <Button type="submit" disabled={loading || describeText.trim().length < 3}>
                  {loading ? "Interpreting..." : "Interpret and recommend"}
                </Button>
              </div>
            </form>
          ) : null}

          {mode === "surprise" ? (
            <div className="form">
              <div className="item">
                <strong>Low-friction discovery</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  This mode sends a minimal valid backend payload and uses your saved
                  onboarding preferences when available.
                </p>
              </div>

              <div className="form-row">
                <label htmlFor="include_drinks">Include drinks</label>
                <input
                  id="include_drinks"
                  type="checkbox"
                  checked={includeDrinks}
                  onChange={(e) => setIncludeDrinks(e.target.checked)}
                />
              </div>

              <div className="button-row">
                <Button onClick={handleSurprise} disabled={loading}>
                  {loading ? "Finding a surprise..." : "Surprise me"}
                </Button>
              </div>
            </div>
          ) : null}
        </Card>

        <Card
          title="Recommendation output"
          subtitle="Curated results from the active mode"
          actions={
            normalizedResults.length > 0 ? (
              <Badge tone="success">
                {normalizedResults.length} result{normalizedResults.length === 1 ? "" : "s"}
              </Badge>
            ) : (
              <Badge>Waiting</Badge>
            )
          }
        >
          {normalizedResults.length === 0 ? (
            <div className="list">
              <div className="item">
                <strong>No recommendations yet</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Run one of the recommendation modes to populate this panel with
                  curated dining suggestions.
                </p>
              </div>

              <div className="item">
                <strong>Best next move</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  Try Build Your Night first, then compare it to Describe Your Night
                  to validate both structured and natural-language flows.
                </p>
              </div>
            </div>
          ) : (
            <div className="list">
              {normalizedResults.map((item) => (
                <RecommendationCard
                  key={item.id}
                  title={item.title}
                  restaurantName={item.restaurantName}
                  score={item.score}
                  explanation={item.explanation}
                  tags={item.tags}
                />
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
TS

echo "running backend catalog reset + reseed..."

if [ -x "backend/.venv/bin/python" ]; then
  (
    cd backend
    .venv/bin/python -m app.db.reset_and_seed_restaurants
  )
else
  (
    cd backend
    python3 -m app.db.reset_and_seed_restaurants
  )
fi

echo "building frontend to verify patch..."

(
  cd frontend
  npm run build
)

echo ""
echo "fix complete"
echo ""
echo "next:"
echo "1. restart backend:  cd backend && uvicorn app.main:app --reload"
echo "2. restart frontend: cd frontend && npm run dev"
echo "3. open the app and test the recommendations page again"
