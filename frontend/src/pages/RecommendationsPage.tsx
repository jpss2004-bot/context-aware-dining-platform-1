import { FormEvent, useState } from "react";

import { apiRequest } from "../lib/api";
import { RecommendationResponse } from "../types";

function parseList(value: string): string[] {
  return value.split(",").map((item) => item.trim()).filter(Boolean);
}

export default function RecommendationsPage() {
  const [error, setError] = useState("");
  const [result, setResult] = useState<RecommendationResponse | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const [buildForm, setBuildForm] = useState({
    outing_type: "romantic dinner",
    mood: "cozy",
    budget: "$$",
    pace: "leisurely",
    social_context: "romantic",
    preferred_cuisines: "italian, comfort-food",
    drinks_focus: true,
    atmosphere: "cozy, romantic"
  });

  const [describePrompt, setDescribePrompt] = useState(
    "I want a cozy romantic dinner with pasta and drinks."
  );

  async function runBuild(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const response = await apiRequest<RecommendationResponse>("/recommendations/build-your-night", {
        method: "POST",
        body: {
          outing_type: buildForm.outing_type,
          mood: buildForm.mood,
          budget: buildForm.budget,
          pace: buildForm.pace,
          social_context: buildForm.social_context,
          preferred_cuisines: parseList(buildForm.preferred_cuisines),
          drinks_focus: buildForm.drinks_focus,
          atmosphere: parseList(buildForm.atmosphere)
        }
      });
      setResult(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get recommendations");
    } finally {
      setIsLoading(false);
    }
  }

  async function runDescribe(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const response = await apiRequest<RecommendationResponse>("/recommendations/describe-your-night", {
        method: "POST",
        body: {
          prompt: describePrompt
        }
      });
      setResult(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get recommendations");
    } finally {
      setIsLoading(false);
    }
  }

  async function runSurprise() {
    setError("");
    setIsLoading(true);

    try {
      const response = await apiRequest<RecommendationResponse>("/recommendations/surprise-me", {
        method: "POST",
        body: {
          include_drinks: true
        }
      });
      setResult(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get recommendations");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Recommendations</h1>
        <p className="muted">Use the same backend recommendation routes you already verified in Swagger.</p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <div className="card">
          <h2>Build Your Night</h2>
          <form className="form" onSubmit={runBuild}>
            <div className="form-row">
              <label>Outing type</label>
              <input
                value={buildForm.outing_type}
                onChange={(e) => setBuildForm({ ...buildForm, outing_type: e.target.value })}
              />
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label>Mood</label>
                <input
                  value={buildForm.mood}
                  onChange={(e) => setBuildForm({ ...buildForm, mood: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Budget</label>
                <input
                  value={buildForm.budget}
                  onChange={(e) => setBuildForm({ ...buildForm, budget: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Pace</label>
                <input
                  value={buildForm.pace}
                  onChange={(e) => setBuildForm({ ...buildForm, pace: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Social context</label>
                <input
                  value={buildForm.social_context}
                  onChange={(e) => setBuildForm({ ...buildForm, social_context: e.target.value })}
                />
              </div>
            </div>

            <div className="form-row">
              <label>Preferred cuisines</label>
              <input
                value={buildForm.preferred_cuisines}
                onChange={(e) => setBuildForm({ ...buildForm, preferred_cuisines: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Atmosphere</label>
              <input
                value={buildForm.atmosphere}
                onChange={(e) => setBuildForm({ ...buildForm, atmosphere: e.target.value })}
              />
            </div>

            <label>
              <input
                checked={buildForm.drinks_focus}
                onChange={(e) => setBuildForm({ ...buildForm, drinks_focus: e.target.checked })}
                type="checkbox"
              />{" "}
              Drinks focus
            </label>

            <button className="button" disabled={isLoading} type="submit">
              {isLoading ? "Loading..." : "Run build-your-night"}
            </button>
          </form>
        </div>

        <div className="card">
          <h2>Describe Your Night</h2>
          <form className="form" onSubmit={runDescribe}>
            <div className="form-row">
              <label>Prompt</label>
              <textarea value={describePrompt} onChange={(e) => setDescribePrompt(e.target.value)} />
            </div>

            <button className="button secondary" disabled={isLoading} type="submit">
              {isLoading ? "Loading..." : "Run describe-your-night"}
            </button>
          </form>

          <hr />

          <h2>Surprise Me</h2>
          <p className="muted">Use saved onboarding preferences plus experience history.</p>
          <button className="button ghost" disabled={isLoading} onClick={runSurprise} type="button">
            {isLoading ? "Loading..." : "Run surprise-me"}
          </button>
        </div>
      </section>

      {result ? (
        <section className="card">
          <h2>Recommendation results</h2>
          <div className="list">
            {result.results.map((item) => (
              <div className="item" key={`${result.mode}-${item.restaurant_id}`}>
                <h3>
                  {item.restaurant_name} — score {item.score}
                </h3>

                <div>
                  {item.reasons.map((reason) => (
                    <span className="pill" key={reason}>
                      {reason}
                    </span>
                  ))}
                </div>

                {item.suggested_dishes.length ? (
                  <p>
                    <strong>Dishes:</strong> {item.suggested_dishes.join(", ")}
                  </p>
                ) : null}

                {item.suggested_drinks.length ? (
                  <p>
                    <strong>Drinks:</strong> {item.suggested_drinks.join(", ")}
                  </p>
                ) : null}
              </div>
            ))}
          </div>
        </section>
      ) : null}
    </>
  );
}
