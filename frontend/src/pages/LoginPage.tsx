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
