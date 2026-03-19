import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
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
      <Card
        className="auth-card"
        title="Welcome back"
        subtitle="Sign in to access your dining profile, onboarding, recommendation studio, and saved experience history."
        actions={<Badge tone="accent">Secure access</Badge>}
      >
        <div className="item">
          <strong>What you unlock</strong>
          <div style={{ marginTop: "0.8rem" }}>
            <Badge>Recommendations</Badge>
            <Badge tone="accent">Restaurant discovery</Badge>
            <Badge tone="success">Dining memory</Badge>
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
              placeholder="you@example.com"
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
            />
          </div>

          <Button type="submit" disabled={isSubmitting} fullWidth>
            {isSubmitting ? "Signing in..." : "Login"}
          </Button>
        </form>

        <div className="item">
          <strong>Need an account?</strong>
          <p className="muted" style={{ marginBottom: 0 }}>
            <Link to="/register">Create one here</Link>
          </p>
        </div>
      </Card>
    </div>
  );
}
