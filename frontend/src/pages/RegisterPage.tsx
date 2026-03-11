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
