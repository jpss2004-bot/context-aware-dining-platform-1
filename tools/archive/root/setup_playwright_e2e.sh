#!/usr/bin/env bash
set -e

echo "---------------------------------------------"
echo "Setting up Playwright end-to-end test system"
echo "---------------------------------------------"

# Ensure we are in project root
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
  echo "ERROR: Run this script from the project root."
  echo "Expected directories: backend/ frontend/"
  exit 1
fi

echo "Cleaning previous Playwright attempts..."

rm -rf tests
rm -f playwright.config.ts
rm -rf node_modules
rm -f package-lock.json

# Ensure package.json exists
if [ ! -f package.json ]; then
  echo "Creating new package.json"
  npm init -y >/dev/null
fi

echo "Installing Playwright..."

npm install -D @playwright/test >/dev/null

echo "Installing browsers..."

npx playwright install >/dev/null

echo "Creating test directory..."

mkdir -p tests

echo "Writing Playwright config..."

cat << 'EOF' > playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30000,

  use: {
    baseURL: 'http://localhost:5173',
    headless: true,
  },

  webServer: [
    {
      command: 'cd backend && uvicorn app.main:app --reload',
      port: 8000,
      reuseExistingServer: true,
    },
    {
      command: 'cd frontend && npm run dev',
      port: 5173,
      reuseExistingServer: true,
    }
  ]
});
EOF

echo "Writing full system test..."

cat << 'EOF' > tests/full-system.spec.ts
import { test, expect } from '@playwright/test';

const user = {
  first_name: "Test",
  last_name: "User",
  email: `test${Date.now()}@example.com`,
  password: "StrongPass123"
};

test("full platform workflow", async ({ page }) => {

  // Register
  await page.goto('/register');

  await page.fill('input[name="first_name"]', user.first_name);
  await page.fill('input[name="last_name"]', user.last_name);
  await page.fill('input[name="email"]', user.email);
  await page.fill('input[name="password"]', user.password);

  await page.click('button[type="submit"]');

  await page.waitForURL('**/dashboard');

  // Restaurants page
  await page.goto('/restaurants');

  const restaurants = page.locator('.restaurant-card');

  await expect(restaurants.first()).toBeVisible();

  // Restaurant detail
  await restaurants.first().click();

  await expect(page.locator('text=Menu')).toBeVisible();

  // Recommendations
  await page.goto('/recommendations');

  await page.fill('input[id="outing_type"]', 'casual dinner');
  await page.fill('input[id="preferred_cuisines"]', 'pizza');

  await page.click('button:has-text("Generate recommendations")');

  await expect(page.locator('.recommendation-card').first()).toBeVisible();

  // Surprise mode
  await page.click('button:has-text("Surprise Me")');
  await page.click('button:has-text("Surprise me")');

  await expect(page.locator('.recommendation-card').first()).toBeVisible();

  // Experiences
  await page.goto('/experiences');

  await expect(page.locator('text=Experiences')).toBeVisible();

});
EOF

echo "Updating package.json scripts..."

node <<'NODE'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json'));

pkg.scripts = pkg.scripts || {};
pkg.scripts["test:e2e"] = "playwright test";

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
NODE

echo ""
echo "---------------------------------------------"
echo "Playwright setup complete"
echo "---------------------------------------------"
echo ""
echo "To run tests:"
echo ""
echo "npm run test:e2e"
echo ""
echo "To watch the browser:"
echo ""
echo "npx playwright test --headed"
echo ""
