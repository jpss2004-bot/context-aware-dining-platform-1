import { Link } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { useAuth } from "../context/AuthContext";

const workflowSteps = [
  {
    title: "Refresh onboarding",
    description:
      "Keep cuisine, drink, atmosphere, and pace signals current so the engine has stronger preference context."
  },
  {
    title: "Review restaurants",
    description:
      "Inspect the seeded catalog and understand the venues the backend can draw from when creating recommendations."
  },
  {
    title: "Run recommendation modes",
    description:
      "Use structured, prompt-based, or surprise flows depending on how much control you want over the result."
  }
];

const quickPanels = [
  {
    title: "Recommendation modes",
    value: "3",
    subtitle: "Structured, prompt-based, and surprise flows ready to demo.",
    tone: "accent" as const
  },
  {
    title: "Profile readiness",
    value: "Live",
    subtitle: "Onboarding remains the signal backbone behind better recommendation quality.",
    tone: "success" as const
  },
  {
    title: "Experience memory",
    value: "Active",
    subtitle: "Saved dining logs can reinforce future personalization.",
    tone: "default" as const
  }
];

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || "Guest";

  return (
    <div className="grid" style={{ gap: "1.25rem" }}>
      <section className="card">
        <div className="grid" style={{ gap: "1rem" }}>
          <div>
            <p className="navbar-eyebrow">Product overview</p>
            <h1 className="page-title">Welcome back, {firstName}</h1>
            <p className="muted" style={{ maxWidth: "760px", marginBottom: 0 }}>
              Your dining platform now has a stronger shell, clearer workflows, and
              a more product-like recommendation surface. Use this page as the
              control center for demos, testing, and iteration.
            </p>
          </div>

          <div>
            <Badge>Premium shell</Badge>
            <Badge tone="accent">Recommendation-led UX</Badge>
            <Badge tone="success">Backend connected</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Open recommendation studio</Button>
            </Link>
            <Link to="/restaurants">
              <Button variant="ghost">Browse restaurants</Button>
            </Link>
            <Link to="/onboarding">
              <Button variant="secondary">Update onboarding</Button>
            </Link>
          </div>
        </div>
      </section>

      <section className="grid grid-3">
        {quickPanels.map((panel) => (
          <Card
            key={panel.title}
            title={panel.title}
            subtitle={panel.subtitle}
            actions={<Badge tone={panel.tone}>{panel.title}</Badge>}
          >
            <p className="kpi">{panel.value}</p>
          </Card>
        ))}
      </section>

      <section className="grid grid-2">
        <Card
          title="Recommended workflow"
          subtitle="Best path for demos and end-to-end testing"
          actions={<Badge tone="accent">Suggested</Badge>}
        >
          <div className="list">
            {workflowSteps.map((step, index) => (
              <div className="item" key={step.title}>
                <p className="navbar-eyebrow" style={{ marginBottom: "0.35rem" }}>
                  Step {index + 1}
                </p>
                <strong>{step.title}</strong>
                <p className="muted" style={{ marginBottom: 0 }}>
                  {step.description}
                </p>
              </div>
            ))}
          </div>
        </Card>

        <Card
          title="What improved"
          subtitle="UI gains from the current iteration"
          actions={<Badge tone="success">Phase 4</Badge>}
        >
          <div className="list">
            <div className="item">
              <strong>Cleaner shell</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                The sidebar, navbar, spacing, and cards now feel closer to a real
                SaaS product than a class prototype.
              </p>
            </div>

            <div className="item">
              <strong>Better recommendation surface</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                The recommendation workspace is more structured, readable, and ready
                for stronger outputs.
              </p>
            </div>

            <div className="item">
              <strong>Stronger visual system</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Shared components now support richer polish across onboarding,
                restaurants, experiences, login, and register pages.
              </p>
            </div>
          </div>

          <hr />

          <div className="button-row">
            <Link to="/experiences">
              <Button variant="ghost">Review experiences</Button>
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
