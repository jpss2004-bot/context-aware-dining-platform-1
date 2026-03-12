#!/bin/bash

set -e

if [ ! -d "frontend/src" ]; then
  echo "error: run this from inside the context-aware-dining-platform folder"
  exit 1
fi

cat > frontend/package.json <<'JSON'
{
  "name": "context-aware-dining-frontend",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "latest",
    "react-dom": "latest",
    "react-router-dom": "latest"
  },
  "devDependencies": {
    "@types/react": "latest",
    "@types/react-dom": "latest",
    "@vitejs/plugin-react": "latest",
    "typescript": "latest",
    "vite": "latest"
  }
}
JSON

cat > frontend/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Context-Aware Dining Platform</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
HTML

cat > frontend/tsconfig.json <<'JSON'
{
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" }
  ]
}
JSON

cat > frontend/tsconfig.app.json <<'JSON'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "Bundler",
    "allowImportingTsExtensions": false,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "baseUrl": "./src"
  },
  "include": ["src"]
}
JSON

cat > frontend/vite.config.ts <<'TS'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173
  }
});
TS

cat > frontend/src/main.tsx <<'TS'
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";

import App from "./App";
import { AuthProvider } from "./context/AuthContext";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App />
      </AuthProvider>
    </BrowserRouter>
  </React.StrictMode>
);
TS

cat > frontend/src/App.tsx <<'TS'
import { Navigate, Route, Routes } from "react-router-dom";

import Layout from "./components/Layout";
import ProtectedRoute from "./components/ProtectedRoute";
import DashboardPage from "./pages/DashboardPage";
import ExperiencesPage from "./pages/ExperiencesPage";
import LoginPage from "./pages/LoginPage";
import OnboardingPage from "./pages/OnboardingPage";
import RecommendationsPage from "./pages/RecommendationsPage";
import RegisterPage from "./pages/RegisterPage";
import RestaurantsPage from "./pages/RestaurantsPage";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
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
          <ProtectedRoute>
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

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
TS

cat > frontend/src/styles.css <<'CSS'
:root {
  font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #111827;
  background: #f3f4f6;
  line-height: 1.5;
  font-weight: 400;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
  background: #f3f4f6;
  color: #111827;
}

a {
  color: inherit;
  text-decoration: none;
}

button,
input,
textarea,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

.page-shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.topbar {
  background: #111827;
  color: white;
  padding: 1rem 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.brand {
  font-size: 1.1rem;
  font-weight: 700;
}

.nav-links {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.nav-link {
  padding: 0.5rem 0.8rem;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
}

.nav-link:hover {
  background: rgba(255, 255, 255, 0.16);
}

.page-content {
  width: min(1100px, calc(100% - 2rem));
  margin: 1.5rem auto 2rem;
}

.card {
  background: white;
  border-radius: 16px;
  padding: 1.25rem;
  box-shadow: 0 8px 24px rgba(17, 24, 39, 0.08);
  margin-bottom: 1rem;
}

.grid {
  display: grid;
  gap: 1rem;
}

.grid-2 {
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
}

.grid-3 {
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.page-title {
  margin: 0 0 0.5rem;
  font-size: 1.9rem;
  font-weight: 800;
}

.muted {
  color: #6b7280;
}

.form {
  display: grid;
  gap: 0.9rem;
}

.form-row {
  display: grid;
  gap: 0.35rem;
}

.form-row label {
  font-weight: 600;
}

.form-row input,
.form-row textarea,
.form-row select {
  width: 100%;
  border: 1px solid #d1d5db;
  border-radius: 10px;
  padding: 0.75rem 0.9rem;
  background: white;
}

.form-row textarea {
  min-height: 110px;
  resize: vertical;
}

.button {
  border: none;
  border-radius: 12px;
  padding: 0.8rem 1rem;
  background: #2563eb;
  color: white;
  font-weight: 700;
}

.button.secondary {
  background: #374151;
}

.button.ghost {
  background: #e5e7eb;
  color: #111827;
}

.button-row {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.error {
  color: #b91c1c;
  background: #fee2e2;
  border: 1px solid #fecaca;
  border-radius: 10px;
  padding: 0.75rem 0.9rem;
}

.success {
  color: #166534;
  background: #dcfce7;
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  padding: 0.75rem 0.9rem;
}

.auth-shell {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 1.5rem;
  background: linear-gradient(180deg, #eff6ff 0%, #f3f4f6 100%);
}

.auth-card {
  width: min(460px, 100%);
  background: white;
  border-radius: 18px;
  padding: 1.5rem;
  box-shadow: 0 12px 32px rgba(17, 24, 39, 0.12);
}

.list {
  display: grid;
  gap: 0.8rem;
}

.item {
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 1rem;
}

.pill {
  display: inline-block;
  background: #dbeafe;
  color: #1d4ed8;
  border-radius: 999px;
  padding: 0.25rem 0.65rem;
  font-size: 0.85rem;
  margin-right: 0.4rem;
  margin-bottom: 0.4rem;
}

.kpi {
  font-size: 2rem;
  font-weight: 800;
  margin: 0;
}

pre.json-box {
  background: #0f172a;
  color: #e2e8f0;
  border-radius: 12px;
  padding: 1rem;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
}

@media (max-width: 640px) {
  .page-content {
    width: min(100% - 1rem, 1100px);
    margin: 1rem auto 1.5rem;
  }

  .topbar {
    padding: 1rem;
  }
}
CSS

cat > frontend/src/types.ts <<'TS'
export type AuthUser = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  onboarding_completed: boolean;
};

export type UserProfileResponse = {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  is_active: boolean;
  onboarding_completed: boolean;
  created_at: string;
};

export type TokenResponse = {
  access_token: string;
  token_type: string;
};

export type RestaurantListItem = {
  id: number;
  name: string;
  description: string | null;
  city: string;
  price_tier: string;
  atmosphere: string | null;
  pace: string | null;
  social_style: string | null;
  serves_alcohol: boolean;
};

export type Tag = {
  id: number;
  name: string;
  category: string;
};

export type MenuItem = {
  id: number;
  restaurant_id: number;
  name: string;
  category: string;
  price: number | null;
  description: string | null;
  is_signature: boolean;
  tags: Tag[];
};

export type RestaurantDetail = RestaurantListItem & {
  tags: Tag[];
  menu_items: MenuItem[];
};

export type OnboardingPayload = {
  dietary_restrictions: string[];
  cuisine_preferences: string[];
  texture_preferences: string[];
  dining_pace_preferences: string[];
  social_preferences: string[];
  drink_preferences: string[];
  atmosphere_preferences: string[];
  favorite_dining_experiences: string[];
  favorite_restaurants: string[];
  bio: string | null;
  spice_tolerance: string | null;
  price_sensitivity: string | null;
};

export type OnboardingResponse = {
  message: string;
  onboarding_completed: boolean;
};

export type RecommendationItem = {
  restaurant_id: number;
  restaurant_name: string;
  score: number;
  reasons: string[];
  suggested_dishes: string[];
  suggested_drinks: string[];
};

export type RecommendationResponse = {
  mode: string;
  results: RecommendationItem[];
};

export type ExperienceRating = {
  id: number;
  category: string;
  score: number;
};

export type Experience = {
  id: number;
  user_id: number;
  restaurant_id: number | null;
  title: string | null;
  occasion: string | null;
  social_context: string | null;
  notes: string | null;
  overall_rating: number | null;
  created_at: string;
  ratings: ExperienceRating[];
};
TS

cat > frontend/src/lib/auth.ts <<'TS'
const TOKEN_KEY = "cadp_access_token";

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setStoredToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearStoredToken(): void {
  localStorage.removeItem(TOKEN_KEY);
}
TS

cat > frontend/src/lib/api.ts <<'TS'
import { clearStoredToken, getStoredToken } from "./auth";

const API_BASE_URL =
  (import.meta as ImportMeta & { env: { VITE_API_BASE_URL?: string } }).env.VITE_API_BASE_URL ||
  "http://127.0.0.1:8000/api";

type RequestOptions = {
  method?: string;
  body?: unknown;
  token?: string | null;
  headers?: Record<string, string>;
};

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const token = options.token ?? getStoredToken();

  const headers: Record<string, string> = {
    ...(options.body !== undefined ? { "Content-Type": "application/json" } : {}),
    ...options.headers
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: options.method ?? "GET",
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined
  });

  if (!response.ok) {
    let message = "Request failed";
    try {
      const errorPayload = await response.json();
      message = errorPayload.detail || JSON.stringify(errorPayload);
    } catch {
      message = await response.text();
    }

    if (response.status === 401) {
      clearStoredToken();
    }

    throw new Error(message || "Request failed");
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}
TS

cat > frontend/src/context/AuthContext.tsx <<'TS'
import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useState } from "react";

import { apiRequest } from "../lib/api";
import { clearStoredToken, getStoredToken, setStoredToken } from "../lib/auth";
import { AuthUser, TokenResponse } from "../types";

type RegisterPayload = {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
};

type LoginPayload = {
  email: string;
  password: string;
};

type AuthContextValue = {
  user: AuthUser | null;
  token: string | null;
  isLoading: boolean;
  register: (payload: RegisterPayload) => Promise<void>;
  login: (payload: LoginPayload) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(getStoredToken());
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshUser = useCallback(async () => {
    const currentToken = getStoredToken();
    if (!currentToken) {
      setUser(null);
      setToken(null);
      setIsLoading(false);
      return;
    }

    try {
      const me = await apiRequest<AuthUser>("/auth/me", { token: currentToken });
      setUser(me);
      setToken(currentToken);
    } catch {
      clearStoredToken();
      setUser(null);
      setToken(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshUser();
  }, [refreshUser]);

  const register = useCallback(async (payload: RegisterPayload) => {
    await apiRequest<AuthUser>("/auth/register", {
      method: "POST",
      body: payload
    });
  }, []);

  const login = useCallback(async (payload: LoginPayload) => {
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
  }, []);

  const logout = useCallback(() => {
    clearStoredToken();
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      isLoading,
      register,
      login,
      logout,
      refreshUser
    }),
    [user, token, isLoading, register, login, logout, refreshUser]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used inside AuthProvider");
  }
  return context;
}
TS

cat > frontend/src/components/Layout.tsx <<'TS'
import { ReactNode } from "react";
import { NavLink, useNavigate } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

export default function Layout({ children }: { children: ReactNode }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="page-shell">
      <header className="topbar">
        <div>
          <div className="brand">Context-Aware Dining Platform</div>
          <div className="muted">
            {user ? `Signed in as ${user.first_name} ${user.last_name}` : "Not signed in"}
          </div>
        </div>

        <nav className="nav-links">
          <NavLink className="nav-link" to="/dashboard">
            Dashboard
          </NavLink>
          <NavLink className="nav-link" to="/onboarding">
            Onboarding
          </NavLink>
          <NavLink className="nav-link" to="/recommendations">
            Recommendations
          </NavLink>
          <NavLink className="nav-link" to="/restaurants">
            Restaurants
          </NavLink>
          <NavLink className="nav-link" to="/experiences">
            Experiences
          </NavLink>
          <button className="nav-link" onClick={handleLogout} type="button">
            Logout
          </button>
        </nav>
      </header>

      <main className="page-content">{children}</main>
    </div>
  );
}
TS

cat > frontend/src/components/ProtectedRoute.tsx <<'TS'
import { ReactNode } from "react";
import { Navigate } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

export default function ProtectedRoute({ children }: { children: ReactNode }) {
  const { token, isLoading } = useAuth();

  if (isLoading) {
    return <div className="auth-shell"><div className="auth-card">Loading...</div></div>;
  }

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
TS

cat > frontend/src/pages/LoginPage.tsx <<'TS'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("jp@example.com");
  const [password, setPassword] = useState("StrongPass123");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await login({ email, password });
      navigate("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="page-title">Login</h1>
        <p className="muted">Sign in to access your dining profile, onboarding, and recommendations.</p>

        {error ? <div className="error">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input id="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button className="button" disabled={isSubmitting} type="submit">
            {isSubmitting ? "Signing in..." : "Login"}
          </button>
        </form>

        <p>
          Need an account? <Link to="/register">Register here</Link>
        </p>
      </div>
    </div>
  );
}
TS

cat > frontend/src/pages/RegisterPage.tsx <<'TS'
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

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
      setSuccess("Account created successfully. You can now log in.");
      setTimeout(() => navigate("/login"), 900);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="page-title">Create account</h1>
        <p className="muted">Set up your account to save dining preferences and recommendation history.</p>

        {error ? <div className="error">{error}</div> : null}
        {success ? <div className="success">{success}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="grid grid-2">
            <div className="form-row">
              <label htmlFor="first_name">First name</label>
              <input
                id="first_name"
                value={form.first_name}
                onChange={(e) => setForm({ ...form, first_name: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label htmlFor="last_name">Last name</label>
              <input
                id="last_name"
                value={form.last_name}
                onChange={(e) => setForm({ ...form, last_name: e.target.value })}
              />
            </div>
          </div>

          <div className="form-row">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
          </div>

          <div className="form-row">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
            />
          </div>

          <button className="button" disabled={isSubmitting} type="submit">
            {isSubmitting ? "Creating..." : "Register"}
          </button>
        </form>

        <p>
          Already have an account? <Link to="/login">Go to login</Link>
        </p>
      </div>
    </div>
  );
}
TS

cat > frontend/src/pages/DashboardPage.tsx <<'TS'
import { Link } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

export default function DashboardPage() {
  const { user } = useAuth();

  return (
    <>
      <section className="card">
        <h1 className="page-title">Dashboard</h1>
        <p className="muted">
          Welcome back{user ? `, ${user.first_name}` : ""}. Your backend is connected and ready.
        </p>
      </section>

      <section className="grid grid-3">
        <div className="card">
          <p className="kpi">{user?.onboarding_completed ? "Done" : "Pending"}</p>
          <p className="muted">Onboarding status</p>
          <Link to="/onboarding">Go to onboarding</Link>
        </div>

        <div className="card">
          <p className="kpi">3 Modes</p>
          <p className="muted">Recommendation flows supported</p>
          <Link to="/recommendations">Open recommendations</Link>
        </div>

        <div className="card">
          <p className="kpi">Seeded</p>
          <p className="muted">Restaurant dataset loaded</p>
          <Link to="/restaurants">Browse restaurants</Link>
        </div>
      </section>

      <section className="card">
        <h2>Next useful actions</h2>
        <div className="button-row">
          <Link className="button" to="/onboarding">
            Complete onboarding
          </Link>
          <Link className="button secondary" to="/recommendations">
            Get recommendations
          </Link>
          <Link className="button ghost" to="/experiences">
            Log an experience
          </Link>
        </div>
      </section>
    </>
  );
}
TS

cat > frontend/src/pages/OnboardingPage.tsx <<'TS'
import { FormEvent, useState } from "react";

import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../lib/api";
import { OnboardingPayload, OnboardingResponse } from "../types";

function splitList(value: string): string[] {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

export default function OnboardingPage() {
  const { refreshUser } = useAuth();

  const [form, setForm] = useState({
    dietary_restrictions: "",
    cuisine_preferences: "italian, comfort-food",
    texture_preferences: "creamy, crispy",
    dining_pace_preferences: "leisurely",
    social_preferences: "romantic",
    drink_preferences: "cocktails, wine",
    atmosphere_preferences: "cozy",
    favorite_dining_experiences: "pasta night, cocktail date night",
    favorite_restaurants: "Luna Trattoria",
    bio: "I like cozy dinners with pasta and drinks.",
    spice_tolerance: "medium",
    price_sensitivity: "$$"
  });

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [submittedJson, setSubmittedJson] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setMessage("");
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
      const response = await apiRequest<OnboardingResponse>("/onboarding", {
        method: "POST",
        body: payload
      });
      await refreshUser();
      setMessage(response.message);
      setSubmittedJson(JSON.stringify(payload, null, 2));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save onboarding");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Let&apos;s get to know you</h1>
        <p className="muted">
          Enter comma-separated values for preference lists. This page writes directly to your working backend.
        </p>
      </section>

      <section className="card">
        {error ? <div className="error">{error}</div> : null}
        {message ? <div className="success">{message}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <div className="grid grid-2">
            <div className="form-row">
              <label>Dietary restrictions</label>
              <input
                value={form.dietary_restrictions}
                onChange={(e) => setForm({ ...form, dietary_restrictions: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Cuisine preferences</label>
              <input
                value={form.cuisine_preferences}
                onChange={(e) => setForm({ ...form, cuisine_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Texture preferences</label>
              <input
                value={form.texture_preferences}
                onChange={(e) => setForm({ ...form, texture_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Dining pace preferences</label>
              <input
                value={form.dining_pace_preferences}
                onChange={(e) => setForm({ ...form, dining_pace_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Social preferences</label>
              <input
                value={form.social_preferences}
                onChange={(e) => setForm({ ...form, social_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Drink preferences</label>
              <input
                value={form.drink_preferences}
                onChange={(e) => setForm({ ...form, drink_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Atmosphere preferences</label>
              <input
                value={form.atmosphere_preferences}
                onChange={(e) => setForm({ ...form, atmosphere_preferences: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Favorite restaurants</label>
              <input
                value={form.favorite_restaurants}
                onChange={(e) => setForm({ ...form, favorite_restaurants: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Spice tolerance</label>
              <input
                value={form.spice_tolerance}
                onChange={(e) => setForm({ ...form, spice_tolerance: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Price sensitivity</label>
              <input
                value={form.price_sensitivity}
                onChange={(e) => setForm({ ...form, price_sensitivity: e.target.value })}
              />
            </div>
          </div>

          <div className="form-row">
            <label>Favorite dining experiences</label>
            <input
              value={form.favorite_dining_experiences}
              onChange={(e) => setForm({ ...form, favorite_dining_experiences: e.target.value })}
            />
          </div>

          <div className="form-row">
            <label>Bio</label>
            <textarea value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} />
          </div>

          <button className="button" disabled={isSubmitting} type="submit">
            {isSubmitting ? "Saving..." : "Save onboarding"}
          </button>
        </form>
      </section>

      {submittedJson ? (
        <section className="card">
          <h2>Last submitted payload</h2>
          <pre className="json-box">{submittedJson}</pre>
        </section>
      ) : null}
    </>
  );
}
TS

cat > frontend/src/pages/RecommendationsPage.tsx <<'TS'
import { FormEvent, useState } from "react";

import { apiRequest } from "../lib/api";
import { RecommendationResponse } from "../types";

function parseList(value: string): string[] {
  return value.split(",").map((item) => item.trim()).filter(Boolean);
}

export default function RecommendationsPage() {
  const [error, setError] = useState("");
  const [result, setResult] = useState<RecommendationResponse | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const [buildForm, setBuildForm] = useState({
    outing_type: "romantic dinner",
    mood: "cozy",
    budget: "$$",
    pace: "leisurely",
    social_context: "romantic",
    preferred_cuisines: "italian, comfort-food",
    drinks_focus: true,
    atmosphere: "cozy, romantic"
  });

  const [describePrompt, setDescribePrompt] = useState(
    "I want a cozy romantic dinner with pasta and drinks."
  );

  async function runBuild(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const response = await apiRequest<RecommendationResponse>("/recommendations/build-your-night", {
        method: "POST",
        body: {
          outing_type: buildForm.outing_type,
          mood: buildForm.mood,
          budget: buildForm.budget,
          pace: buildForm.pace,
          social_context: buildForm.social_context,
          preferred_cuisines: parseList(buildForm.preferred_cuisines),
          drinks_focus: buildForm.drinks_focus,
          atmosphere: parseList(buildForm.atmosphere)
        }
      });
      setResult(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get recommendations");
    } finally {
      setIsLoading(false);
    }
  }

  async function runDescribe(event: FormEvent) {
    event.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const response = await apiRequest<RecommendationResponse>("/recommendations/describe-your-night", {
        method: "POST",
        body: {
          prompt: describePrompt
        }
      });
      setResult(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get recommendations");
    } finally {
      setIsLoading(false);
    }
  }

  async function runSurprise() {
    setError("");
    setIsLoading(true);

    try {
      const response = await apiRequest<RecommendationResponse>("/recommendations/surprise-me", {
        method: "POST",
        body: {
          include_drinks: true
        }
      });
      setResult(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get recommendations");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Recommendations</h1>
        <p className="muted">Use the same backend recommendation routes you already verified in Swagger.</p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <div className="card">
          <h2>Build Your Night</h2>
          <form className="form" onSubmit={runBuild}>
            <div className="form-row">
              <label>Outing type</label>
              <input
                value={buildForm.outing_type}
                onChange={(e) => setBuildForm({ ...buildForm, outing_type: e.target.value })}
              />
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label>Mood</label>
                <input
                  value={buildForm.mood}
                  onChange={(e) => setBuildForm({ ...buildForm, mood: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Budget</label>
                <input
                  value={buildForm.budget}
                  onChange={(e) => setBuildForm({ ...buildForm, budget: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Pace</label>
                <input
                  value={buildForm.pace}
                  onChange={(e) => setBuildForm({ ...buildForm, pace: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Social context</label>
                <input
                  value={buildForm.social_context}
                  onChange={(e) => setBuildForm({ ...buildForm, social_context: e.target.value })}
                />
              </div>
            </div>

            <div className="form-row">
              <label>Preferred cuisines</label>
              <input
                value={buildForm.preferred_cuisines}
                onChange={(e) => setBuildForm({ ...buildForm, preferred_cuisines: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Atmosphere</label>
              <input
                value={buildForm.atmosphere}
                onChange={(e) => setBuildForm({ ...buildForm, atmosphere: e.target.value })}
              />
            </div>

            <label>
              <input
                checked={buildForm.drinks_focus}
                onChange={(e) => setBuildForm({ ...buildForm, drinks_focus: e.target.checked })}
                type="checkbox"
              />{" "}
              Drinks focus
            </label>

            <button className="button" disabled={isLoading} type="submit">
              {isLoading ? "Loading..." : "Run build-your-night"}
            </button>
          </form>
        </div>

        <div className="card">
          <h2>Describe Your Night</h2>
          <form className="form" onSubmit={runDescribe}>
            <div className="form-row">
              <label>Prompt</label>
              <textarea value={describePrompt} onChange={(e) => setDescribePrompt(e.target.value)} />
            </div>

            <button className="button secondary" disabled={isLoading} type="submit">
              {isLoading ? "Loading..." : "Run describe-your-night"}
            </button>
          </form>

          <hr />

          <h2>Surprise Me</h2>
          <p className="muted">Use saved onboarding preferences plus experience history.</p>
          <button className="button ghost" disabled={isLoading} onClick={runSurprise} type="button">
            {isLoading ? "Loading..." : "Run surprise-me"}
          </button>
        </div>
      </section>

      {result ? (
        <section className="card">
          <h2>Recommendation results</h2>
          <div className="list">
            {result.results.map((item) => (
              <div className="item" key={`${result.mode}-${item.restaurant_id}`}>
                <h3>
                  {item.restaurant_name} — score {item.score}
                </h3>

                <div>
                  {item.reasons.map((reason) => (
                    <span className="pill" key={reason}>
                      {reason}
                    </span>
                  ))}
                </div>

                {item.suggested_dishes.length ? (
                  <p>
                    <strong>Dishes:</strong> {item.suggested_dishes.join(", ")}
                  </p>
                ) : null}

                {item.suggested_drinks.length ? (
                  <p>
                    <strong>Drinks:</strong> {item.suggested_drinks.join(", ")}
                  </p>
                ) : null}
              </div>
            ))}
          </div>
        </section>
      ) : null}
    </>
  );
}
TS

cat > frontend/src/pages/ExperiencesPage.tsx <<'TS'
import { FormEvent, useEffect, useState } from "react";

import { apiRequest } from "../lib/api";
import { Experience, RestaurantListItem } from "../types";

export default function ExperiencesPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const [form, setForm] = useState({
    restaurant_id: "",
    title: "Great dinner",
    occasion: "date night",
    social_context: "romantic",
    notes: "Really enjoyed the pasta and drinks.",
    overall_rating: "4.5"
  });

  async function loadData() {
    try {
      const [restaurantData, experienceData] = await Promise.all([
        apiRequest<RestaurantListItem[]>("/restaurants"),
        apiRequest<Experience[]>("/experiences")
      ]);
      setRestaurants(restaurantData);
      setExperiences(experienceData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load experiences");
    }
  }

  useEffect(() => {
    void loadData();
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setSuccess("");

    try {
      await apiRequest<Experience>("/experiences", {
        method: "POST",
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
              category: "overall",
              score: form.overall_rating ? Number(form.overall_rating) : 4
            }
          ]
        }
      });

      setSuccess("Experience saved successfully");
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save experience");
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Experiences</h1>
        <p className="muted">Create a dining log entry and review your saved history.</p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <div className="card">
          <h2>Log a new experience</h2>

          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label>Restaurant</label>
              <select
                value={form.restaurant_id}
                onChange={(e) => setForm({ ...form, restaurant_id: e.target.value })}
              >
                <option value="">Select a restaurant</option>
                {restaurants.map((restaurant) => (
                  <option key={restaurant.id} value={restaurant.id}>
                    {restaurant.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-row">
              <label>Title</label>
              <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label>Occasion</label>
                <input
                  value={form.occasion}
                  onChange={(e) => setForm({ ...form, occasion: e.target.value })}
                />
              </div>

              <div className="form-row">
                <label>Social context</label>
                <input
                  value={form.social_context}
                  onChange={(e) => setForm({ ...form, social_context: e.target.value })}
                />
              </div>
            </div>

            <div className="form-row">
              <label>Overall rating</label>
              <input
                value={form.overall_rating}
                onChange={(e) => setForm({ ...form, overall_rating: e.target.value })}
              />
            </div>

            <div className="form-row">
              <label>Notes</label>
              <textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
            </div>

            <button className="button" type="submit">
              Save experience
            </button>
          </form>
        </div>

        <div className="card">
          <h2>Saved experiences</h2>
          <div className="list">
            {experiences.length === 0 ? (
              <div className="item">No experiences logged yet.</div>
            ) : (
              experiences.map((experience) => (
                <div className="item" key={experience.id}>
                  <strong>{experience.title || "Untitled experience"}</strong>
                  <p className="muted">
                    Occasion: {experience.occasion || "-"} | Social: {experience.social_context || "-"}
                  </p>
                  <p>Overall rating: {experience.overall_rating ?? "-"}</p>
                  <p>{experience.notes || "No notes"}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </section>
    </>
  );
}
TS

cat > frontend/src/pages/RestaurantsPage.tsx <<'TS'
import { useEffect, useState } from "react";

import { apiRequest } from "../lib/api";
import { RestaurantDetail, RestaurantListItem } from "../types";

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<RestaurantDetail | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    void loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      const data = await apiRequest<RestaurantListItem[]>("/restaurants");
      setRestaurants(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurants");
    }
  }

  async function loadRestaurantDetail(restaurantId: number) {
    try {
      const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
      setSelectedRestaurant(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load restaurant detail");
    }
  }

  return (
    <>
      <section className="card">
        <h1 className="page-title">Restaurants</h1>
        <p className="muted">Browse the seeded restaurants and inspect details from the backend.</p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <div className="card">
          <h2>Available restaurants</h2>
          <div className="list">
            {restaurants.map((restaurant) => (
              <div className="item" key={restaurant.id}>
                <h3>{restaurant.name}</h3>
                <p>{restaurant.description || "No description"}</p>
                <p className="muted">
                  {restaurant.city} • {restaurant.price_tier} • {restaurant.atmosphere || "No atmosphere tag"}
                </p>
                <button
                  className="button ghost"
                  onClick={() => void loadRestaurantDetail(restaurant.id)}
                  type="button"
                >
                  View details
                </button>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <h2>Restaurant detail</h2>
          {!selectedRestaurant ? (
            <div className="item">Select a restaurant to view details.</div>
          ) : (
            <div className="item">
              <h3>{selectedRestaurant.name}</h3>
              <p>{selectedRestaurant.description || "No description"}</p>
              <p className="muted">
                {selectedRestaurant.city} • {selectedRestaurant.price_tier} •{" "}
                {selectedRestaurant.atmosphere || "No atmosphere"}
              </p>

              <div>
                {selectedRestaurant.tags.map((tag) => (
                  <span className="pill" key={`${tag.category}-${tag.name}`}>
                    {tag.category}: {tag.name}
                  </span>
                ))}
              </div>

              <h4>Menu items</h4>
              <div className="list">
                {selectedRestaurant.menu_items.map((item) => (
                  <div className="item" key={item.id}>
                    <strong>{item.name}</strong> — {item.category}
                    <p>{item.description || "No description"}</p>
                    <p className="muted">Price: {item.price ?? "-"}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </section>
    </>
  );
}
TS

echo "frontend files written successfully"
