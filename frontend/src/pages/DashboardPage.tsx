import { Link } from 'react-router-dom';

import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { useAuth } from '../context/AuthContext';

const workflowSteps = [
  {
    title: 'Refine your Taste Profile',
    description:
      'Keep cuisine, drink, atmosphere, and pace signals current so SAVR can curate stronger matches.'
  },
  {
    title: 'Browse the Venue Guide',
    description:
      'Review the restaurant catalog, compare venue signals, and understand what the engine can recommend.'
  },
  {
    title: 'Launch Curated Matches',
    description:
      'Use guided blocks, natural language, or surprise mode depending on how much control you want.'
  }
];

const quickPanels = [
  {
    title: 'Match modes',
    value: '3',
    subtitle: 'Guided, prompt-based, and surprise flows remain fully available.',
    tone: 'accent' as const
  },
  {
    title: 'Taste profile',
    value: 'Live',
    subtitle: 'Your onboarding data still powers the recommendation engine.',
    tone: 'success' as const
  },
  {
    title: 'SAVR Log',
    value: 'Active',
    subtitle: 'Saved outings keep building memory for future recommendations.',
    tone: 'default' as const
  }
];

export default function DashboardPage() {
  const { user } = useAuth();
  const firstName = user?.first_name || 'Guest';

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="hero-card">
        <div className="grid" style={{ gap: '1rem' }}>
          <div>
            <p className="navbar-eyebrow">SAVR overview</p>
            <h1 className="page-title">Good evening, {firstName}</h1>
            <p className="muted" style={{ maxWidth: '760px', marginBottom: 0 }}>
              SAVR is your dining assistant for planning nights worth savoring. From taste signals to venue research to saved outings, every workflow stays intact — now with a clearer, warmer interface.
            </p>
          </div>

          <div>
            <Badge>Curated discovery</Badge>
            <Badge tone="accent">Brand-aligned shell</Badge>
            <Badge tone="success">Backend connected</Badge>
          </div>

          <div className="button-row">
            <Link to="/recommendations">
              <Button>Open Curated Matches</Button>
            </Link>
            <Link to="/restaurants">
              <Button variant="ghost">Browse Venue Guide</Button>
            </Link>
            <Link to="/onboarding">
              <Button variant="secondary">Refine Taste Profile</Button>
            </Link>
          </div>
        </div>
      </section>

      <section className="grid grid-3">
        {quickPanels.map((panel) => (
          <Card key={panel.title} title={panel.title} subtitle={panel.subtitle} actions={<Badge tone={panel.tone}>{panel.title}</Badge>}>
            <p className="kpi">{panel.value}</p>
          </Card>
        ))}
      </section>

      <section className="grid grid-2">
        <Card title="Tonight's best flow" subtitle="A clean path through the product" actions={<Badge tone="accent">Suggested</Badge>}>
          <div className="list">
            {workflowSteps.map((step, index) => (
              <div className="item" key={step.title}>
                <p className="navbar-eyebrow" style={{ marginBottom: '0.35rem' }}>
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

        <Card title="What changed visually" subtitle="Same product, sharper presentation" actions={<Badge tone="success">SAVR refresh</Badge>}>
          <div className="list">
            <div className="item">
              <strong>Warmer hierarchy</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                The interface now reflects the premium, discovery-led tone from the SAVR mood board instead of a generic SaaS skin.
              </p>
            </div>
            <div className="item">
              <strong>Clearer navigation</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Feature areas are grouped around what the user wants to do: define taste, browse venues, generate matches, and save memories.
              </p>
            </div>
            <div className="item">
              <strong>More intuitive language</strong>
              <p className="muted" style={{ marginBottom: 0 }}>
                Placeholder product labels were replaced with SAVR-specific language that feels more curated and experiential.
              </p>
            </div>
          </div>

          <hr />

          <div className="button-row">
            <Link to="/experiences">
              <Button variant="ghost">Open SAVR Log</Button>
            </Link>
            <Link to="/recommendations">
              <Button>Generate curated matches</Button>
            </Link>
          </div>
        </Card>
      </section>
    </div>
  );
}
