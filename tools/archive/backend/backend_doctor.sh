#!/bin/bash
set -euo pipefail

echo "----- backend doctor starting -----"

if [ ! -d "app" ]; then
  echo "error: run this script from inside the backend folder"
  exit 1
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
backend_dir="$(pwd)"
project_root="$(cd .. && pwd)"
backend_env="${backend_dir}/.env"
root_env="${project_root}/.env"
config_file="${backend_dir}/app/core/config.py"
db_file="${backend_dir}/app.db"
backup_dir="${backend_dir}/backups/backend_doctor_${timestamp}"

mkdir -p "${backup_dir}"

echo "1. backing up critical files"
[ -f "${backend_env}" ] && cp "${backend_env}" "${backup_dir}/backend.env.bak" || true
[ -f "${root_env}" ] && cp "${root_env}" "${backup_dir}/root.env.bak" || true
cp "${config_file}" "${backup_dir}/config.py.bak"

echo "2. patching app/core/config.py to read backend/.env"
python3 <<'PY'
from pathlib import Path

path = Path("app/core/config.py")
content = path.read_text()

old_base = 'BASE_DIR = Path(__file__).resolve().parents[3]'
new_base = 'BASE_DIR = Path(__file__).resolve().parents[2]'

if old_base in content:
    content = content.replace(old_base, new_base)
elif new_base not in content:
    raise SystemExit("could not find expected BASE_DIR line in app/core/config.py")

path.write_text(content)
print("config.py patched successfully")
PY

echo "3. forcing both .env files to use sqlite:///./app.db"

mkdir -p "${project_root}"

write_env_file() {
  local target="$1"
  cat > "$target" <<'EOF'
JWT_SECRET_KEY=replace-this-with-a-long-random-secret
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=120
BACKEND_CORS_ORIGINS=["http://localhost:5173","http://127.0.0.1:5173"]
VITE_API_BASE_URL=http://127.0.0.1:8000/api
DATABASE_URL=sqlite:///./app.db
EOF
}

write_env_file "${backend_env}"
write_env_file "${root_env}"

echo "4. removing broken database"
rm -f "${db_file}"

echo "5. activating virtual environment"
source .venv/bin/activate

echo "6. confirming effective database url from settings"
python3 <<'PY'
from app.core.config import settings
print("effective DATABASE_URL =", settings.database_url)
if settings.database_url.strip() != "sqlite:///./app.db":
    raise SystemExit("settings still not using sqlite:///./app.db")
PY

echo "7. initializing database tables"
python3 -m app.db.init_db

echo "8. verifying database file exists"
if [ ! -f "${db_file}" ]; then
  echo "error: app.db was not created"
  exit 1
fi

echo "9. testing sqlite connection and listing tables"
python3 <<'PY'
import sqlite3

conn = sqlite3.connect("app.db")
cur = conn.cursor()

cur.execute("select name from sqlite_master where type='table' order by name;")
tables = [row[0] for row in cur.fetchall()]

print("tables found:", tables)

if not tables:
    raise SystemExit("no tables were created")

conn.close()
print("sqlite connection test passed")
PY

echo "----- backend doctor finished successfully -----"
