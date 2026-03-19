#!/usr/bin/env bash
set -euo pipefail

PATCH_NAME="patch6b_cleanup_legacy_recommendations"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Starting ${PATCH_NAME}..."

if [[ -d "frontend/src" && -f "frontend/package.json" ]]; then
  FRONTEND_DIR="$(pwd)/frontend"
elif [[ -d "src" && -f "package.json" ]]; then
  FRONTEND_DIR="$(pwd)"
else
  echo "ERROR: Could not find frontend directory."
  exit 1
fi

echo "Resolved frontend directory: ${FRONTEND_DIR}"
cd "${FRONTEND_DIR}"

mkdir -p "${BACKUP_DIR}"
echo "Creating backup at: ${FRONTEND_DIR}/${BACKUP_DIR}"

if [[ -f "src/pages/RecommendationsPage.tsx" ]]; then
  cp "src/pages/RecommendationsPage.tsx" "${BACKUP_DIR}/RecommendationsPage.tsx.bak"
fi

cat > src/pages/RecommendationsPage.tsx <<'EOF'
import { Navigate } from "react-router-dom";

export default function RecommendationsPage() {
  return <Navigate to="/recommendations" replace />;
}
EOF

echo "Running TypeScript check..."
if command -v npx >/dev/null 2>&1; then
  npx tsc -b
else
  echo "npx not found; skipping TypeScript check."
fi

echo
echo "Cleanup patch applied successfully."
echo "Next steps:"
echo "1) cd frontend"
echo "2) npm run dev"
echo "3) test /recommendations"
EOF
