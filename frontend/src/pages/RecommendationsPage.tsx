import { useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";

export default function RecommendationsPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Recommendations</p>
        <h1 className="page-title">Choose how you want to generate recommendations</h1>
        <p className="muted" style={{ maxWidth: "780px", marginBottom: 0 }}>
          Start from a guided builder, natural language, or a surprise flow. The build path now has its own dedicated branching flow.
        </p>
      </section>

      <section className="grid grid-3">
        <Card
          title="Build a Night"
          subtitle="Choose a preset or go step by step to build your own night"
          actions={<Badge tone="accent">Structured</Badge>}
        >
          <div className="button-row">
            <Button onClick={() => navigate("/recommendations/build")}>Open build flow</Button>
          </div>
        </Card>

        <Card
          title="Describe the Night"
          subtitle="Use natural language to explain what kind of outing you want"
          actions={<Badge tone="success">Prompt-based</Badge>}
        >
          <div className="button-row">
            <Button onClick={() => navigate("/recommendations/describe")}>Describe a night</Button>
          </div>
        </Card>

        <Card
          title="Surprise Me"
          subtitle="Get recommendations quickly with very little input"
          actions={<Badge>Fastest</Badge>}
        >
          <div className="button-row">
            <Button onClick={() => navigate("/recommendations/surprise")}>Start surprise flow</Button>
          </div>
        </Card>
      </section>
    </div>
  );
}
