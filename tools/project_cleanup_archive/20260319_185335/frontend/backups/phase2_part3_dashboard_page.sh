#!/bin/zsh
set -e

echo "writing DashboardPage..."

cat > src/pages/DashboardPage.tsx <<'EOF'
import { Link } from "react-router-dom";

import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import Badge from "../components/ui/Badge";
import { useAuth } from "../context/AuthContext";

export default function DashboardPage() {
  const { user } = useAuth();

  const firstName = user?.first_name || "Guest";

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <p className="navbar-eyebrow">Overview</p>
        <h1 className="page-title">Welcome back, {firstName}</h1>
        <p className="muted" style={{ maxWidth: "760px" }}>
          This is your dining recommendation control center. Jump into onboarding,
          explore restaurants, review saved experiences, or generate a new
          recommendation with a cleaner, more product-like workflow.
        </p>

        <div className="button-row" style={{ marginTop: "1rem" }}>
          <Link to="/recommendations">
            <Button>Open recommendation studio</Button>
          </Link>
          <Link to="/restaurants">
            <Button variant="ghost">Browse restaurants</Button>
          </Link>
          <Link to="/experiences">
            <Button variant="secondary">View experiences</Button>
          </Link>
        </div>
      </section>

      <section className="grid grid-3">
        <Card title="Recommendation modes" subtitle="Core product actions">
          <p className="kpi">3</p>
          <p className="muted">
            Build Your Night, Describe Your Night, and Surprise Me are ready from
            one workspace.
          </p>
        </Card>

        <Card title="Profile signals" subtitle="Taste capture status">
          <p className="kpi">Active</p>
          <p className="muted">
            Keep onboarding updated so the platform can generate stronger
            restaurant matches.
          </p>
        </Card>

        <Card title="Experience memory" subtitle="Feedback loop">
          <p className="kpi">Live</p>
          <p className="muted">
            Past dining experiences can strengthen future recommendations and make
            results feel more personal.
          </p>
        </Card>
      </section>

      <section className="grid grid-2">
        <Card
          title="Quick launch"
          subtitle="Start from the flow that matches your intent"
        >
          <div>
            <Badge>Discovery</Badge>
            <Badge tone="accent">Personalization</Badge>
            <Badge tone="success">Recommendation quality</Badge>
          </div>

          <div className="list">
            <div className="item">
              <strong>Onboarding</strong>
              <p className="muted">
                Update taste, pace, drink, budget, and atmosphere signals.
              </p>
            </div>

            <div className="item">
              <strong>Restaurants</strong>
              <p className="muted">
                Explore the available venues and inspect their attributes before
                generating recommendations.
              </p>
            </div>

            <div className="item">
              <strong>Recommendations</strong>
              <p className="muted">
                Run the main product flow and get curated suggestions with better
                visual presentation.
              </p>
            </div>
          </div>
        </Card>

        <Card
          title="Best workflow"
          subtitle="Suggested path for demo and development"
        >
          <ol className="muted" style={{ margin: 0, paddingLeft: "1.2rem" }}>
            <li style={{ marginBottom: "0.6rem" }}>
              Complete onboarding so profile inputs are fresh.
            </li>
            <li style={{ marginBottom: "0.6rem" }}>
              Review restaurants and experience history for better context.
            </li>
            <li>
              Open recommendations and run the mode that best matches the night you
              want to create.
            </li>
          </ol>

          <hr />

          <div className="button-row">
            <Link to="/onboarding">
              <Button variant="ghost">Update onboarding</Button>
            </Link>
            <Link to="/recommendations">
              <Button>Generate recommendations</Button>
            </Link>
          </div>
        </Card>
      </section>
    </div>
  );
}
EOF

echo "DashboardPage written"
