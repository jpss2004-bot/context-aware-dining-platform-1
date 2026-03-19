import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import ExperienceCard from "../components/dining/ExperienceCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { Experience } from "../types";

export default function ExperiencesPage() {
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadExperiences() {
      try {
        setError("");
        setLoading(true);
        const experienceData = await apiRequest<Experience[]>("/experiences");
        if (!cancelled) {
          setExperiences(experienceData);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load your SAVR history.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadExperiences();

    return () => {
      cancelled = true;
    };
  }, []);

  const summary = useMemo(() => {
    const total = experiences.length;
    const rated = experiences.filter((experience) => experience.overall_rating !== null);
    const average =
      rated.length > 0
        ? (
            rated.reduce((sum, experience) => sum + (experience.overall_rating ?? 0), 0) /
            rated.length
          ).toFixed(1)
        : "—";

    return {
      total,
      rated: rated.length,
      average
    };
  }, [experiences]);

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Experiences</p>
        <h1 className="page-title">Your dining history</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Review your saved outings, track what worked, and continue building a stronger dining memory for SAVR.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-3">
        <Card
          title="Saved entries"
          subtitle="Total number of dining experiences currently stored"
          actions={<Badge tone="accent">History</Badge>}
        >
          <p className="kpi">{summary.total}</p>
        </Card>

        <Card
          title="Rated entries"
          subtitle="Experiences that include an overall score"
          actions={<Badge tone="success">Ratings</Badge>}
        >
          <p className="kpi">{summary.rated}</p>
        </Card>

        <Card
          title="Average rating"
          subtitle="Average score across rated experiences"
          actions={<Badge>Average</Badge>}
        >
          <p className="kpi">{summary.average}</p>
        </Card>
      </section>

      <div className="button-row">
        <Link to="/experiences/new">
          <Button>Log a new experience</Button>
        </Link>
        <Link to="/recommendations">
          <Button variant="ghost">Go to recommendations</Button>
        </Link>
      </div>

      <Card
        title="Saved dining memories"
        subtitle="Browse your saved entries in one place"
        actions={<Badge>{experiences.length} entries</Badge>}
      >
        {loading ? (
          <div className="item">
            <strong>Loading your dining history</strong>
            <p className="muted" style={{ marginBottom: 0 }}>
              Pulling your saved experiences from the backend.
            </p>
          </div>
        ) : experiences.length === 0 ? (
          <div className="item">
            <strong>No experiences saved yet</strong>
            <p className="muted" style={{ marginBottom: "1rem" }}>
              Start by logging your first restaurant visit so SAVR can begin learning from your real dining outcomes.
            </p>
            <Link to="/experiences/new">
              <Button>Log your first experience</Button>
            </Link>
          </div>
        ) : (
          <div className="grid grid-2">
            {experiences.map((experience) => (
              <ExperienceCard key={experience.id} experience={experience} />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
