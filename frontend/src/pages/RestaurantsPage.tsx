import { useEffect, useMemo, useState } from 'react';

import RestaurantCard from '../components/dining/RestaurantCard';
import Badge from '../components/ui/Badge';
import Card from '../components/ui/Card';
import { apiRequest } from '../lib/api';
import { RestaurantDetail, RestaurantListItem } from '../types';

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<RestaurantListItem[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<RestaurantDetail | null>(null);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [error, setError] = useState('');
  const [loadingList, setLoadingList] = useState(true);
  const [loadingDetail, setLoadingDetail] = useState(false);

  useEffect(() => {
    void loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      setError('');
      setLoadingList(true);
      const data = await apiRequest<RestaurantListItem[]>('/restaurants');
      setRestaurants(data);
      if (data.length > 0 && selectedId === null) {
        void loadRestaurantDetail(data[0].id);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'We could not load the venue guide.');
    } finally {
      setLoadingList(false);
    }
  }

  async function loadRestaurantDetail(restaurantId: number) {
    try {
      setError('');
      setLoadingDetail(true);
      setSelectedId(restaurantId);
      const data = await apiRequest<RestaurantDetail>(`/restaurants/${restaurantId}`);
      setSelectedRestaurant(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'We could not load this venue.');
    } finally {
      setLoadingDetail(false);
    }
  }

  const summaryText = useMemo(() => {
    if (!selectedRestaurant) {
      return 'Choose a venue to inspect its menu, tags, atmosphere, and recommendation signals.';
    }

    return selectedRestaurant.description || 'No summary is available for this venue yet.';
  }, [selectedRestaurant]);

  return (
    <div className="grid" style={{ gap: '1.25rem' }}>
      <section className="card">
        <p className="navbar-eyebrow">Venue Guide</p>
        <h1 className="page-title">Browse the places SAVR can recommend</h1>
        <p className="muted" style={{ maxWidth: '780px', marginBottom: 0 }}>
          Compare restaurants in a research-first layout that keeps the catalog on one side and a detailed venue profile on the other.
        </p>
      </section>

      {error ? <div className="error">{error}</div> : null}

      <section className="grid grid-2">
        <Card title="Available venues" subtitle="Loaded directly from the backend catalog" actions={<Badge>{restaurants.length} venues</Badge>}>
          {loadingList ? (
            <div className="item">
              <strong>Loading the venue guide</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Pulling available restaurants from the API.</p>
            </div>
          ) : restaurants.length === 0 ? (
            <div className="item">
              <strong>No venues are available</strong>
              <p className="muted" style={{ marginBottom: 0 }}>The backend returned an empty catalog.</p>
            </div>
          ) : (
            <div className="list">
              {restaurants.map((restaurant) => (
                <RestaurantCard key={restaurant.id} restaurant={restaurant} onSelect={(restaurantId) => void loadRestaurantDetail(restaurantId)} isActive={selectedId === restaurant.id} />
              ))}
            </div>
          )}
        </Card>

        <Card title={selectedRestaurant?.name || 'Venue detail'} subtitle={summaryText} actions={selectedRestaurant ? <Badge tone="accent">{selectedRestaurant.price_tier}</Badge> : <Badge>Preview</Badge>}>
          {!selectedRestaurant ? (
            <div className="item">
              <strong>No venue selected</strong>
              <p className="muted" style={{ marginBottom: 0 }}>Choose a venue from the guide to inspect its full profile.</p>
            </div>
          ) : (
            <div className="list">
              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: '0.4rem' }}>Venue profile</p>
                <strong>Atmosphere and positioning</strong>
                <p className="muted">{selectedRestaurant.city} • {selectedRestaurant.price_tier} • {selectedRestaurant.atmosphere || 'No atmosphere'} • {selectedRestaurant.pace || 'No pace'} • {selectedRestaurant.social_style || 'No social style'}</p>
                <div>
                  {selectedRestaurant.tags.map((tag) => (
                    <Badge key={`${tag.category}-${tag.name}`}>{tag.category}: {tag.name}</Badge>
                  ))}
                </div>
              </div>

              <div className="item">
                <p className="navbar-eyebrow" style={{ marginBottom: '0.4rem' }}>Menu signals</p>
                <strong>Menu items</strong>
                {loadingDetail ? (
                  <p className="muted">Loading venue detail...</p>
                ) : selectedRestaurant.menu_items.length === 0 ? (
                  <p className="muted" style={{ marginBottom: 0 }}>No menu items were returned for this venue.</p>
                ) : (
                  <div className="list" style={{ marginTop: '0.8rem' }}>
                    {selectedRestaurant.menu_items.map((item) => (
                      <div className="item" key={item.id}>
                        <strong>{item.name}</strong>
                        <p className="muted">{item.category} • Price: {item.price ?? '-'} • {item.is_signature ? 'Signature item' : 'Standard item'}</p>
                        <p style={{ marginBottom: item.tags.length > 0 ? '0.8rem' : 0 }}>{item.description || 'No description'}</p>
                        {item.tags.length > 0 ? (
                          <div>
                            {item.tags.map((tag) => (
                              <Badge key={`${item.id}-${tag.id}`} tone="accent">{tag.name}</Badge>
                            ))}
                          </div>
                        ) : null}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </Card>
      </section>
    </div>
  );
}
