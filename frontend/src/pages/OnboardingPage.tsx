import { FormEvent, useMemo, useState } from 'react';

import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { brandContent } from '../config/content';
import { useAuth } from '../context/AuthContext';
import { apiRequest } from '../lib/api';
import { OnboardingPayload, OnboardingResponse } from '../types';

function splitList(value: string): string[] {
  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

export default function OnboardingPage() {
  const { refreshUser } = useAuth();

  const [form, setForm] = useState({
    dietary_restrictions: '',
    cuisine_preferences: 'italian, comfort-food',
    texture_preferences: 'creamy, crispy',
    dining_pace_preferences: 'leisurely',
    social_preferences: 'romantic',
    drink_preferences: 'cocktails, wine',
    atmosphere_preferences: 'cozy',
    favorite_dining_experiences: 'pasta night, cocktail date night',
    favorite_restaurants: 'Luna Trattoria',
    bio: 'I like cozy dinners with pasta and drinks.',
    spice_tolerance: 'medium',
    price_sensitivity: '$$'
  });

  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [submittedJson, setSubmittedJson] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const previewStats = useMemo(
    () => [
      { label: 'Cuisine cues', value: splitList(form.cuisine_preferences).length },
      { label: 'Drink cues', value: splitList(form.drink_preferences).length },
      { label: 'Atmosphere cues', value: splitList(form.atmosphere_preferences).length }
    ],
    [form]
  );

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setMessage('');
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
      const response = await apiRequest<OnboardingResponse>('/onboarding', {
        method: 'POST',
        body: payload
      });
      await refreshUser();
      setMessage(response.message || brandContent.microcopy.onboardingSuccess);
      setSubmittedJson(JSON.stringify(payload, null, 2));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save your taste profile');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="card">
        <p className="navbar-eyebrow">Taste Profile</p>
        <h1 className="page-title">Shape how SAVR curates your night</h1>
        <p className="muted" style={{ maxWidth: '780px', marginBottom: 0 }}>
          Use simple comma-separated inputs to describe the tastes, pacing, drinks, and memories that should guide future recommendations.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {message ? <div className="success">{message}</div> : null}

      <section className="grid grid-3">
        {previewStats.map((stat, index) => (
          <Card key={stat.label} title={stat.label} subtitle="Active signals" actions={<Badge tone={index === 1 ? 'accent' : index === 2 ? 'success' : 'default'}>{stat.label}</Badge>}>
            <p className="kpi">{stat.value}</p>
          </Card>
        ))}
      </section>

      <section className="grid grid-2">
        <Card title="Taste profile form" subtitle="All existing onboarding fields remain available" actions={<Badge tone="accent">Guided setup</Badge>}>
          <form className="form" onSubmit={handleSubmit}>
            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="cuisine_preferences">Cuisine preferences</label>
                <input id="cuisine_preferences" value={form.cuisine_preferences} onChange={(e) => setForm({ ...form, cuisine_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="texture_preferences">Texture preferences</label>
                <input id="texture_preferences" value={form.texture_preferences} onChange={(e) => setForm({ ...form, texture_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="dining_pace_preferences">Dining pace preferences</label>
                <input id="dining_pace_preferences" value={form.dining_pace_preferences} onChange={(e) => setForm({ ...form, dining_pace_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="social_preferences">Social preferences</label>
                <input id="social_preferences" value={form.social_preferences} onChange={(e) => setForm({ ...form, social_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="drink_preferences">Drink preferences</label>
                <input id="drink_preferences" value={form.drink_preferences} onChange={(e) => setForm({ ...form, drink_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="atmosphere_preferences">Atmosphere preferences</label>
                <input id="atmosphere_preferences" value={form.atmosphere_preferences} onChange={(e) => setForm({ ...form, atmosphere_preferences: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="dietary_restrictions">Dietary restrictions</label>
                <input id="dietary_restrictions" value={form.dietary_restrictions} onChange={(e) => setForm({ ...form, dietary_restrictions: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="spice_tolerance">Spice tolerance</label>
                <input id="spice_tolerance" value={form.spice_tolerance} onChange={(e) => setForm({ ...form, spice_tolerance: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="price_sensitivity">Price sensitivity</label>
                <input id="price_sensitivity" value={form.price_sensitivity} onChange={(e) => setForm({ ...form, price_sensitivity: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="favorite_restaurants">Favorite restaurants</label>
                <input id="favorite_restaurants" value={form.favorite_restaurants} onChange={(e) => setForm({ ...form, favorite_restaurants: e.target.value })} />
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="favorite_dining_experiences">Favorite dining experiences</label>
              <input id="favorite_dining_experiences" value={form.favorite_dining_experiences} onChange={(e) => setForm({ ...form, favorite_dining_experiences: e.target.value })} />
            </div>

            <div className="form-row">
              <label htmlFor="bio">Taste note</label>
              <textarea id="bio" rows={5} value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} />
            </div>

            <Button type="submit" disabled={isSubmitting}>{isSubmitting ? 'Saving profile...' : 'Save Taste Profile'}</Button>
          </form>
        </Card>

        <Card title="How SAVR reads this" subtitle="Your current payload preview" actions={<Badge>Live payload</Badge>}>
          <div className="list">
            <div className="item">
              <strong>Input style</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Comma-separated entries are split into arrays before being sent to the existing onboarding endpoint.</p>
            </div>
            <div className="item">
              <strong>Recommendation impact</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Cuisine, drink, atmosphere, and pace cues are used later by the recommendation flows without changing backend logic.</p>
            </div>
            {submittedJson ? (
              <pre className="json-box">{submittedJson}</pre>
            ) : (
              <div className="item">
                <strong>No payload submitted yet</strong>
                <p className="muted" style={{ marginBottom: 0 }}>Save the form once to preview the exact JSON sent to the API.</p>
              </div>
            )}
          </div>
        </Card>
      </section>
    </div>
  );
}
