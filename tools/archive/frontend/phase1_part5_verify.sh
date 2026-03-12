#!/bin/zsh
set -e

echo "verifying phase 1 changes..."

echo "checking expected files..."
for file in \
  src/components/layout/Layout.tsx \
  src/components/navigation/Navbar.tsx \
  src/components/navigation/Sidebar.tsx \
  src/components/ui/Button.tsx \
  src/components/ui/Card.tsx \
  src/components/ui/Input.tsx \
  src/components/ui/Badge.tsx \
  src/styles.css
do
  if [ ! -f "$file" ]; then
    echo "missing file: $file"
    exit 1
  fi
done

echo "all phase 1 files are present"

echo "running build..."
npm run build

echo "phase 1 build passed"
echo "start the frontend with:"
echo "npm run dev"
