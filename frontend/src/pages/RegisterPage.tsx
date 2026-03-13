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
