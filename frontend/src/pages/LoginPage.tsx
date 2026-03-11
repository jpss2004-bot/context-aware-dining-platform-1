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
