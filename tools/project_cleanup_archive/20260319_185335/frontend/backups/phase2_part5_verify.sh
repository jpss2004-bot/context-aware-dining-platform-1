#!/bin/zsh
set -e

echo "verifying phase 2 changes..."

echo "checking expected files..."
for file in \
  src/components/dining/RestaurantCard.tsx \
  src/components/dining/RecommendationCard.tsx \
  src/pages/DashboardPage.tsx \
  src/pages/RecommendationsPage.tsx
do
  if [ ! -f "$file" ]; then
    echo "missing file: $file"
    exit 1
  fi
done

echo "all phase 2 files are present"

echo "running build..."
npm run build

echo "phase 2 build passed"
echo "start the frontend with:"
echo "npm run dev"
