import { FormEvent, useEffect, useState } from 'react';

import ExperienceCard from '../components/dining/ExperienceCard';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { brandContent } from '../config/content';
import { apiRequest } from '../lib/api';
import { Experience, RestaurantListItem } from '../types';

export default function ExperiencesPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [experiences, setExperiences] = useState<Experience[]>([]);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({
    restaurant_id: '',
    title: 'Unforgettable dinner',
    occasion: 'date night',
    social_context: 'romantic',
    notes: 'Great pacing, strong atmosphere, and a menu I would come back for.',
    overall_rating: '4.5'
  });

  async function loadData() {
    try {
      setError('');
      setLoading(true);
      const [restaurantData, experienceData] = await Promise.all([
        apiRequest<RestaurantListItem[]>('/restaurants'),
        apiRequest<Experience[]>('/experiences')
      ]);
      setRestaurants(restaurantData);
      setExperiences(experienceData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load SAVR Log');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadData();
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setSuccess('');

    try {
      await apiRequest<Experience>('/experiences', {
        method: 'POST',
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
              category: 'overall',
              score: form.overall_rating ? Number(form.overall_rating) : 4
            }
          ]
        }
      });

      setSuccess(brandContent.microcopy.saveExperienceSuccess);
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save this SAVR Log entry');
    }
  }

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="card">
        <p className="navbar-eyebrow">SAVR Log</p>
        <h1 className="page-title">Save the nights worth remembering</h1>
        <p className="muted" style={{ maxWidth: '780px', marginBottom: 0 }}>
          Capture venue, context, notes, and ratings so SAVR can learn from the experiences you actually enjoyed.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}
      {success ? <div className="success">{success}</div> : null}

      <section className="grid grid-2">
        <Card title="Add a SAVR Log entry" subtitle="Record the meal, the context, and how it felt" actions={<Badge tone="accent">Journal</Badge>}>
          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label htmlFor="restaurant_id">Venue</label>
              <select id="restaurant_id" value={form.restaurant_id} onChange={(e) => setForm({ ...form, restaurant_id: e.target.value })}>
                <option value="">Select a venue</option>
                {restaurants.map((restaurant) => (
                  <option key={restaurant.id} value={restaurant.id}>{restaurant.name}</option>
                ))}
              </select>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="title">Entry title</label>
                <input id="title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="overall_rating">Overall rating</label>
                <input id="overall_rating" value={form.overall_rating} onChange={(e) => setForm({ ...form, overall_rating: e.target.value })} />
              </div>
            </div>

            <div className="grid grid-2">
              <div className="form-row">
                <label htmlFor="occasion">Occasion</label>
                <input id="occasion" value={form.occasion} onChange={(e) => setForm({ ...form, occasion: e.target.value })} />
              </div>
              <div className="form-row">
                <label htmlFor="social_context">Social context</label>
                <input id="social_context" value={form.social_context} onChange={(e) => setForm({ ...form, social_context: e.target.value })} />
              </div>
            </div>

            <div className="form-row">
              <label htmlFor="notes">Notes</label>
              <textarea id="notes" value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} rows={5} />
            </div>

            <Button type="submit">Save to SAVR Log</Button>
          </form>
        </Card>

        <Card title="Saved entries" subtitle="A running memory of real dining moments" actions={<Badge>{experiences.length} entries</Badge>}>
          {loading ? (
            <div className="item"><strong>Loading SAVR Log</strong><p className="muted" style={{ marginBottom: 0 }}>Pulling your saved entries from the backend.</p></div>
          ) : experiences.length === 0 ? (
            <div className="item"><strong>No entries yet</strong><p className="muted" style={{ marginBottom: 0 }}>Your first saved night will appear here.</p></div>
          ) : (
            <div className="list">
              {experiences.map((experience) => (
                <ExperienceCard key={experience.id} experience={experience} />
              ))}
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
