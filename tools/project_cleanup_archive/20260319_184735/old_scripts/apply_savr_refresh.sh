#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT_DIR/.savr_backup_$TIMESTAMP"

if [[ ! -d "$FRONTEND_DIR" ]]; then
  echo 'Error: frontend directory not found. Run this from the context-aware-dining-platform root folder.' >&2
  exit 1
fi

if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
  echo 'Error: frontend/package.json not found. Wrong folder.' >&2
  exit 1
fi

if [[ ! -f "$FRONTEND_DIR/src/App.tsx" ]]; then
  echo 'Error: frontend/src/App.tsx not found. Wrong frontend structure.' >&2
  exit 1
fi

echo 'Creating backup at:' "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

mkdir -p "$BACKUP_DIR/src/config"
if [[ -f "$FRONTEND_DIR/src/config/content.ts" ]]; then cp "$FRONTEND_DIR/src/config/content.ts" "$BACKUP_DIR/src/config/content.ts"; fi
mkdir -p "$BACKUP_DIR/src/config"
if [[ -f "$FRONTEND_DIR/src/config/designTokens.ts" ]]; then cp "$FRONTEND_DIR/src/config/designTokens.ts" "$BACKUP_DIR/src/config/designTokens.ts"; fi
mkdir -p "$BACKUP_DIR/src/components/navigation"
if [[ -f "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" ]]; then cp "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" "$BACKUP_DIR/src/components/navigation/Navbar.tsx"; fi
mkdir -p "$BACKUP_DIR/src/components/navigation"
if [[ -f "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" ]]; then cp "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" "$BACKUP_DIR/src/components/navigation/Sidebar.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/DashboardPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/DashboardPage.tsx" "$BACKUP_DIR/src/pages/DashboardPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/ExperiencesPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/ExperiencesPage.tsx" "$BACKUP_DIR/src/pages/ExperiencesPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/LoginPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/LoginPage.tsx" "$BACKUP_DIR/src/pages/LoginPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/OnboardingPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/OnboardingPage.tsx" "$BACKUP_DIR/src/pages/OnboardingPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx" "$BACKUP_DIR/src/pages/RecommendationsPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/RegisterPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/RegisterPage.tsx" "$BACKUP_DIR/src/pages/RegisterPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src/pages"
if [[ -f "$FRONTEND_DIR/src/pages/RestaurantsPage.tsx" ]]; then cp "$FRONTEND_DIR/src/pages/RestaurantsPage.tsx" "$BACKUP_DIR/src/pages/RestaurantsPage.tsx"; fi
mkdir -p "$BACKUP_DIR/src"
if [[ -f "$FRONTEND_DIR/src/styles.css" ]]; then cp "$FRONTEND_DIR/src/styles.css" "$BACKUP_DIR/src/styles.css"; fi

mkdir -p "$FRONTEND_DIR/src/config"
cat > "$FRONTEND_DIR/src/config/content.ts" <<'EOF_src_config_content_ts'
export const brandContent = {
  productName: 'SAVR',
  tagline: 'Savor Every Experience',
  strapline: 'Context-aware dining, curated for the night you want.',
  nav: [
    { to: '/dashboard', label: 'Home', short: 'HM' },
    { to: '/onboarding', label: 'Taste Profile', short: 'TP' },
    { to: '/recommendations', label: 'Curated Matches', short: 'CM' },
    { to: '/restaurants', label: 'Venue Guide', short: 'VG' },
    { to: '/experiences', label: 'SAVR Log', short: 'SL' }
  ],
  routeMeta: {
    '/dashboard': {
      eyebrow: 'Home',
      title: 'Your SAVR command table',
      subtitle: 'See what is ready, refresh your taste profile, and launch curated matches without losing any existing workflows.'
    },
    '/onboarding': {
      eyebrow: 'Taste Profile',
      title: 'Teach SAVR your taste',
      subtitle: 'Capture cuisines, pace, atmosphere, and drink preferences so every curated match feels more intentional.'
    },
    '/recommendations': {
      eyebrow: 'Curated Matches',
      title: 'Build the night worth savoring',
      subtitle: 'Use guided blocks, natural language, or surprise mode to surface restaurants that fit the exact experience you want.'
    },
    '/restaurants': {
      eyebrow: 'Venue Guide',
      title: 'Browse the SAVR venue guide',
      subtitle: 'Compare restaurants, menu signals, atmosphere, and pace in one clear research surface.'
    },
    '/experiences': {
      eyebrow: 'SAVR Log',
      title: 'Save the meals that shaped your taste',
      subtitle: 'Log memorable outings so the platform can learn what felt right and what you want more of later.'
    }
  },
  microcopy: {
    loginTitle: 'Welcome back to SAVR',
    loginSubtitle: 'Sign in to reopen your taste profile, curated matches, venue guide, and saved nights.',
    registerTitle: 'Create your SAVR profile',
    registerSubtitle: 'Start a profile that remembers your preferences, your favorite venues, and the experiences you want to repeat.',
    authFeatures: ['Curated matches', 'Venue discovery', 'Saved dining memories'],
    emptyRecommendations: 'No curated matches yet. Refine the night and ask SAVR again.',
    saveExperienceSuccess: 'Your SAVR Log entry was saved.',
    onboardingSuccess: 'Your taste profile is updated and ready to guide new matches.'
  }
} as const;

export const productLanguageRows = [
  ['Dashboard', 'Home', 'Sidebar navigation'],
  ['Onboarding', 'Taste Profile', 'Sidebar navigation / page heading'],
  ['Recommendations', 'Curated Matches', 'Sidebar navigation / page heading'],
  ['Restaurants', 'Venue Guide', 'Sidebar navigation / page heading'],
  ['Experiences', 'SAVR Log', 'Sidebar navigation / page heading'],
  ['Dining experiences', 'SAVR Log', 'Experiences page'],
  ['Restaurant library', 'Venue Guide', 'Restaurants page'],
  ['Product overview', 'SAVR overview', 'Dashboard hero'],
  ['Open recommendation studio', 'Open Curated Matches', 'Dashboard CTA'],
  ['Update onboarding', 'Refine Taste Profile', 'Dashboard CTA'],
  ['Generate recommendations', 'Generate curated matches', 'Dashboard CTA'],
  ['Login', 'Enter SAVR', 'Login button'],
  ['Register', 'Create SAVR profile', 'Register button'],
  ['Experience saved successfully.', 'Your SAVR Log entry was saved.', 'Experience form success state'],
  ['Failed to load restaurants', 'We could not load the venue guide.', 'Restaurants error state']
] as const;
EOF_src_config_content_ts

mkdir -p "$FRONTEND_DIR/src/config"
cat > "$FRONTEND_DIR/src/config/designTokens.ts" <<'EOF_src_config_designTokens_ts'
export const designTokens = {
  colors: {
    wine: '#781E5A',
    wineSoft: '#9C476B',
    cream: '#F6F1EB',
    olive: '#6F7559',
    charcoal: '#282828',
    gold: '#C9A247',
    blush: '#C98B86',
    line: 'rgba(120, 30, 90, 0.14)',
    lineStrong: 'rgba(120, 30, 90, 0.22)'
  },
  typography: {
    display: 'Cormorant Garamond, Georgia, serif',
    body: 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif'
  },
  radius: {
    sm: '12px',
    md: '18px',
    lg: '24px',
    pill: '999px'
  },
  shadow: {
    soft: '0 14px 36px rgba(60, 38, 29, 0.08)',
    medium: '0 20px 48px rgba(60, 38, 29, 0.12)',
    glow: '0 20px 40px rgba(120, 30, 90, 0.18)'
  },
  spacing: {
    xs: '0.5rem',
    sm: '0.75rem',
    md: '1rem',
    lg: '1.5rem',
    xl: '2rem',
    xxl: '3rem'
  }
} as const;

export type DesignTokens = typeof designTokens;
EOF_src_config_designTokens_ts

mkdir -p "$FRONTEND_DIR/src/components/navigation"
cat > "$FRONTEND_DIR/src/components/navigation/Navbar.tsx" <<'EOF_src_components_navigation_Navbar_tsx'
import { useLocation } from 'react-router-dom';

import { brandContent } from '../../config/content';

type NavbarProps = {
  userName?: string;
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content =
    brandContent.routeMeta[location.pathname as keyof typeof brandContent.routeMeta] ?? {
      eyebrow: 'Workspace',
      title: 'SAVR',
      subtitle: brandContent.strapline
    };

  const today = new Date().toLocaleDateString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric'
  });

  return (
    <header className="app-navbar">
      <div className="navbar-copy">
        <p className="navbar-eyebrow">{content.eyebrow}</p>
        <h2 className="navbar-title">{content.title}</h2>
        <p className="navbar-subtitle">{content.subtitle}</p>
      </div>

      <div className="navbar-right">
        <div className="navbar-date-chip">{today}</div>

        <div className="navbar-meta-card">
          <span className="status-dot" />
          <div>
            <p className="navbar-meta-label">Active profile</p>
            <strong>{userName || 'Guest user'}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
EOF_src_components_navigation_Navbar_tsx

mkdir -p "$FRONTEND_DIR/src/components/navigation"
cat > "$FRONTEND_DIR/src/components/navigation/Sidebar.tsx" <<'EOF_src_components_navigation_Sidebar_tsx'
import { NavLink } from 'react-router-dom';

import { brandContent } from '../../config/content';

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">SV</div>

        <div>
          <p className="sidebar-eyebrow">{brandContent.tagline}</p>
          <h1 className="sidebar-brand">{brandContent.productName}</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Signed in</p>
          <span className="sidebar-online-pill">Live</span>
        </div>

        <strong className="sidebar-user-name">{userName || 'Guest user'}</strong>

        <p className="muted">A personal dining assistant for the nights you want to savor.</p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {brandContent.nav.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              ['sidebar-link', isActive ? 'sidebar-link--active' : '']
                .filter(Boolean)
                .join(' ')
            }
          >
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-footer-card">
          <p className="sidebar-section-label">Brand note</p>
          <p className="muted">Warm, curated, and discovery-led — without changing routes, features, or backend behavior.</p>
        </div>

        <button className="ui-button ui-button--ghost ui-button--md ui-button--full sidebar-logout" type="button" onClick={onLogout}>
          Leave SAVR
        </button>
      </div>
    </aside>
  );
}
EOF_src_components_navigation_Sidebar_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/DashboardPage.tsx" <<'EOF_src_pages_DashboardPage_tsx'
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
EOF_src_pages_DashboardPage_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/ExperiencesPage.tsx" <<'EOF_src_pages_ExperiencesPage_tsx'
import { FormEvent, useEffect, useState } from 'react';

import ExperienceCard from '../components/dining/ExperienceCard';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { brandContent } from '../config/content';
import { apiRequest } from '../lib/api';
import { Experience, RestaurantListItem } from '../types';

export default function ExperiencesPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({
    restaurant_id: '',
    title: 'Unforgettable dinner',
    occasion: 'date night',
    social_context: 'romantic',
    notes: 'Great pacing, strong atmosphere, and a menu I would come back for.',
    overall_rating: '4.5'
  });

  async function loadData() {
    try {
      setError('');
      setLoading(true);
      const [restaurantData, experienceData] = await Promise.all([
        apiRequest<RestaurantListItem[]>('/restaurants'),
        apiRequest<Experience[]>('/experiences')
      ]);
      setRestaurants(restaurantData);
      setExperiences(experienceData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load SAVR Log');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadData();
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setSuccess('');

    try {
      await apiRequest<Experience>('/experiences', {
        method: 'POST',
        body: {
          restaurant_id: form.restaurant_id ? Number(form.restaurant_id) : null,
          title: form.title || null,
          occasion: form.occasion || null,
          social_context: form.social_context || null,
          notes: form.notes || null,
          overall_rating: form.overall_rating ? Number(form.overall_rating) : null,
          menu_item_ids: [],
          ratings: [
            {
              category: 'overall',
              score: form.overall_rating ? Number(form.overall_rating) : 4
            }
          ]
        }
      });

      setSuccess(brandContent.microcopy.saveExperienceSuccess);
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save this SAVR Log entry');
    }
  }

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="card">
        <p className="navbar-eyebrow">SAVR Log</p>
        <h1 className="page-title">Save the nights worth remembering</h1>
        <p className="muted" style={{ maxWidth: '780px', marginBottom: 0 }}>
          Capture venue, context, notes, and ratings so SAVR can learn from the experiences you actually enjoyed.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <Card title="Add a SAVR Log entry" subtitle="Record the meal, the context, and how it felt" actions={<Badge tone="accent">Journal</Badge>}>
          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label htmlFor="restaurant_id">Venue</label>
              <select id="restaurant_id" value={form.restaurant_id} onChange={(e) => setForm({ ...form, restaurant_id: e.target.value })}>
                <option value="">Select a venue</option>
                {restaurants.map((restaurant) => (
                  <option key={restaurant.id} value={restaurant.id}>{restaurant.name}</option>
                ))}
              </select>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="title">Entry title</label>
                <input id="title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="overall_rating">Overall rating</label>
                <input id="overall_rating" value={form.overall_rating} onChange={(e) => setForm({ ...form, overall_rating: e.target.value })} />
              </div>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="occasion">Occasion</label>
                <input id="occasion" value={form.occasion} onChange={(e) => setForm({ ...form, occasion: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="social_context">Social context</label>
                <input id="social_context" value={form.social_context} onChange={(e) => setForm({ ...form, social_context: e.target.value })} />
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="notes">Notes</label>
              <textarea id="notes" value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} rows={5} />
            </div>

            <Button type="submit">Save to SAVR Log</Button>
          </form>
        </Card>

        <Card title="Saved entries" subtitle="A running memory of real dining moments" actions={<Badge>{experiences.length} entries</Badge>}>
          {loading ? (
            <div className="item"><strong>Loading SAVR Log</strong><p className="muted" style={{ marginBottom: 0 }}>Pulling your saved entries from the backend.</p></div>
          ) : experiences.length === 0 ? (
            <div className="item"><strong>No entries yet</strong><p className="muted" style={{ marginBottom: 0 }}>Your first saved night will appear here.</p></div>
          ) : (
            <div className="list">
              {experiences.map((experience) => (
                <ExperienceCard key={experience.id} experience={experience} />
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
EOF_src_pages_ExperiencesPage_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/LoginPage.tsx" <<'EOF_src_pages_LoginPage_tsx'
import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { brandContent } from '../config/content';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState('jp@example.com');
  const [password, setPassword] = useState('StrongPass123');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      await login({ email, password });
      navigate('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign-in failed');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <Card
        className="auth-card"
        title={brandContent.microcopy.loginTitle}
        subtitle={brandContent.microcopy.loginSubtitle}
        actions={<Badge tone="accent">Secure access</Badge>}
      >
        <div className="item">
          <strong>What opens inside SAVR</strong>
          <div style={{ marginTop: '0.8rem' }}>
            {brandContent.microcopy.authFeatures.map((feature, index) => (
              <Badge key={feature} tone={index === 1 ? 'accent' : index === 2 ? 'success' : 'default'}>
                {feature}
              </Badge>
            ))}
          </div>
        </div>

        {error ? <div className="error">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input id="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
            />
          </div>

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? 'Opening SAVR...' : 'Enter SAVR'}
          </Button>
        </form>

        <div className="item">
          <strong>New here?</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            <Link to="/register">Create your SAVR profile</Link>
          </p>
        </div>
      </Card>
    </div>
  );
}
EOF_src_pages_LoginPage_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/OnboardingPage.tsx" <<'EOF_src_pages_OnboardingPage_tsx'
import { FormEvent, useMemo, useState } from 'react';

import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { brandContent } from '../config/content';
import { useAuth } from '../context/AuthContext';
import { apiRequest } from '../lib/api';
import { OnboardingPayload, OnboardingResponse } from '../types';

function splitList(value: string): string[] {
  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

export default function OnboardingPage() {
  const { refreshUser } = useAuth();

  const [form, setForm] = useState({
    dietary_restrictions: '',
    cuisine_preferences: 'italian, comfort-food',
    texture_preferences: 'creamy, crispy',
    dining_pace_preferences: 'leisurely',
    social_preferences: 'romantic',
    drink_preferences: 'cocktails, wine',
    atmosphere_preferences: 'cozy',
    favorite_dining_experiences: 'pasta night, cocktail date night',
    favorite_restaurants: 'Luna Trattoria',
    bio: 'I like cozy dinners with pasta and drinks.',
    spice_tolerance: 'medium',
    price_sensitivity: '$$'
  });

  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [submittedJson, setSubmittedJson] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const previewStats = useMemo(
    () => [
      { label: 'Cuisine cues', value: splitList(form.cuisine_preferences).length },
      { label: 'Drink cues', value: splitList(form.drink_preferences).length },
      { label: 'Atmosphere cues', value: splitList(form.atmosphere_preferences).length }
    ],
    [form]
  );

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setMessage('');
    setIsSubmitting(true);

    const payload: OnboardingPayload = {
      dietary_restrictions: splitList(form.dietary_restrictions),
      cuisine_preferences: splitList(form.cuisine_preferences),
      texture_preferences: splitList(form.texture_preferences),
      dining_pace_preferences: splitList(form.dining_pace_preferences),
      social_preferences: splitList(form.social_preferences),
      drink_preferences: splitList(form.drink_preferences),
      atmosphere_preferences: splitList(form.atmosphere_preferences),
      favorite_dining_experiences: splitList(form.favorite_dining_experiences),
      favorite_restaurants: splitList(form.favorite_restaurants),
      bio: form.bio || null,
      spice_tolerance: form.spice_tolerance || null,
      price_sensitivity: form.price_sensitivity || null
    };

    try {
      const response = await apiRequest<OnboardingResponse>('/onboarding', {
        method: 'POST',
        body: payload
      });
      await refreshUser();
      setMessage(response.message || brandContent.microcopy.onboardingSuccess);
      setSubmittedJson(JSON.stringify(payload, null, 2));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save your taste profile');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="card">
        <p className="navbar-eyebrow">Taste Profile</p>
        <h1 className="page-title">Shape how SAVR curates your night</h1>
        <p className="muted" style={{ maxWidth: '780px', marginBottom: 0 }}>
          Use simple comma-separated inputs to describe the tastes, pacing, drinks, and memories that should guide future recommendations.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-3">
        {previewStats.map((stat, index) => (
          <Card key={stat.label} title={stat.label} subtitle="Active signals" actions={<Badge tone={index === 1 ? 'accent' : index === 2 ? 'success' : 'default'}>{stat.label}</Badge>}>
            <p className="kpi">{stat.value}</p>
          </Card>
        ))}
      </section>

      <section className="grid grid-2">
        <Card title="Taste profile form" subtitle="All existing onboarding fields remain available" actions={<Badge tone="accent">Guided setup</Badge>}>
          <form className="form" onSubmit={handleSubmit}>
            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="cuisine_preferences">Cuisine preferences</label>
                <input id="cuisine_preferences" value={form.cuisine_preferences} onChange={(e) => setForm({ ...form, cuisine_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="texture_preferences">Texture preferences</label>
                <input id="texture_preferences" value={form.texture_preferences} onChange={(e) => setForm({ ...form, texture_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="dining_pace_preferences">Dining pace preferences</label>
                <input id="dining_pace_preferences" value={form.dining_pace_preferences} onChange={(e) => setForm({ ...form, dining_pace_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="social_preferences">Social preferences</label>
                <input id="social_preferences" value={form.social_preferences} onChange={(e) => setForm({ ...form, social_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="drink_preferences">Drink preferences</label>
                <input id="drink_preferences" value={form.drink_preferences} onChange={(e) => setForm({ ...form, drink_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="atmosphere_preferences">Atmosphere preferences</label>
                <input id="atmosphere_preferences" value={form.atmosphere_preferences} onChange={(e) => setForm({ ...form, atmosphere_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="dietary_restrictions">Dietary restrictions</label>
                <input id="dietary_restrictions" value={form.dietary_restrictions} onChange={(e) => setForm({ ...form, dietary_restrictions: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="spice_tolerance">Spice tolerance</label>
                <input id="spice_tolerance" value={form.spice_tolerance} onChange={(e) => setForm({ ...form, spice_tolerance: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="price_sensitivity">Price sensitivity</label>
                <input id="price_sensitivity" value={form.price_sensitivity} onChange={(e) => setForm({ ...form, price_sensitivity: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="favorite_restaurants">Favorite restaurants</label>
                <input id="favorite_restaurants" value={form.favorite_restaurants} onChange={(e) => setForm({ ...form, favorite_restaurants: e.target.value })} />
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="favorite_dining_experiences">Favorite dining experiences</label>
              <input id="favorite_dining_experiences" value={form.favorite_dining_experiences} onChange={(e) => setForm({ ...form, favorite_dining_experiences: e.target.value })} />
            </div>

            <div className="form-row">
              <label htmlFor="bio">Taste note</label>
              <textarea id="bio" rows={5} value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} />
            </div>

            <Button type="submit" disabled={isSubmitting}>{isSubmitting ? 'Saving profile...' : 'Save Taste Profile'}</Button>
          </form>
        </Card>

        <Card title="How SAVR reads this" subtitle="Your current payload preview" actions={<Badge>Live payload</Badge>}>
          <div className="list">
            <div className="item">
              <strong>Input style</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Comma-separated entries are split into arrays before being sent to the existing onboarding endpoint.</p>
            </div>
            <div className="item">
              <strong>Recommendation impact</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Cuisine, drink, atmosphere, and pace cues are used later by the recommendation flows without changing backend logic.</p>
            </div>
            {submittedJson ? (
              <pre className="json-box">{submittedJson}</pre>
            ) : (
              <div className="item">
                <strong>No payload submitted yet</strong>
                <p className="muted" style={{ marginBottom: 0 }}>Save the form once to preview the exact JSON sent to the API.</p>
              </div>
            )}
          </div>
        </Card>
      </section>
    </div>
  );
}
EOF_src_pages_OnboardingPage_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx" <<'EOF_src_pages_RecommendationsPage_tsx'
import { FormEvent, useEffect, useMemo, useState } from "react";

import RecommendationCard from "../components/dining/RecommendationCard";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { apiRequest } from "../lib/api";
import { RecommendationItem, RecommendationResponse } from "../types";

type Mode = "build" | "describe" | "surprise";
type SingleBuildField = "outing_type" | "budget" | "pace" | "social_context";
type MultiBuildField = "preferred_cuisines" | "atmosphere";

type BuildFormState = {
  outing_type: string;
  budget: string;
  pace: string;
  social_context: string;
  preferred_cuisines: string[];
  atmosphere: string[];
  drinks_focus: boolean;
};

type BlockOption = {
  label: string;
  value: string;
  hint?: string;
};

type BuildPreset = {
  label: string;
  description: string;
  state: BuildFormState;
};

type SavedRun = {
  id: string;
  createdAt: string;
  engineVersion: string;
  requestSummary: BuildFormState;
  resultCount: number;
  topResultName: string | null;
};

const RUN_STORAGE_KEY = "build-your-night-recent-runs-v1";

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
    eyebrow: "Guided mode",
    title: "Build Your SAVR Night",
    subtitle:
      "Choose clear experience blocks that map directly to the recommendation engine.",
    bullets: [
      "Uses canonical values shared with the backend scorer.",
      "Best for controlled demos and predictable comparisons.",
      "Now includes transparency, saved runs, and exportable diagnostics."
    ]
  },
  describe: {
    eyebrow: "Describe mode",
    title: "Describe the Night",
    subtitle:
      "Describe the kind of night you want in natural language and let SAVR interpret it.",
    bullets: [
      "Best when the vibe matters more than rigid form fields.",
      "Feels closer to a personal dining assistant.",
      "Useful for testing natural-language intent parsing."
    ]
  },
  surprise: {
    eyebrow: "Discovery mode",
    title: "Let SAVR Surprise You",
    subtitle: "Get recommendationes quickly with minimal friction.",
    bullets: [
      "Fastest path to discovery.",
      "Uses your saved preferences when available.",
      "Good for novelty and low-effort browsing."
    ]
  }
};

const outingOptions: BlockOption[] = [
  { label: "Casual bite", value: "casual-bite", hint: "easy, flexible, low-pressure" },
  { label: "Date night", value: "date-night", hint: "romantic, polished, slower" },
  { label: "Group dinner", value: "group-dinner", hint: "social, shareable, energetic" },
  { label: "Drinks night", value: "drinks-night", hint: "beer, wine, pub, brewery" },
  { label: "Quick bite", value: "quick-bite", hint: "fast, convenient, affordable" },
  { label: "Coffee stop", value: "coffee-stop", hint: "café, coffeehouse, study-friendly" },
  { label: "Special occasion", value: "special-occasion", hint: "refined, scenic, memorable" }
];

const budgetOptions: BlockOption[] = [
  { label: "$", value: "$", hint: "budget-friendly" },
  { label: "$$", value: "$$", hint: "mid-range" },
  { label: "$$$", value: "$$$", hint: "premium" }
];

const paceOptions: BlockOption[] = [
  { label: "Fast", value: "fast" },
  { label: "Moderate", value: "moderate" },
  { label: "Slow", value: "slow" },
  { label: "Leisurely", value: "leisurely" }
];

const socialOptions: BlockOption[] = [
  { label: "Solo", value: "solo" },
  { label: "Friends", value: "friends" },
  { label: "Group", value: "group" },
  { label: "Date", value: "date" }
];

const cuisineOptions: BlockOption[] = [
  { label: "Pizza", value: "pizza" },
  { label: "Mediterranean", value: "mediterranean" },
  { label: "Asian", value: "asian" },
  { label: "Bakery", value: "bakery" },
  { label: "Dessert", value: "dessert" },
  { label: "Seasonal", value: "seasonal" },
  { label: "Turkish", value: "turkish" },
  { label: "Coffee", value: "coffee" },
  { label: "Beer", value: "beer" },
  { label: "Wine", value: "wine" },
  { label: "Cider", value: "cider" }
];

const atmosphereOptions: BlockOption[] = [
  { label: "Cozy", value: "cozy" },
  { label: "Lively", value: "lively" },
  { label: "Quiet", value: "quiet" },
  { label: "Casual", value: "casual" },
  { label: "Scenic", value: "scenic" },
  { label: "Historic", value: "historic" },
  { label: "Refined", value: "refined" },
  { label: "Upscale", value: "upscale" },
  { label: "Rustic", value: "rustic" }
];

const yesNoOptions: BlockOption[] = [
  { label: "Yes", value: "yes", hint: "drinks should matter" },
  { label: "No", value: "no", hint: "food and setting first" }
];

const initialBuildForm: BuildFormState = {
  outing_type: "casual-bite",
  budget: "",
  pace: "",
  social_context: "",
  preferred_cuisines: [],
  atmosphere: [],
  drinks_focus: false
};

const buildPresets: BuildPreset[] = [
  {
    label: "Scenic date night",
    description: "Luxury, scenic, quieter, wine-friendly validation case.",
    state: {
      outing_type: "date-night",
      budget: "$$$",
      pace: "leisurely",
      social_context: "date",
      preferred_cuisines: ["wine", "seasonal"],
      atmosphere: ["scenic", "quiet", "refined"],
      drinks_focus: true
    }
  },
  {
    label: "Fast solo bite",
    description: "Budget, fast, solo validation case.",
    state: {
      outing_type: "quick-bite",
      budget: "$",
      pace: "fast",
      social_context: "solo",
      preferred_cuisines: ["asian"],
      atmosphere: ["casual"],
      drinks_focus: false
    }
  },
  {
    label: "Quiet coffee stop",
    description: "Solo coffee validation case.",
    state: {
      outing_type: "coffee-stop",
      budget: "$",
      pace: "slow",
      social_context: "solo",
      preferred_cuisines: ["coffee"],
      atmosphere: ["quiet"],
      drinks_focus: false
    }
  },
  {
    label: "Group drinks night",
    description: "Social drinks-forward validation case.",
    state: {
      outing_type: "drinks-night",
      budget: "$$",
      pace: "moderate",
      social_context: "group",
      preferred_cuisines: ["beer", "wine"],
      atmosphere: ["lively", "casual"],
      drinks_focus: true
    }
  }
];

function normalizeScore(score?: number): number | undefined {
  if (typeof score !== "number" || Number.isNaN(score)) {
    return undefined;
  }

  return Math.max(0, Math.min(score / 14, 1));
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
    rank: item.rank,
    fitLabel: item.fit_label,
    explanation:
      item.explanation ||
      (reasons.length > 0
        ? reasons.join(" • ")
        : "This restaurant matched your current dining request."),
    score: normalizeScore(item.score),
    confidenceLevel: item.confidence_level,
    matchedSignals: item.matched_signals ?? [],
    penalizedSignals: item.penalized_signals ?? [],
    scoreBreakdown: item.score_breakdown ?? [],
    tags: tagValues
  };
}

function toggleArrayValue(values: string[], value: string): string[] {
  if (values.includes(value)) {
    return values.filter((entry) => entry !== value);
  }

  return [...values, value];
}

function BlockSection({
  title,
  subtitle,
  options,
  selectedValue,
  onSelect
}: {
  title: string;
  subtitle: string;
  options: BlockOption[];
  selectedValue: string;
  onSelect: (value: string) => void;
}) {
  return (
    <div className="build-section">
      <div className="build-section__copy">
        <strong>{title}</strong>
        <p className="muted">{subtitle}</p>
      </div>
      <div className="build-block-grid">
        {options.map((option) => {
          const active = selectedValue === option.value;
          return (
            <button
              key={option.value}
              type="button"
              className={active ? "build-block active" : "build-block"}
              onClick={() => onSelect(option.value)}
            >
              <span className="build-block__label">{option.label}</span>
              {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function MultiBlockSection({
  title,
  subtitle,
  options,
  selectedValues,
  onToggle
}: {
  title: string;
  subtitle: string;
  options: BlockOption[];
  selectedValues: string[];
  onToggle: (value: string) => void;
}) {
  return (
    <div className="build-section">
      <div className="build-section__copy">
        <strong>{title}</strong>
        <p className="muted">{subtitle}</p>
      </div>
      <div className="build-block-grid">
        {options.map((option) => {
          const active = selectedValues.includes(option.value);
          return (
            <button
              key={option.value}
              type="button"
              className={active ? "build-block active" : "build-block"}
              onClick={() => onToggle(option.value)}
            >
              <span className="build-block__label">{option.label}</span>
              {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function formatRunSummary(run: SavedRun): string {
  const parts: string[] = [];
  if (run.requestSummary.outing_type) parts.push(run.requestSummary.outing_type);
  if (run.requestSummary.budget) parts.push(run.requestSummary.budget);
  if (run.requestSummary.pace) parts.push(run.requestSummary.pace);
  if (run.requestSummary.social_context) parts.push(run.requestSummary.social_context);
  return parts.join(" • ");
}

export default function RecommendationsPage() {
  const [mode, setMode] = useState<Mode>("build");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [results, setResults] = useState<RecommendationItem[]>([]);
  const [lastResponse, setLastResponse] = useState<RecommendationResponse | null>(null);
  const [savedRuns, setSavedRuns] = useState<SavedRun[]>([]);

  const [buildForm, setBuildForm] = useState<BuildFormState>(initialBuildForm);
  const [describeText, setDescribeText] = useState("");
  const [includeDrinks, setIncludeDrinks] = useState(false);

  const activeMeta = modeMeta[mode];

  useEffect(() => {
    try {
      const raw = localStorage.getItem(RUN_STORAGE_KEY);
      if (!raw) return;
      const parsed = JSON.parse(raw) as SavedRun[];
      if (Array.isArray(parsed)) {
        setSavedRuns(parsed);
      }
    } catch {
      setSavedRuns([]);
    }
  }, []);

  const normalizedResults = useMemo(
    () => results.map((item, index) => normalizeRecommendation(item, index)),
    [results]
  );

  const buildSummary = useMemo(() => {
    const parts: string[] = [];

    if (buildForm.outing_type) parts.push(`outing: ${buildForm.outing_type}`);
    if (buildForm.budget) parts.push(`budget: ${buildForm.budget}`);
    if (buildForm.pace) parts.push(`pace: ${buildForm.pace}`);
    if (buildForm.social_context) parts.push(`social: ${buildForm.social_context}`);
    if (buildForm.preferred_cuisines.length > 0) {
      parts.push(`interests: ${buildForm.preferred_cuisines.join(", ")}`);
    }
    if (buildForm.atmosphere.length > 0) {
      parts.push(`atmosphere: ${buildForm.atmosphere.join(", ")}`);
    }
    parts.push(`drinks focus: ${buildForm.drinks_focus ? "yes" : "no"}`);

    return parts;
  }, [buildForm]);

  function persistRun(data: RecommendationResponse, requestSummary: BuildFormState) {
    const nextRun: SavedRun = {
      id: `${Date.now()}`,
      createdAt: data.generated_at || new Date().toISOString(),
      engineVersion: data.engine_version || "unknown",
      requestSummary,
      resultCount: data.results.length,
      topResultName: data.results[0]?.restaurant_name || null
    };

    const nextRuns = [nextRun, ...savedRuns].slice(0, 8);
    setSavedRuns(nextRuns);
    localStorage.setItem(RUN_STORAGE_KEY, JSON.stringify(nextRuns));
  }

  async function runRequest(
    endpoint: string,
    payload: Record<string, unknown>,
    options?: { saveBuildRun?: boolean; buildState?: BuildFormState }
  ) {
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
      setLastResponse(data);

      if (options?.saveBuildRun && options.buildState) {
        persistRun(data, options.buildState);
      }

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
      setLastResponse(null);
    } finally {
      setLoading(false);
    }
  }

  async function handleBuildSubmit(event: FormEvent) {
    event.preventDefault();

    await runRequest(
      "/recommendations/build-your-night",
      {
        outing_type: buildForm.outing_type,
        budget: buildForm.budget || null,
        pace: buildForm.pace || null,
        social_context: buildForm.social_context || null,
        preferred_cuisines: buildForm.preferred_cuisines,
        drinks_focus: buildForm.drinks_focus,
        atmosphere: buildForm.atmosphere
      },
      {
        saveBuildRun: true,
        buildState: buildForm
      }
    );
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

  function selectSingle(field: SingleBuildField, value: string) {
    setBuildForm((prev) => ({ ...prev, [field]: prev[field] === value ? "" : value }));
  }

  function toggleMulti(field: MultiBuildField, value: string) {
    setBuildForm((prev) => ({
      ...prev,
      [field]: toggleArrayValue(prev[field], value)
    }));
  }

  function resetBuildForm() {
    setBuildForm(initialBuildForm);
  }

  function applyPreset(preset: BuildPreset) {
    setMode("build");
    setBuildForm(preset.state);
  }

  function applySavedRun(run: SavedRun) {
    setMode("build");
    setBuildForm(run.requestSummary);
  }

  function clearSavedRuns() {
    setSavedRuns([]);
    localStorage.removeItem(RUN_STORAGE_KEY);
  }

  function exportDiagnostics() {
    if (!lastResponse) {
      setError("No diagnostics available to export yet.");
      return;
    }

    const blob = new Blob([JSON.stringify(lastResponse, null, 2)], {
      type: "application/json"
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    anchor.href = url;
    anchor.download = `recommendation-diagnostics-${stamp}.json`;
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
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
            Build Your SAVR Night
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
            Describe the Night
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
            Let SAVR Surprise You
          </h3>
          <p className="muted" style={{ margin: 0 }}>
            Best when you want novelty with almost no effort.
          </p>
        </button>
      </section>

      {mode === "build" ? (
        <>
          <section className="card">
            <p className="navbar-eyebrow">Validation presets</p>
            <h3 style={{ marginTop: "0.35rem" }}>Apply a known test build</h3>
            <p className="muted" style={{ marginTop: 0 }}>
              These presets help you validate whether the engine is ranking the right types of venues.
            </p>
            <div style={{ display: "grid", gap: "0.85rem", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))" }}>
              {buildPresets.map((preset) => (
                <div
                  key={preset.label}
                  style={{
                    border: "1px solid rgba(148, 163, 184, 0.18)",
                    borderRadius: "1rem",
                    padding: "0.95rem",
                    background: "rgba(15, 23, 42, 0.4)"
                  }}
                >
                  <strong>{preset.label}</strong>
                  <p className="muted" style={{ marginTop: "0.45rem", marginBottom: "0.85rem" }}>
                    {preset.description}
                  </p>
                  <Button variant="secondary" onClick={() => applyPreset(preset)}>
                    Apply preset
                  </Button>
                </div>
              ))}
            </div>
          </section>

          <section className="card">
            <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap", alignItems: "center" }}>
              <div>
                <p className="navbar-eyebrow">Saved runs</p>
                <h3 style={{ marginTop: "0.35rem", marginBottom: "0.35rem" }}>Recent Build Your SAVR Night runs</h3>
                <p className="muted" style={{ margin: 0 }}>
                  Reapply earlier builds fast and export the latest diagnostics for QA.
                </p>
              </div>
              <div className="button-row">
                <Button variant="secondary" onClick={exportDiagnostics}>
                  Export latest diagnostics
                </Button>
                <Button variant="ghost" onClick={clearSavedRuns}>
                  Clear saved runs
                </Button>
              </div>
            </div>

            {savedRuns.length === 0 ? (
              <p className="muted" style={{ marginTop: "1rem", marginBottom: 0 }}>
                No saved runs yet. Generate a Build Your SAVR Night recommendation to populate this panel.
              </p>
            ) : (
              <div style={{ display: "grid", gap: "0.8rem", marginTop: "1rem" }}>
                {savedRuns.map((run) => (
                  <div
                    key={run.id}
                    style={{
                      border: "1px solid rgba(148, 163, 184, 0.18)",
                      borderRadius: "1rem",
                      padding: "0.9rem",
                      background: "rgba(15, 23, 42, 0.32)",
                      display: "grid",
                      gap: "0.45rem"
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
                      <strong>{formatRunSummary(run) || "Saved build"}</strong>
                      <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                        <Badge tone="accent">{run.engineVersion}</Badge>
                        <Badge>{run.resultCount} results</Badge>
                      </div>
                    </div>
                    <p className="muted" style={{ margin: 0 }}>
                      Top result: {run.topResultName || "none"} • {new Date(run.createdAt).toLocaleString()}
                    </p>
                    <div className="button-row">
                      <Button variant="secondary" onClick={() => applySavedRun(run)}>
                        Reapply build
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </>
      ) : null}

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
              <div className="build-night-layout">
                <BlockSection
                  title="Pick the kind of night"
                  subtitle="Choose the primary intent first."
                  options={outingOptions}
                  selectedValue={buildForm.outing_type}
                  onSelect={(value) => selectSingle("outing_type", value)}
                />

                <BlockSection
                  title="Choose your budget"
                  subtitle="Match the spend level you actually want."
                  options={budgetOptions}
                  selectedValue={buildForm.budget}
                  onSelect={(value) => selectSingle("budget", value)}
                />

                <BlockSection
                  title="Set the pace"
                  subtitle="Control how fast or relaxed the outing should feel."
                  options={paceOptions}
                  selectedValue={buildForm.pace}
                  onSelect={(value) => selectSingle("pace", value)}
                />

                <BlockSection
                  title="Who is this for"
                  subtitle="Tell the engine the social setup."
                  options={socialOptions}
                  selectedValue={buildForm.social_context}
                  onSelect={(value) => selectSingle("social_context", value)}
                />

                <MultiBlockSection
                  title="Pick food and drink interests"
                  subtitle="Select as many cuisine or drink signals as you want."
                  options={cuisineOptions}
                  selectedValues={buildForm.preferred_cuisines}
                  onToggle={(value) => toggleMulti("preferred_cuisines", value)}
                />

                <MultiBlockSection
                  title="Choose the atmosphere"
                  subtitle="These values directly influence the scorer."
                  options={atmosphereOptions}
                  selectedValues={buildForm.atmosphere}
                  onToggle={(value) => toggleMulti("atmosphere", value)}
                />

                <div className="build-section">
                  <div className="build-section__copy">
                    <strong>Should drinks matter</strong>
                    <p className="muted">Toggle whether the engine should actively prefer drink-friendly venues.</p>
                  </div>
                  <div className="build-block-grid build-block-grid--compact">
                    {yesNoOptions.map((option) => {
                      const active = buildForm.drinks_focus === (option.value === "yes");
                      return (
                        <button
                          key={option.value}
                          type="button"
                          className={active ? "build-block active" : "build-block"}
                          onClick={() =>
                            setBuildForm((prev) => ({
                              ...prev,
                              drinks_focus: option.value === "yes"
                            }))
                          }
                        >
                          <span className="build-block__label">{option.label}</span>
                          {option.hint ? <span className="build-block__hint">{option.hint}</span> : null}
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>

              <div className="build-summary">
                <strong>Current build</strong>
                <div className="build-summary__chips">
                  {buildSummary.map((value) => (
                    <span key={value} className="build-summary__chip">
                      {value}
                    </span>
                  ))}
                </div>
              </div>

              <div className="button-row">
                <Button type="button" variant="secondary" onClick={resetBuildForm} disabled={loading}>
                  Reset selections
                </Button>
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
              <div style={{ display: "flex", gap: "0.45rem", flexWrap: "wrap" }}>
                <Badge tone="success">
                  {normalizedResults.length} result{normalizedResults.length === 1 ? "" : "s"}
                </Badge>
                {lastResponse?.engine_version ? <Badge tone="accent">{lastResponse.engine_version}</Badge> : null}
              </div>
            ) : (
              <Badge>Waiting</Badge>
            )
          }
        >
          {lastResponse?.generated_at ? (
            <div className="item" style={{ marginBottom: "0.9rem" }}>
              <strong>Last run metadata</strong>
              <p className="muted" style={{ margin: "0.35rem 0 0" }}>
                Generated: {new Date(lastResponse.generated_at).toLocaleString()}
              </p>
              {lastResponse.request_summary ? (
                <p className="muted" style={{ margin: "0.2rem 0 0" }}>
                  Request: {lastResponse.request_summary.outing_type || "n/a"}
                  {lastResponse.request_summary.budget ? ` • ${lastResponse.request_summary.budget}` : ""}
                  {lastResponse.request_summary.pace ? ` • ${lastResponse.request_summary.pace}` : ""}
                  {lastResponse.request_summary.social_context ? ` • ${lastResponse.request_summary.social_context}` : ""}
                </p>
              ) : null}
            </div>
          ) : null}

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
                  Use a validation preset, generate results, inspect the scoring detail,
                  and export diagnostics when the run looks correct.
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
                  rank={item.rank}
                  fitLabel={item.fitLabel}
                  score={item.score}
                  explanation={item.explanation}
                  confidenceLevel={item.confidenceLevel}
                  matchedSignals={item.matchedSignals}
                  penalizedSignals={item.penalizedSignals}
                  scoreBreakdown={item.scoreBreakdown}
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
EOF_src_pages_RecommendationsPage_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/RegisterPage.tsx" <<'EOF_src_pages_RegisterPage_tsx'
import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { brandContent } from '../config/content';
import { useAuth } from '../context/AuthContext';

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();

  const [form, setForm] = useState({
    first_name: '',
    last_name: '',
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setSuccess('');
    setIsSubmitting(true);

    try {
      await register(form);
      setSuccess('Your SAVR profile is ready. Redirecting to sign in.');
      setTimeout(() => navigate('/login'), 900);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Profile creation failed');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <Card
        className="auth-card"
        title={brandContent.microcopy.registerTitle}
        subtitle={brandContent.microcopy.registerSubtitle}
        actions={<Badge tone="accent">New profile</Badge>}
      >
        <div className="item">
          <strong>What your profile remembers</strong>
          <div style={{ marginTop: '0.8rem' }}>
            <Badge>Taste profile</Badge>
            <Badge tone="accent">Curated match history</Badge>
            <Badge tone="success">Saved nights</Badge>
          </div>
        </div>

        {error ? <div className="error">{error}</div> : null}
        {success ? <div className="success">{success}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="grid grid-2">
            <div className="form-row">
              <label htmlFor="first_name">First name</label>
              <input id="first_name" value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} />
            </div>

            <div className="form-row">
              <label htmlFor="last_name">Last name</label>
              <input id="last_name" value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} />
            </div>
          </div>

          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input id="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input id="password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
          </div>

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? 'Creating profile...' : 'Create SAVR profile'}
          </Button>
        </form>

        <div className="item">
          <strong>Already have a profile?</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            <Link to="/login">Return to sign in</Link>
          </p>
        </div>
      </Card>
    </div>
  );
}
EOF_src_pages_RegisterPage_tsx

mkdir -p "$FRONTEND_DIR/src/pages"
cat > "$FRONTEND_DIR/src/pages/RestaurantsPage.tsx" <<'EOF_src_pages_RestaurantsPage_tsx'
import { useEffect, useMemo, useState } from 'react';

import RestaurantCard from '../components/dining/RestaurantCard';
import Badge from '../components/ui/Badge';
import Card from '../components/ui/Card';
import { apiRequest } from '../lib/api';
import { RestaurantDetail, RestaurantListItem } from '../types';

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<RestaurantDetail | null>(null);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [error, setError] = useState('');
  const [loadingList, setLoadingList] = useState(true);
  const [loadingDetail, setLoadingDetail] = useState(false);

  useEffect(() => {
    void loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      setError('');
      setLoadingList(true);
      const data = await apiRequest<RestaurantListItem[]>('/restaurants');
      setRestaurants(data);
      if (data.length > 0 && selectedId === null) {
        void loadRestaurantDetail(data[0].id);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'We could not load the venue guide.');
    } finally {
      setLoadingList(false);
    }
  }

  async function loadRestaurantDetail(restaurantId: number) {
    try {
      setError('');
      setLoadingDetail(true);
      setSelectedId(restaurantId);
      const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
      setSelectedRestaurant(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'We could not load this venue.');
    } finally {
      setLoadingDetail(false);
    }
  }

  const summaryText = useMemo(() => {
    if (!selectedRestaurant) {
      return 'Choose a venue to inspect its menu, tags, atmosphere, and recommendation signals.';
    }

    return selectedRestaurant.description || 'No summary is available for this venue yet.';
  }, [selectedRestaurant]);

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="card">
        <p className="navbar-eyebrow">Venue Guide</p>
        <h1 className="page-title">Browse the places SAVR can recommend</h1>
        <p className="muted" style={{ maxWidth: '780px', marginBottom: 0 }}>
          Compare restaurants in a research-first layout that keeps the catalog on one side and a detailed venue profile on the other.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card title="Available venues" subtitle="Loaded directly from the backend catalog" actions={<Badge>{restaurants.length} venues</Badge>}>
          {loadingList ? (
            <div className="item">
              <strong>Loading the venue guide</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Pulling available restaurants from the API.</p>
            </div>
          ) : restaurants.length === 0 ? (
            <div className="item">
              <strong>No venues are available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>The backend returned an empty catalog.</p>
            </div>
          ) : (
            <div className="list">
              {restaurants.map((restaurant) => (
                <RestaurantCard key={restaurant.id} restaurant={restaurant} onSelect={(restaurantId) => void loadRestaurantDetail(restaurantId)} isActive={selectedId === restaurant.id} />
              ))}
            </div>
          )}
        </Card>

        <Card title={selectedRestaurant?.name || 'Venue detail'} subtitle={summaryText} actions={selectedRestaurant ? <Badge tone="accent">{selectedRestaurant.price_tier}</Badge> : <Badge>Preview</Badge>}>
          {!selectedRestaurant ? (
            <div className="item">
              <strong>No venue selected</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Choose a venue from the guide to inspect its full profile.</p>
            </div>
          ) : (
            <div className="list">
              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: '0.4rem' }}>Venue profile</p>
                <strong>Atmosphere and positioning</strong>
                <p className="muted">{selectedRestaurant.city} • {selectedRestaurant.price_tier} • {selectedRestaurant.atmosphere || 'No atmosphere'} • {selectedRestaurant.pace || 'No pace'} • {selectedRestaurant.social_style || 'No social style'}</p>
                <div>
                  {selectedRestaurant.tags.map((tag) => (
                    <Badge key={`${tag.category}-${tag.name}`}>{tag.category}: {tag.name}</Badge>
                  ))}
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: '0.4rem' }}>Menu signals</p>
                <strong>Menu items</strong>
                {loadingDetail ? (
                  <p className="muted">Loading venue detail...</p>
                ) : selectedRestaurant.menu_items.length === 0 ? (
                  <p className="muted" style={{ marginBottom: 0 }}>No menu items were returned for this venue.</p>
                ) : (
                  <div className="list" style={{ marginTop: '0.8rem' }}>
                    {selectedRestaurant.menu_items.map((item) => (
                      <div className="item" key={item.id}>
                        <strong>{item.name}</strong>
                        <p className="muted">{item.category} • Price: {item.price ?? '-'} • {item.is_signature ? 'Signature item' : 'Standard item'}</p>
                        <p style={{ marginBottom: item.tags.length > 0 ? '0.8rem' : 0 }}>{item.description || 'No description'}</p>
                        {item.tags.length > 0 ? (
                          <div>
                            {item.tags.map((tag) => (
                              <Badge key={`${item.id}-${tag.id}`} tone="accent">{tag.name}</Badge>
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
      </section>
    </div>
  );
}
EOF_src_pages_RestaurantsPage_tsx

mkdir -p "$FRONTEND_DIR/src"
cat > "$FRONTEND_DIR/src/styles.css" <<'EOF_src_styles_css'
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600;700&family=Inter:wght@400;500;600;700;800&display=swap');

:root {
  --font-display: 'Cormorant Garamond', Georgia, serif;
  --font-body: 'Inter', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;

  --color-wine: #781e5a;
  --color-wine-soft: #9c476b;
  --color-cream: #f6f1eb;
  --color-cream-strong: #fffaf5;
  --color-olive: #6f7559;
  --color-charcoal: #282828;
  --color-gold: #c9a247;
  --color-blush: #c98b86;
  --color-border: rgba(120, 30, 90, 0.14);
  --color-border-strong: rgba(120, 30, 90, 0.24);
  --color-surface: rgba(255, 251, 246, 0.9);
  --color-surface-strong: rgba(255, 248, 241, 0.97);
  --color-panel: rgba(246, 241, 235, 0.92);
  --text-main: #2f2926;
  --text-soft: #6d645e;
  --text-faint: #9a8f87;
  --shadow-soft: 0 14px 36px rgba(60, 38, 29, 0.08);
  --shadow-medium: 0 20px 48px rgba(60, 38, 29, 0.12);
  --shadow-glow: 0 18px 40px rgba(120, 30, 90, 0.12);
  --radius-sm: 12px;
  --radius-md: 18px;
  --radius-lg: 24px;
  --radius-pill: 999px;
}

* { box-sizing: border-box; }
html, body, #root { min-height: 100%; }
html { background: linear-gradient(180deg, #efe7e1 0%, #f8f3ee 100%); }
body {
  margin: 0;
  min-width: 320px;
  font-family: var(--font-body);
  color: var(--text-main);
  background:
    radial-gradient(circle at top left, rgba(120, 30, 90, 0.08), transparent 28%),
    radial-gradient(circle at top right, rgba(201, 162, 71, 0.10), transparent 26%),
    radial-gradient(circle at bottom center, rgba(111, 117, 89, 0.08), transparent 24%),
    linear-gradient(180deg, #efe7e1 0%, #f8f3ee 100%);
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

a { color: inherit; text-decoration: none; }
button, input, textarea, select { font: inherit; }
button { cursor: pointer; }
textarea { resize: vertical; }

.app-frame {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 300px minmax(0, 1fr);
}

.app-sidebar {
  position: sticky;
  top: 0;
  height: 100vh;
  padding: 1.4rem;
  border-right: 1px solid rgba(120, 30, 90, 0.08);
  background: linear-gradient(180deg, rgba(249, 243, 237, 0.97), rgba(245, 238, 230, 0.93));
  backdrop-filter: blur(18px);
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.sidebar-brand-block {
  display: flex;
  align-items: center;
  gap: 0.95rem;
  padding: 0.25rem 0.2rem 0.8rem;
}

.sidebar-brand-mark {
  width: 3.15rem;
  height: 3.15rem;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-weight: 800;
  font-size: 0.82rem;
  letter-spacing: 0.08em;
  color: var(--color-cream-strong);
  background: radial-gradient(circle at 35% 30%, #9c476b 0%, var(--color-wine) 58%, #5d1346 100%);
  box-shadow: var(--shadow-glow);
  border: 2px solid rgba(201, 162, 71, 0.45);
}

.sidebar-eyebrow,
.navbar-eyebrow,
.sidebar-section-label,
.navbar-meta-label {
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.16em;
  font-size: 0.72rem;
  color: var(--color-wine);
  font-weight: 700;
}

.sidebar-brand,
.navbar-title,
.page-title,
.ui-card__title,
.auth-card h3 {
  font-family: var(--font-display);
}

.sidebar-brand {
  margin: 0.08rem 0 0;
  font-size: 2rem;
  line-height: 0.95;
  letter-spacing: -0.03em;
}

.sidebar-profile-card,
.navbar-meta-card,
.sidebar-footer-card,
.ui-card,
.card,
.auth-card,
.item,
.json-box,
.hero-card {
  border: 1px solid var(--color-border);
  background: linear-gradient(180deg, rgba(255, 251, 246, 0.98), rgba(248, 242, 236, 0.92));
  box-shadow: var(--shadow-soft);
}

.sidebar-profile-card,
.navbar-meta-card,
.sidebar-footer-card,
.ui-card,
.card,
.auth-card,
.hero-card {
  border-radius: var(--radius-lg);
}

.sidebar-profile-card,
.sidebar-footer-card { padding: 1rem; }
.sidebar-profile-card__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  margin-bottom: 0.55rem;
}

.sidebar-online-pill,
.build-summary__chip {
  display: inline-flex;
  align-items: center;
  border-radius: var(--radius-pill);
  padding: 0.32rem 0.68rem;
  font-size: 0.74rem;
  font-weight: 700;
  color: #456144;
  background: rgba(111, 117, 89, 0.14);
  border: 1px solid rgba(111, 117, 89, 0.2);
}

.sidebar-user-name { display: block; margin-bottom: 0.35rem; }
.muted { color: var(--text-soft); }

.sidebar-nav,
.grid,
.list,
.form,
.page-content,
.ui-card__body,
.build-night-layout,
.build-section,
.build-summary,
.build-summary__chips { display: grid; gap: 1rem; }

.grid-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.grid-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }

.sidebar-link {
  display: flex;
  align-items: center;
  gap: 0.82rem;
  padding: 0.92rem 1rem;
  border-radius: var(--radius-md);
  color: var(--text-soft);
  transition: 180ms ease;
  border: 1px solid transparent;
}
.sidebar-link:hover {
  transform: translateX(2px);
  background: rgba(120, 30, 90, 0.05);
  color: var(--text-main);
}
.sidebar-link--active {
  background: linear-gradient(135deg, rgba(120, 30, 90, 0.11), rgba(201, 162, 71, 0.12));
  color: var(--text-main);
  border-color: var(--color-border-strong);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.7);
}
.sidebar-link__icon {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  display: inline-grid;
  place-items: center;
  font-size: 0.66rem;
  font-weight: 800;
  color: var(--color-wine);
  background: rgba(120, 30, 90, 0.08);
  border: 1px solid rgba(120, 30, 90, 0.12);
}
.sidebar-footer { margin-top: auto; display: grid; gap: 0.75rem; }

.app-main-column {
  min-width: 0;
  display: flex;
  flex-direction: column;
  position: relative;
}
.app-main-column::before {
  content: '';
  position: absolute;
  inset: 0 0 auto 0;
  height: 240px;
  pointer-events: none;
  background: linear-gradient(180deg, rgba(120, 30, 90, 0.06), transparent 78%);
}

.app-navbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.9rem 2rem 0.9rem;
  position: relative;
  z-index: 1;
}
.navbar-copy { max-width: 860px; }
.navbar-title {
  margin: 0.18rem 0 0.45rem;
  font-size: clamp(2.4rem, 4vw, 3.4rem);
  line-height: 0.92;
  letter-spacing: -0.04em;
}
.navbar-subtitle { max-width: 760px; margin: 0; color: var(--text-soft); }
.navbar-right { display: flex; align-items: stretch; gap: 0.8rem; flex-wrap: wrap; justify-content: flex-end; }
.navbar-date-chip {
  display: inline-flex;
  align-items: center;
  border-radius: var(--radius-pill);
  padding: 0.75rem 1rem;
  background: rgba(255, 250, 244, 0.88);
  border: 1px solid var(--color-border);
  color: var(--color-wine);
  min-height: 54px;
  box-shadow: var(--shadow-soft);
}
.navbar-meta-card {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  min-width: 220px;
  padding: 0.95rem 1rem;
}
.status-dot {
  width: 0.62rem;
  height: 0.62rem;
  border-radius: 999px;
  background: linear-gradient(135deg, var(--color-gold), var(--color-wine));
  box-shadow: 0 0 0 6px rgba(201, 162, 71, 0.15);
  flex: 0 0 auto;
}

.page-shell { min-height: 100%; padding: 0.35rem 2rem 2.25rem; position: relative; z-index: 1; }
.page-content { width: min(1240px, 100%); }
.page-title {
  margin: 0 0 0.55rem;
  font-size: clamp(2.15rem, 3vw, 3rem);
  letter-spacing: -0.04em;
  line-height: 0.95;
  font-weight: 700;
}

.hero-card,
.card,
.auth-card,
.ui-card { padding: 1.4rem; }
.hero-card {
  position: relative;
  overflow: hidden;
  background:
    linear-gradient(135deg, rgba(120, 30, 90, 0.06), rgba(201, 162, 71, 0.08)),
    linear-gradient(180deg, rgba(255, 251, 246, 0.99), rgba(246, 239, 232, 0.95));
}
.hero-card::after {
  content: '';
  position: absolute;
  right: -40px;
  top: -40px;
  width: 180px;
  height: 180px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(201, 162, 71, 0.18) 0%, transparent 70%);
}

.ui-card__header {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: flex-start;
  margin-bottom: 1rem;
}
.ui-card__header-copy { min-width: 0; }
.ui-card__title {
  margin: 0;
  font-size: 1.8rem;
  line-height: 0.98;
  letter-spacing: -0.03em;
}
.ui-card__subtitle {
  margin: 0.45rem 0 0;
  color: var(--text-soft);
}
.ui-card__actions { display: flex; justify-content: flex-end; }
.kpi {
  margin: 0;
  font-size: clamp(2.1rem, 4vw, 3rem);
  font-weight: 800;
  color: var(--color-wine);
}

.item {
  padding: 1rem;
  border-radius: var(--radius-md);
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.95), rgba(247, 241, 234, 0.95));
}

.button-row { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: center; }

.ui-button {
  appearance: none;
  border: 0;
  border-radius: var(--radius-pill);
  font-weight: 700;
  transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease, color 160ms ease;
}
.ui-button:hover { transform: translateY(-1px); }
.ui-button:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }
.ui-button--sm { padding: 0.55rem 0.95rem; font-size: 0.92rem; }
.ui-button--md { padding: 0.82rem 1.2rem; font-size: 0.96rem; }
.ui-button--lg { padding: 1rem 1.35rem; font-size: 1rem; }
.ui-button--full { width: 100%; justify-content: center; display: inline-flex; }
.ui-button--primary {
  color: var(--color-cream-strong);
  background: linear-gradient(135deg, #6c1a51, var(--color-wine));
  box-shadow: var(--shadow-glow);
}
.ui-button--secondary {
  color: var(--color-charcoal);
  background: linear-gradient(135deg, rgba(201, 162, 71, 0.92), rgba(219, 191, 116, 0.92));
  box-shadow: var(--shadow-soft);
}
.ui-button--ghost {
  color: var(--color-wine);
  background: rgba(120, 30, 90, 0.03);
  border: 1px solid var(--color-border);
}

.ui-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.34rem 0.7rem;
  border-radius: var(--radius-pill);
  font-size: 0.78rem;
  font-weight: 700;
  margin: 0 0.45rem 0.45rem 0;
  border: 1px solid transparent;
}
.ui-badge--default { background: rgba(120, 30, 90, 0.05); color: var(--color-wine); border-color: rgba(120, 30, 90, 0.08); }
.ui-badge--accent { background: rgba(201, 162, 71, 0.14); color: #775a17; border-color: rgba(201, 162, 71, 0.25); }
.ui-badge--success { background: rgba(111, 117, 89, 0.12); color: #4f5940; border-color: rgba(111, 117, 89, 0.24); }
.ui-badge--warning { background: rgba(201, 139, 134, 0.12); color: #8d5a55; border-color: rgba(201, 139, 134, 0.25); }

.form { gap: 1rem; }
.form-row { display: grid; gap: 0.45rem; }
.form-row label, .ui-field__label { font-size: 0.92rem; font-weight: 700; color: var(--text-main); }

input, textarea, select, .ui-input {
  width: 100%;
  padding: 0.82rem 0.95rem;
  border-radius: 16px;
  border: 1px solid rgba(120, 30, 90, 0.12);
  background: rgba(255, 252, 248, 0.92);
  color: var(--text-main);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.65);
}
input:focus, textarea:focus, select:focus, .ui-input:focus {
  outline: none;
  border-color: rgba(120, 30, 90, 0.32);
  box-shadow: 0 0 0 4px rgba(120, 30, 90, 0.08);
}

.error,
.success {
  padding: 0.95rem 1rem;
  border-radius: var(--radius-md);
  border: 1px solid;
  box-shadow: var(--shadow-soft);
}
.error { color: #7a2323; background: rgba(201, 139, 134, 0.14); border-color: rgba(201, 139, 134, 0.3); }
.success { color: #47573c; background: rgba(111, 117, 89, 0.14); border-color: rgba(111, 117, 89, 0.28); }

.auth-shell {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 2rem;
}
.auth-card {
  width: min(720px, 100%);
  background:
    linear-gradient(135deg, rgba(120, 30, 90, 0.06), rgba(201, 162, 71, 0.08)),
    linear-gradient(180deg, rgba(255, 251, 246, 0.99), rgba(247, 240, 233, 0.96));
}
.json-box {
  margin: 0;
  padding: 1rem;
  border-radius: var(--radius-md);
  overflow: auto;
  white-space: pre-wrap;
  font-size: 0.9rem;
  color: var(--color-wine);
}

.recommendation-card,
.restaurant-card,
.experience-card { height: 100%; }
.restaurant-card--active { border-color: var(--color-border-strong); box-shadow: var(--shadow-medium); }

.build-night-layout { grid-template-columns: 1.15fr 0.85fr; align-items: start; }
.build-section__copy p { margin: 0.35rem 0 0; }
.build-block-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 0.75rem; }
.build-block-grid--compact { grid-template-columns: repeat(auto-fit, minmax(110px, 1fr)); }
.build-block {
  text-align: left;
  padding: 0.9rem 0.95rem;
  border-radius: var(--radius-md);
  border: 1px solid rgba(120, 30, 90, 0.12);
  background: rgba(255, 252, 248, 0.92);
  transition: 160ms ease;
}
.build-block:hover { border-color: var(--color-border-strong); transform: translateY(-1px); }
.build-block.active {
  background: linear-gradient(135deg, rgba(120, 30, 90, 0.10), rgba(201, 162, 71, 0.14));
  border-color: var(--color-border-strong);
  box-shadow: var(--shadow-soft);
}
.build-block__label { display: block; font-weight: 700; color: var(--text-main); }
.build-block__hint { display: block; margin-top: 0.32rem; color: var(--text-soft); font-size: 0.84rem; }
.build-summary { padding: 1rem; border-radius: var(--radius-md); background: rgba(255,255,255,0.44); border: 1px solid rgba(120, 30, 90, 0.08); }

hr { border: 0; border-top: 1px solid rgba(120, 30, 90, 0.08); margin: 1rem 0; }

@media (max-width: 1100px) {
  .app-frame { grid-template-columns: 1fr; }
  .app-sidebar { position: static; height: auto; border-right: 0; border-bottom: 1px solid rgba(120,30,90,0.08); }
  .build-night-layout, .grid-3 { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 760px) {
  .app-navbar { padding: 1.4rem 1rem 0.75rem; flex-direction: column; }
  .page-shell { padding: 0.35rem 1rem 1.5rem; }
  .grid-2, .grid-3, .build-night-layout { grid-template-columns: 1fr; }
  .auth-shell { padding: 1rem; }
  .sidebar-brand { font-size: 1.7rem; }
  .navbar-title { font-size: 2.5rem; }
}
EOF_src_styles_css

echo 'Files updated. Running frontend verification...'
cd "$FRONTEND_DIR"
if [[ ! -d node_modules ]]; then
  echo 'node_modules not found. Running npm install...'
  npm install
fi

echo 'Running TypeScript build check...'
npm exec tsc -b

echo 'Running Vite production build...'
if ! node ./node_modules/vite/bin/vite.js build; then
  echo 'Initial Vite build failed. Refreshing frontend dependencies and retrying...'
  npm install
  node ./node_modules/vite/bin/vite.js build
fi

echo
echo 'SAVR frontend refresh applied successfully.'
echo 'Backup saved at:' "$BACKUP_DIR"
echo 'Frontend build completed successfully.'
