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
  echo "Error: could not find frontend/src and backend/app from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

BACKUP_DIR="$ROOT_DIR/.platform_fix_backup_$(date +%Y%m%d_%H%M%S)"
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

export ROOT_DIR FRONTEND_DIR BACKEND_DIR

python3 <<'PY'
from pathlib import Path
import json
import os

root = Path(os.environ["ROOT_DIR"])
frontend = Path(os.environ["FRONTEND_DIR"])
backend = Path(os.environ["BACKEND_DIR"])


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"Patch failed for {label}: expected block not found in {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


# 1) Fix the actual syntax error that is breaking Vite.
rec_path = frontend / "src/pages/RecommendationsPage.tsx"
replace_once(
    rec_path,
    '''      setSuccess(\n        recs.length > 0\n          ? \n          : "Request completed, but no surprise recommendations were returned."\n      );''',
    '''      setSuccess(\n        recs.length > 0\n          ? `Generated ${recs.length} surprise recommendation${recs.length === 1 ? "" : "s"}.`\n          : "Request completed, but no surprise recommendations were returned."\n      );''',
    "RecommendationsPage surprise success message",
)

# 2) Make API base URL safe for both localhost and same-domain deployment.
api_path = frontend / "src/lib/api.ts"
replace_once(
    api_path,
    '''const API_BASE_URL =\n  (import.meta as ImportMeta & { env: { VITE_API_BASE_URL?: string } }).env.VITE_API_BASE_URL ||\n  "http://127.0.0.1:8000/api";\n''',
    '''const ENV_API_BASE_URL =\n  (import.meta as ImportMeta & { env: { VITE_API_BASE_URL?: string } }).env.VITE_API_BASE_URL;\n\nconst API_BASE_URL =\n  ENV_API_BASE_URL ||\n  (typeof window !== "undefined" &&\n  (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1")\n    ? "http://127.0.0.1:8000/api"\n    : `${window.location.origin}/api`);\n''',
    "frontend API base URL",
)

# 3) Pin frontend versions so installs are reproducible instead of depending on latest.
pkg_path = frontend / "package.json"
pkg = json.loads(pkg_path.read_text(encoding="utf-8"))
pkg["dependencies"] = {
    "react": "19.2.0",
    "react-dom": "19.2.0",
    "react-router-dom": "7.9.3",
}
pkg["devDependencies"] = {
    "@types/react": "19.2.2",
    "@types/react-dom": "19.2.2",
    "@vitejs/plugin-react": "5.0.4",
    "typescript": "5.9.2",
    "vite": "7.1.7",
}
pkg_path.write_text(json.dumps(pkg, indent=2) + "\n", encoding="utf-8")

# 4) Fix backend dependency that currently blocks clean installs.
req_path = backend / "requirements.txt"
req_text = req_path.read_text(encoding="utf-8")
if "psycopg[binary]==3.2.1" in req_text:
    req_text = req_text.replace("psycopg[binary]==3.2.1", "psycopg[binary]==3.2.13")
req_path.write_text(req_text, encoding="utf-8")

# 5) Create a sane .gitignore so deploy artifacts stop polluting the repo.
(root / ".gitignore").write_text(
    '''# macOS\n.DS_Store\n\n# frontend\nfrontend/node_modules/\nfrontend/dist/\nfrontend/.vite/\nfrontend/.env.local\nfrontend/.env.production.local\n\n# backend\nbackend/.venv/\nbackend/.venv_test/\nbackend/__pycache__/\nbackend/.pytest_cache/\nbackend/*.pyc\nbackend/*.sqlite3\n\n# general python\n__pycache__/\n*.py[cod]\n\n# env files\n.env\n.env.*\n!.env.example\n''',
    encoding="utf-8",
)

# 6) Provide env examples for deployment.
(frontend / ".env.example").write_text(
    '''# Local development only:\n# VITE_API_BASE_URL=http://127.0.0.1:8000/api\n\n# For same-domain deployment, leave this unset.\n''',
    encoding="utf-8",
)

(backend / ".env.example").write_text(
    '''DATABASE_URL=sqlite:///./app.db\nJWT_SECRET_KEY=replace-this-with-a-long-random-secret\nJWT_ALGORITHM=HS256\nJWT_ACCESS_TOKEN_EXPIRE_MINUTES=120\nBACKEND_CORS_ORIGINS=["http://localhost:5173","http://127.0.0.1:5173"]\n''',
    encoding="utf-8",
)

print("Patch phase completed successfully.")
PY

echo
echo "Cleaning frontend install state..."
cd "$FRONTEND_DIR"
rm -rf node_modules package-lock.json
npm install

echo
echo "Running frontend production build..."
npm run build

echo
echo "Creating backend virtual environment..."
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
print('Backend import OK:', app.title)
PY

echo
echo "Fix complete. Backup saved to: $BACKUP_DIR"
echo
echo "Start backend:"
echo "  cd \"$BACKEND_DIR\""
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --reload"
echo
echo "Start frontend in a new terminal:"
echo "  cd \"$FRONTEND_DIR\""
echo "  npm run dev"
