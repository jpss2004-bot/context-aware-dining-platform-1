#!/bin/bash

echo "Starting frontend restructuring..."

cd src || exit

echo "Creating new component architecture..."

mkdir -p components/layout
mkdir -p components/navigation
mkdir -p components/ui
mkdir -p components/dining

echo "Moving layout components..."

if [ -f components/Layout.tsx ]; then
  mv components/Layout.tsx components/layout/Layout.tsx
fi

if [ -f components/ProtectedRoute.tsx ]; then
  mv components/ProtectedRoute.tsx components/layout/ProtectedRoute.tsx
fi

echo "Creating placeholder navigation components..."

touch components/navigation/Navbar.tsx
touch components/navigation/Sidebar.tsx

echo "Creating reusable UI components..."

touch components/ui/Button.tsx
touch components/ui/Card.tsx
touch components/ui/Input.tsx
touch components/ui/Badge.tsx

echo "Creating dining feature components..."

touch components/dining/RestaurantCard.tsx
touch components/dining/ExperienceCard.tsx
touch components/dining/RecommendationCard.tsx

echo "Creating styles folder..."

mkdir -p styles

echo "Restructure complete."

echo "New structure:"

tree -L 3

echo "Done."
