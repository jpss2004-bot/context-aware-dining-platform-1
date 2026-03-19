#!/bin/zsh
set -e

echo "verifying phase 4 changes..."

echo "checking expected files..."
for file in \
  src/styles.css \
  src/components/layout/Layout.tsx \
  src/components/navigation/Navbar.tsx \
  src/components/navigation/Sidebar.tsx \
  src/components/ui/Button.tsx \
  src/components/ui/Card.tsx \
  src/components/ui/Input.tsx \
  src/components/ui/Badge.tsx \
  src/components/dining/RestaurantCard.tsx \
  src/components/dining/RecommendationCard.tsx \
  src/components/dining/ExperienceCard.tsx \
  src/pages/DashboardPage.tsx \
  src/pages/RecommendationsPage.tsx \
  src/pages/RestaurantsPage.tsx \
  src/pages/ExperiencesPage.tsx \
  src/pages/OnboardingPage.tsx \
  src/pages/LoginPage.tsx \
  src/pages/RegisterPage.tsx
do
  if [ ! -f "$file" ]; then
    echo "missing file: $file"
    exit 1
  fi
done

echo "all phase 4 files are present"

echo "running final build..."
npm run build

echo "phase 4 build passed"
echo "start the frontend with:"
echo "npm run dev"
