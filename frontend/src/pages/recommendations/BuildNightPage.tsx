import { useNavigate } from "react-router-dom";

import Badge from "../../components/ui/Badge";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";

export default function BuildNightPage() {
  const navigate = useNavigate();

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Build a night</p>
        <h1 className="page-title">How do you want to start?</h1>
        <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
          Either start from an existing preset or build your night step by step. Both paths end with recommendation results.
        </p>
      </section>

      <section className="grid grid-2">
        <Card
          title="Select a preset"
          subtitle="Browse available presets, apply one, and generate recommendations quickly"
          actions={<Badge tone="accent">Preset path</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Best when</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You already know a reusable dining pattern and want fast results.
              </p>
            </div>
          </div>
          <div className="button-row" style={{ marginTop: "1rem" }}>
            <Button onClick={() => navigate("/recommendations/build/presets")}>
              Select a preset
            </Button>
          </div>
        </Card>

        <Card
          title="Build your own night"
          subtitle="Move through a guided step-by-step builder, then save it as a preset if you want"
          actions={<Badge tone="success">Guided flow</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Best when</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                You want to create a fresh configuration block by block before generating recommendations.
              </p>
            </div>
          </div>
          <div className="button-row" style={{ marginTop: "1rem" }}>
            <Button onClick={() => navigate("/recommendations/build/guide")}>
              Build your own night
            </Button>
          </div>
        </Card>
      </section>
    </div>
  );
}
