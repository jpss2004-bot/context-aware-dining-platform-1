#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" && -d "$ROOT_DIR/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
  BACKEND_DIR="$ROOT_DIR/backend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" && -d "$ROOT_DIR/backend/backend/app" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
  BACKEND_DIR="$ROOT_DIR/backend/backend"
else
  echo "Could not find frontend/src and backend/app from ROOT_DIR=$ROOT_DIR"
  echo "Run this from the project root."
  exit 1
fi

echo "Project root: $ROOT_DIR"
echo "Frontend: $FRONTEND_DIR"
echo "Backend:  $BACKEND_DIR"

BACKUP_DIR="$ROOT_DIR/.repair_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${file#$ROOT_DIR/}")"
    cp "$file" "$BACKUP_DIR/${file#$ROOT_DIR/}"
  fi
}

backup_file "$FRONTEND_DIR/src/pages/RecommendationsPage.tsx"
backup_file "$FRONTEND_DIR/src/lib/api.ts"
backup_file "$FRONTEND_DIR/package.json"
backup_file "$BACKEND_DIR/requirements.txt"
backup_file "$ROOT_DIR/.gitignore"

python3 <<PY
from pathlib import Path
import json
import re

root = Path(r"$ROOT_DIR")
frontend = Path(r"$FRONTEND_DIR")
backend = Path(r"$BACKEND_DIR")

# -----------------------------
# 1) Fix RecommendationsPage.tsx
# -----------------------------
rec_file = frontend / "src/pages/RecommendationsPage.tsx"
text = rec_file.read_text(encoding="utf-8")

pattern = re.compile(
    r'''setSuccess\(\s*recs\.length > 0\s*\?\s*(?:`[^`]*`|"(?:[^"\\\\]|\\\\.)*"|'(?:[^'\\\\]|\\\\.)*'|)\s*:\s*"Request completed, but no surprise recommendations were returned\."\s*\);''',
    re.DOTALL
)

replacement = '''setSuccess(
        recs.length > 0
          ? `Generated ${recs.length} surprise recommendation${recs.length === 1 ? "" : "s"}.`
          : "Request completed, but no surprise recommendations were returned."
      );'''

new_text, count = pattern.subn(replacement, text, count=1)

if count == 0:
    anchor = 'const recs = Array.isArray(data.results) ? data.results : [];'
    idx = text.find(anchor)
    if idx == -1:
        raise SystemExit("Could not patch RecommendationsPage.tsx: expected surprise handler anchor not found.")
    success_anchor = 'setSuccess('
    start = text.find(success_anchor, idx)
    if start == -1:
        raise SystemExit("Could not patch RecommendationsPage.tsx: setSuccess call not found.")
    end = text.find(');', start)
    if end == -1:
        raise SystemExit("Could not patch RecommendationsPage.tsx: end of setSuccess call not found.")
    end += 2
    new_text = text[:start] + replacement + text[end:]

rec_file.write_text(new_text, encoding="utf-8")

# -----------------------------
# 2) Make frontend API base deploy-friendly
# -----------------------------
api_file = frontend / "src/lib/api.ts"
api_text = api_file.read_text(encoding="utf-8")

api_pattern = re.compile(
    r'''const API_BASE_URL =\s*\n\s*\(import\.meta as ImportMeta & \{ env: \{ VITE_API_BASE_URL\?: string \} \}\)\.env\.VITE_API_BASE_URL \|\|\s*\n\s*"http://127\.0\.0\.1:8000/api";''',
    re.DOTALL
)

api_replacement = '''const ENV_API_BASE_URL =
  (import.meta as ImportMeta & { env: { VITE_API_BASE_URL?: string } }).env.VITE_API_BASE_URL;

const API_BASE_URL =
  ENV_API_BASE_URL ||
  (typeof window !== "undefined" &&
  (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1")
    ? "http://127.0.0.1:8000/api"
    : `${window.location.origin}/api`);'''

api_text, api_count = api_pattern.subn(api_replacement, api_text, count=1)

if api_count == 0 and "const ENV_API_BASE_URL =" not in api_text:
    raise SystemExit("Could not patch src/lib/api.ts")

api_file.write_text(api_text, encoding="utf-8")

# -----------------------------
# 3) Pin frontend dependency versions for stable deploys
# -----------------------------
pkg_file = frontend / "package.json"
pkg = json.loads(pkg_file.read_text(encoding="utf-8"))

pkg["dependencies"] = {
    "react": "19.2.0",
    "react-dom": "19.2.0",
    "react-router-dom": "7.13.1"
}
pkg["devDependencies"] = {
    "@types/react": "19.2.14",
    "@types/react-dom": "19.2.3",
    "@vitejs/plugin-react": "5.1.4",
    "typescript": "5.9.3",
    "vite": "7.3.1"
}

pkg_file.write_text(json.dumps(pkg, indent=2) + "\n", encoding="utf-8")

# -----------------------------
# 4) Update backend dependency pin
# -----------------------------
req_file = backend / "requirements.txt"
req_text = req_file.read_text(encoding="utf-8")
req_text = req_text.replace("psycopg[binary]==3.2.1", "psycopg[binary]==3.2.12")
req_file.write_text(req_text, encoding="utf-8")

# -----------------------------
# 5) Add .gitignore
# -----------------------------
gitignore = root / ".gitignore"
gitignore.write_text(
"""# macOS
.DS_Store

# frontend
frontend/node_modules/
frontend/dist/
frontend/.vite/
frontend/.env.local
frontend/.env.production.local

# nested frontend fallback
frontend/frontend/node_modules/
frontend/frontend/dist/
frontend/frontend/.vite/

# backend
backend/.venv/
backend/__pycache__/
backend/.pytest_cache/
backend/*.pyc
backend/*.sqlite3

# nested backend fallback
backend/backend/.venv/
backend/backend/__pycache__/
backend/backend/.pytest_cache/

# python
__pycache__/
*.py[cod]

# env files
.env
.env.*
!.env.example
""",
    encoding="utf-8"
)

# -----------------------------
# 6) Create env examples
# -----------------------------
(frontend / ".env.example").write_text(
"""# For local development:
# VITE_API_BASE_URL=http://127.0.0.1:8000/api

# For same-domain deployment, leave this unset.
""",
    encoding="utf-8"
)

(backend / ".env.example").write_text(
"""JWT_SECRET_KEY=replace-with-a-long-random-secret
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=120
BACKEND_CORS_ORIGINS=["http://localhost:5173","http://127.0.0.1:5173"]
DATABASE_URL=sqlite:///./app.db
""",
    encoding="utf-8"
)

print("Patch phase completed.")
PY

echo
echo "Refreshing frontend dependencies..."
cd "$FRONTEND_DIR"
rm -rf node_modules package-lock.json
npm install

echo
echo "Running frontend build verification..."
npm run build

echo
echo "Setting up backend virtual environment..."
cd "$BACKEND_DIR"
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt

echo
echo "Running backend verification..."
python -m compileall app >/dev/null
python - <<'PY'
from app.main import app
print("Backend import OK:", app.title)
PY

echo
echo "Repair completed successfully."
echo "Backup saved to: $BACKUP_DIR"
echo
echo "Start backend:"
echo "  cd \"$BACKEND_DIR\""
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --reload"
echo
echo "Start frontend in a new terminal:"
echo "  cd \"$FRONTEND_DIR\""
echo "  npm run dev"
