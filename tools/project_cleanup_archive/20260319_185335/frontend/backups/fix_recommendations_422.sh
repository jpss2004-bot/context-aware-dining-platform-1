#!/bin/zsh
set -e

echo "fixing recommendations 422 issue..."

perl -0pi -e 's/body: payload \? JSON\.stringify\(payload\) : undefined/body: payload/g' src/pages/RecommendationsPage.tsx

echo "running build..."
npm run build

echo "fix applied"
echo "start frontend with: npm run dev"

