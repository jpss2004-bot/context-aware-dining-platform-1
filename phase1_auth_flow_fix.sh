#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" && -d "$ROOT_DIR/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" && -d "$ROOT_DIR/backend/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
else
  echo "Error: could not find frontend/src and backend/app from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

mkdir -p "$FRONTEND_DIR/src/components/layout"

cat > "$FRONTEND_DIR/src/pages/LoginPage.tsx" <<'EOF'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
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
        className="auth-card"
        title="Welcome back to SAVR"
        subtitle="Sign in to access your taste profile, curated matches, venue guide, and saved dining memories."
        actions={<Badge tone="accent">Secure access</Badge>}
      >
        <div className="item">
          <strong>What opens inside SAVR</strong>
          <div style={{ marginTop: "0.8rem", display: "flex", flexWrap: "wrap", gap: "0.5rem" }}>
            <Badge>Curated matches</Badge>
            <Badge tone="accent">Venue discovery</Badge>
            <Badge tone="success">Saved dining memories</Badge>
          </div>
        </div>

        {error ? <div className="error">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="jp@example.com"
              autoComplete="email"
            />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              autoComplete="current-password"
            />
            <small className="muted">{PASSWORD_HINT}</small>
          </div>

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Signing in..." : "Enter SAVR"}
          </Button>
        </form>

        <div className="item">
          <strong>New here?</strong>
          <p className="muted" style={{ marginBottom: "0.9rem" }}>
            Create your SAVR profile to unlock onboarding and personalized recommendations.
          </p>
          <Link className="ui-button ui-button--secondary ui-button--full" to="/register">
            Create your SAVR profile
          </Link>
        </div>
      </Card>
    </div>
  );
}
EOF

cat > "$FRONTEND_DIR/src/components/layout/ProtectedRoute.tsx" <<'EOF'
import { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";

import { useAuth } from "../../context/AuthContext";

type ProtectedRouteProps = {
  children: ReactNode;
  allowIncompleteOnboarding?: boolean;
  redirectCompletedUsersTo?: string | null;
};

export default function ProtectedRoute({
  children,
  allowIncompleteOnboarding = false,
  redirectCompletedUsersTo = null
}: ProtectedRouteProps) {
  const { token, user, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading...</div>
      </div>
    );
  }

  if (!token) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (!user) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading profile...</div>
      </div>
    );
  }

  if (!user.onboarding_completed && !allowIncompleteOnboarding) {
    return <Navigate to="/onboarding" replace state={{ from: location }} />;
  }

  if (user.onboarding_completed && redirectCompletedUsersTo) {
    return <Navigate to={redirectCompletedUsersTo} replace />;
  }

  return <>{children}</>;
}
EOF

cat > "$FRONTEND_DIR/src/App.tsx" <<'EOF'
import { Navigate, Route, Routes } from "react-router-dom";

import Layout from "./components/layout/Layout";
import ProtectedRoute from "./components/layout/ProtectedRoute";
import { useAuth } from "./context/AuthContext";
import DashboardPage from "./pages/DashboardPage";
import ExperiencesPage from "./pages/ExperiencesPage";
import LoginPage from "./pages/LoginPage";
import OnboardingPage from "./pages/OnboardingPage";
import RecommendationsPage from "./pages/RecommendationsPage";
import RegisterPage from "./pages/RegisterPage";
import RestaurantsPage from "./pages/RestaurantsPage";

function AppEntryRedirect() {
  const { token, user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading...</div>
      </div>
    );
  }

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  if (!user?.onboarding_completed) {
    return <Navigate to="/onboarding" replace />;
  }

  return <Navigate to="/dashboard" replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<AppEntryRedirect />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Layout>
              <DashboardPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/onboarding"
        element={
          <ProtectedRoute allowIncompleteOnboarding redirectCompletedUsersTo="/dashboard">
            <Layout>
              <OnboardingPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/recommendations"
        element={
          <ProtectedRoute>
            <Layout>
              <RecommendationsPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/experiences"
        element={
          <ProtectedRoute>
            <Layout>
              <ExperiencesPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/restaurants"
        element={
          <ProtectedRoute>
            <Layout>
              <RestaurantsPage />
            </Layout>
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<AppEntryRedirect />} />
    </Routes>
  );
}
EOF

python3 - <<PY
from pathlib import Path
path = Path(r"$FRONTEND_DIR/src/context/AuthContext.tsx")
text = path.read_text()

text = text.replace(
    "  login: (payload: LoginPayload) => Promise<void>;",
    "  login: (payload: LoginPayload) => Promise<AuthUser>;"
)

old = '''  const login = useCallback(async (payload: LoginPayload) => {
    const response = await apiRequest<TokenResponse>("/auth/login", {
      method: "POST",
      body: payload
    });

    setStoredToken(response.access_token);
    setToken(response.access_token);

    const me = await apiRequest<AuthUser>("/auth/me", {
      token: response.access_token
    });
    setUser(me);
  }, []);'''

new = '''  const login = useCallback(async (payload: LoginPayload) => {
    const response = await apiRequest<TokenResponse>("/auth/login", {
      method: "POST",
      body: payload
    });

    setStoredToken(response.access_token);
    setToken(response.access_token);

    const me = await apiRequest<AuthUser>("/auth/me", {
      token: response.access_token
    });
    setUser(me);
    return me;
  }, []);'''

if old not in text:
    raise SystemExit("Failed to update login function in AuthContext.tsx")

text = text.replace(old, new)
path.write_text(text)
PY

echo "Phase 1 fixes applied successfully in: $FRONTEND_DIR"
