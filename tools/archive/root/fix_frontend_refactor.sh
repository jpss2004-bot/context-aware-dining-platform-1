#!/bin/zsh

set -e

echo "starting frontend refactor repair..."

PROJECT_ROOT="$(pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
SRC_DIR="$FRONTEND_DIR/src"

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "error: frontend directory not found at $FRONTEND_DIR"
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "error: frontend/src directory not found at $SRC_DIR"
  exit 1
fi

echo "frontend found at: $FRONTEND_DIR"

REQUIRED_FILES=(
  "$SRC_DIR/components/layout/Layout.tsx"
  "$SRC_DIR/components/layout/ProtectedRoute.tsx"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "error: missing expected file -> $file"
    exit 1
  fi
done

echo "required layout files exist"
echo "fixing import paths..."

FILE_GLOB=("*.ts" "*.tsx" "*.js" "*.jsx")

for pattern in "${FILE_GLOB[@]}"; do
  find "$SRC_DIR" -type f -name "$pattern" -print0 | while IFS= read -r -d '' file; do
    perl -0pi -e 's#(["'"'"'])\./components/ProtectedRoute\1#${1}./components/layout/ProtectedRoute${1}#g' "$file"
    perl -0pi -e 's#(["'"'"'])\.\./components/ProtectedRoute\1#${1}../components/layout/ProtectedRoute${1}#g' "$file"
    perl -0pi -e 's#(["'"'"'])components/ProtectedRoute\1#${1}components/layout/ProtectedRoute${1}#g' "$file"

    perl -0pi -e 's#(["'"'"'])\./components/Layout\1#${1}./components/layout/Layout${1}#g' "$file"
    perl -0pi -e 's#(["'"'"'])\.\./components/Layout\1#${1}../components/layout/Layout${1}#g' "$file"
    perl -0pi -e 's#(["'"'"'])components/Layout\1#${1}components/layout/Layout${1}#g' "$file"
  done
done

echo "fixing moved-file relative imports..."

find "$SRC_DIR/components/layout" -type f \( -name "*.ts" -o -name "*.tsx" \) -print0 | while IFS= read -r -d '' file; do
  perl -0pi -e 's#\.\./context/AuthContext#../../context/AuthContext#g' "$file"
  perl -0pi -e 's#\.\./lib/#../../lib/#g' "$file"
  perl -0pi -e 's#\.\./types#../../types#g' "$file"
  perl -0pi -e 's#\.\./styles\.css#../../styles.css#g' "$file"
done

echo "checking for leftover old imports..."
LEFTOVERS=$(grep -RInE 'components/(Layout|ProtectedRoute)' "$SRC_DIR" || true)

if [ -n "$LEFTOVERS" ]; then
  echo "warning: some old-style imports may still remain:"
  echo "$LEFTOVERS"
else
  echo "no old import paths found"
fi

echo "running vite build..."
cd "$FRONTEND_DIR"

if [ ! -d node_modules ]; then
  npm install
fi

npm run build
echo "build succeeded"

echo "starting dev server..."
npm run dev
