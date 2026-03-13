#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
else
  echo "Error: could not find frontend/src from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

cat > "$FRONTEND_DIR/src/pages/LoginPage.tsx" <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import PasswordField from "../components/forms/PasswordField";
import { useAuth } from "../context/AuthContext";

const PASSWORD_HINT = "Passwords must be between 8 and 128 characters.";

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      const authenticatedUser = await login({ email, password });
      navigate(authenticatedUser.onboarding_completed ? "/dashboard" : "/onboarding", {
        replace: true
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <Card
        className="auth-card auth-card--focused"
        title="Welcome to SAVR"
        subtitle="Log in with your existing account or create a new one to start building a more personal dining experience."
        actions={<Badge tone="accent">Login</Badge>}
      >
        <div className="auth-intro-block">
          <strong>Two clear paths</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            Use your existing account to continue, or create a new account if this is your first time using SAVR.
          </p>
        </div>

        {error ? <div className="error">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              autoComplete="email"
            />
          </div>

          <PasswordField
            label="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            autoComplete="current-password"
            hint={PASSWORD_HINT}
          />

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Signing in..." : "Log in"}
          </Button>
        </form>

        <div className="auth-switch-card">
          <strong>Create a new account</strong>
          <p className="muted" style={{ marginBottom: "0.85rem" }}>
            New to SAVR? Create an account to build your dining profile and start exploring recommendations.
          </p>
          <Link className="ui-button ui-button--secondary ui-button--md ui-button--full" to="/register">
            Create my account
          </Link>
        </div>
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/pages/RegisterPage.tsx" <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import PasswordField from "../components/forms/PasswordField";
import { useAuth } from "../context/AuthContext";

const PASSWORD_HINT = "Passwords must be between 8 and 128 characters.";

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();

  const [form, setForm] = useState({
    first_name: "",
    last_name: "",
    email: "",
    password: ""
  });
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");
    setIsSubmitting(true);

    try {
      await register(form);
      setSuccess("Account created successfully. Redirecting you to login...");
      setTimeout(() => navigate("/login"), 900);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <Card
        className="auth-card auth-card--focused"
        title="Create your SAVR account"
        subtitle="Create an account first, then complete your profile so SAVR can start personalizing restaurant and experience recommendations."
        actions={<Badge tone="accent">Register</Badge>}
      >
        <div className="auth-intro-block">
          <strong>Start simple</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            First create your account. After that, you will be guided into the profile setup flow.
          </p>
        </div>

        {error ? <div className="error">{error}</div> : null}
        {success ? <div className="success">{success}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="grid grid-2 auth-grid-compact">
            <div className="form-row">
              <label htmlFor="first_name">First name</label>
              <input
                id="first_name"
                value={form.first_name}
                onChange={(e) => setForm({ ...form, first_name: e.target.value })}
                placeholder="First name"
                autoComplete="given-name"
              />
            </div>

            <div className="form-row">
              <label htmlFor="last_name">Last name</label>
              <input
                id="last_name"
                value={form.last_name}
                onChange={(e) => setForm({ ...form, last_name: e.target.value })}
                placeholder="Last name"
                autoComplete="family-name"
              />
            </div>
          </div>

          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              placeholder="Enter your email"
              autoComplete="email"
            />
          </div>

          <PasswordField
            label="Password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            placeholder="Create a password"
            autoComplete="new-password"
            hint={PASSWORD_HINT}
          />

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Creating account..." : "Create my account"}
          </Button>
        </form>

        <div className="auth-switch-card">
          <strong>Already have an account?</strong>
          <p className="muted" style={{ marginBottom: "0.85rem" }}>
            Go back to the login page and continue with your existing SAVR account.
          </p>
          <Link className="ui-button ui-button--ghost ui-button--md ui-button--full" to="/login">
            Go to login
          </Link>
        </div>
      </Card>
    </div>
  );
}
EOF

python3 - <<PY
from pathlib import Path

styles_path = Path(r"$FRONTEND_DIR/src/styles.css")
text = styles_path.read_text()

marker = "/* PHASE 8 UI ACCESSIBILITY AND RELEASE READINESS */"
if marker not in text:
    text += """

/* PHASE 8 UI ACCESSIBILITY AND RELEASE READINESS */
:root {
  color-scheme: dark;
}

body {
  line-height: 1.5;
}

p,
label,
small,
span,
button,
input,
select,
textarea {
  color: inherit;
}

input,
select,
textarea {
  color: #f8fafc;
  background: rgba(8, 15, 28, 0.92);
  border: 1px solid rgba(148, 163, 184, 0.22);
}

input::placeholder,
textarea::placeholder {
  color: rgba(226, 232, 240, 0.62);
}

input:focus,
select:focus,
textarea:focus {
  border-color: rgba(96, 165, 250, 0.5);
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.14);
}

.muted {
  color: rgba(226, 232, 240, 0.82) !important;
}

.card,
.ui-card,
.auth-card,
.item {
  color: #f8fafc;
}

.navbar-subtitle,
.sidebar-profile-card .muted,
.auth-switch-card .muted,
.auth-intro-block .muted {
  color: rgba(226, 232, 240, 0.8) !important;
}

.badge,
.ui-badge {
  color: #f8fafc;
}

.dashboard-chip,
.experience-rating-pill,
.segmented-option,
.rating-selector,
.multi-select-chip {
  color: #f8fafc;
}

.auth-shell {
  padding: 2rem 1rem;
}

.auth-card {
  max-width: 34rem;
  width: 100%;
  margin: 0 auto;
}

.auth-card--focused .ui-card__body,
.auth-card--focused {
  gap: 1rem;
}

.auth-intro-block {
  border: 1px solid rgba(148, 163, 184, 0.14);
  background: rgba(15, 23, 42, 0.54);
  border-radius: 1rem;
  padding: 1rem;
}

.auth-grid-compact {
  align-items: start;
}

.password-input-shell {
  background: rgba(8, 15, 28, 0.92);
  border: 1px solid rgba(148, 163, 184, 0.22);
}

.password-input-shell__input {
  color: #f8fafc;
}

.password-toggle {
  background: rgba(37, 99, 235, 0.18);
  color: #f8fafc;
}

.password-toggle:hover {
  background: rgba(37, 99, 235, 0.28);
}

.segmented-option {
  background: rgba(15, 23, 42, 0.72);
  border-color: rgba(148, 163, 184, 0.2);
}

.segmented-option--active {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.3), rgba(139, 92, 246, 0.22));
  border-color: rgba(125, 211, 252, 0.56);
}

.rating-selector {
  background: rgba(15, 23, 42, 0.72);
  border-color: rgba(148, 163, 184, 0.2);
  color: #f8fafc;
}

.rating-selector--active {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.3), rgba(139, 92, 246, 0.22));
  border-color: rgba(125, 211, 252, 0.56);
}

.multi-select-chip {
  background: rgba(15, 23, 42, 0.72);
  border-color: rgba(148, 163, 184, 0.2);
  color: #f8fafc;
}

.multi-select-chip--active {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.3), rgba(139, 92, 246, 0.22));
  border-color: rgba(125, 211, 252, 0.56);
}

.experience-rating-pill,
.dashboard-chip {
  background: rgba(15, 23, 42, 0.76);
  border-color: rgba(148, 163, 184, 0.18);
  color: #f8fafc;
}

.error,
.success {
  color: #f8fafc;
  line-height: 1.5;
}

.button-row {
  gap: 0.75rem;
}

.button-row .ui-button,
.button-row button,
.button-row a {
  min-height: 2.75rem;
}

.app-navbar,
.app-sidebar,
.card,
.ui-card {
  backdrop-filter: blur(12px);
}

.ui-card__body,
.card {
  gap: 1rem;
}

.grid.grid-2 > .card,
.grid.grid-2 > section,
.grid.grid-2 > div,
.grid.grid-3 > .card {
  min-width: 0;
}

@media (max-width: 1100px) {
  .grid.grid-3 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .app-navbar {
    gap: 1rem;
  }

  .navbar-right {
    width: 100%;
    justify-content: flex-start;
    flex-wrap: wrap;
  }
}

@media (max-width: 900px) {
  .grid.grid-2,
  .grid.grid-3 {
    grid-template-columns: 1fr;
  }

  .page-title {
    font-size: clamp(1.65rem, 5vw, 2.3rem);
  }

  .app-navbar {
    padding: 1rem;
  }

  .navbar-copy {
    min-width: 0;
  }

  .navbar-title,
  .navbar-subtitle {
    max-width: 100%;
  }
}

@media (max-width: 760px) {
  .auth-shell {
    padding: 1rem 0.85rem 1.5rem;
  }

  .auth-card {
    max-width: 100%;
  }

  .auth-grid-compact {
    grid-template-columns: 1fr;
  }

  .button-row {
    display: grid;
    grid-template-columns: 1fr;
  }

  .button-row > * {
    width: 100%;
  }

  .button-row .ui-button {
    width: 100%;
    justify-content: center;
  }

  .navbar-right {
    display: grid;
    grid-template-columns: 1fr;
    gap: 0.75rem;
  }

  .navbar-date-chip,
  .navbar-meta-card {
    width: 100%;
  }

  .sidebar-brand-block,
  .sidebar-profile-card,
  .sidebar-nav,
  .sidebar-quick-actions,
  .sidebar-footer {
    width: 100%;
  }

  .card,
  .ui-card,
  .item,
  .auth-switch-card,
  .auth-intro-block {
    border-radius: 0.95rem;
  }

  .segmented-option-grid,
  .rating-selector-row,
  .multi-select-grid {
    gap: 0.55rem;
  }

  .segmented-option,
  .rating-selector,
  .multi-select-chip {
    font-size: 0.95rem;
  }
}

@media (max-width: 520px) {
  .page-title {
    font-size: 1.5rem;
  }

  .navbar-title {
    font-size: 1.35rem;
  }

  .kpi {
    font-size: 1.8rem;
  }

  .sidebar-link__icon {
    min-width: 2rem;
    min-height: 2rem;
  }
}
"""
    styles_path.write_text(text)
PY

echo "Phase 8 UI accessibility and release-readiness pass applied successfully in: $FRONTEND_DIR"
echo "Updated files:"
echo " - src/pages/LoginPage.tsx"
echo " - src/pages/RegisterPage.tsx"
echo " - src/styles.css"
