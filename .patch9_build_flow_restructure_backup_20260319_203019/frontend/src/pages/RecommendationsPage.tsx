import { useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";

const options = [
  {
    key: "build",
    title: "Build Your Night",
    badge: "Step-by-step",
    description:
      "Choose your vibe, pacing, budget, and preferences in a guided page with preset support.",
    path: "/recommendations/build",
    cta: "Open build flow"
  },
  {
    key: "describe",
    title: "Describe the Night",
    badge: "Natural language",
    description:
      "Write what kind of night you want, then go straight to a separate results page.",
    path: "/recommendations/describe",
    cta: "Open describe flow"
  },
  {
    key: "surprise",
    title: "Surprise Me",
    badge: "Fast path",
    description:
      "Minimal input, less friction, and a dedicated results page with only the recommendations.",
    path: "/recommendations/surprise",
    cta: "Open surprise flow"
  }
] as const;

export default function RecommendationsPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendation hub</p>
        <h1 className="page-title">Choose how you want to generate your night</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Start from one clear option, move into its own focused page, and view the output on a dedicated results screen.
        </p>
      </section>

      <section className="grid grid-3">
        {options.map((option) => (
          <Card
            key={option.key}
            title={option.title}
            subtitle={option.description}
            actions={<Badge tone="accent">{option.badge}</Badge>}
          >
            <div className="button-row">
              <Button onClick={() => navigate(option.path)} fullWidth>
                {option.cta}
              </Button>
            </div>
          </Card>
        ))}
      </section>
    </div>
  );
}
