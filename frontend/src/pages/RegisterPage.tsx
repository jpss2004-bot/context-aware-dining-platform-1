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
