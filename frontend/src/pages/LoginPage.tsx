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
