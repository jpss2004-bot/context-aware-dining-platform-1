import { test, expect } from '@playwright/test';

test('full platform workflow', async ({ page }) => {

  await page.goto('http://localhost:5173');

  // Go to register page
  await page.getByRole('link', { name: /register/i }).click();

  // Fill register form
  await page.getByPlaceholder(/first/i).fill('Test');
  await page.getByPlaceholder(/last/i).fill('User');
  await page.getByPlaceholder(/email/i).fill(`test${Date.now()}@example.com`);
  await page.getByPlaceholder(/password/i).fill('StrongPass123');

  await page.getByRole('button', { name: /register/i }).click();

  // Dashboard
  await expect(page).toHaveURL(/dashboard/);

  // Restaurants page
  await page.goto('http://localhost:5173/restaurants');

  await expect(page.locator('.restaurant-card').first()).toBeVisible();

  // Recommendations
  await page.goto('http://localhost:5173/recommendations');

  await page.getByRole('button', { name: /generate/i }).click();

  await expect(page.locator('.recommendation-card').first()).toBeVisible();

});
