#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/josepablosamano/Desktop/COMP 3663 Soft Eng 2/Recomendations App/context-aware-dining-platform"
FRONTEND="$ROOT/frontend"

cd "$ROOT"

echo "== Ensure .gitignore has deploy artifact rules =="
touch .gitignore

grep -qxF 'node_modules/' .gitignore || echo 'node_modules/' >> .gitignore
grep -qxF 'frontend/node_modules/' .gitignore || echo 'frontend/node_modules/' >> .gitignore
grep -qxF 'frontend/dist/' .gitignore || echo 'frontend/dist/' >> .gitignore
grep -qxF 'backend/.venv/' .gitignore || echo 'backend/.venv/' >> .gitignore
grep -qxF '*.tsbuildinfo' .gitignore || echo '*.tsbuildinfo' >> .gitignore
grep -qxF '.DS_Store' .gitignore || echo '.DS_Store' >> .gitignore

echo "== Remove tracked artifacts from git index if present =="
git rm -r --cached node_modules 2>/dev/null || true
git rm -r --cached frontend/node_modules 2>/dev/null || true
git rm -r --cached frontend/dist 2>/dev/null || true
git rm -r --cached backend/.venv 2>/dev/null || true
git rm --cached frontend/tsconfig.app.tsbuildinfo 2>/dev/null || true
git rm --cached .DS_Store 2>/dev/null || true
git rm --cached backend/.DS_Store 2>/dev/null || true
git rm --cached backend/app/.DS_Store 2>/dev/null || true

echo "== Clean local frontend install state =="
rm -rf "$FRONTEND/node_modules"
rm -rf "$FRONTEND/dist"
rm -f "$FRONTEND/package-lock.json"
rm -f "$FRONTEND/tsconfig.app.tsbuildinfo"

echo "== Reinstall frontend dependencies cleanly =="
cd "$FRONTEND"
npm install

echo "== Verify production build locally =="
npm run build

echo "== Back to repo root =="
cd "$ROOT"

echo
echo "Done. Next:"
echo "  git status"
echo "  git add ."
echo '  git commit -m "Clean deploy artifacts and rebuild frontend lockfile"'
echo "  git push"
echo
echo "Then redeploy on Vercel WITHOUT cache."
