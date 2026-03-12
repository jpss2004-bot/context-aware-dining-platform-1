#!/bin/bash
set -e

echo "repairing backend environment..."

BACKEND_DIR="$(pwd)"
export PYTHONPATH="$BACKEND_DIR:$PYTHONPATH"

echo "initializing database schema..."

python - <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(".").resolve()))

from app.db.init_db import init_db

init_db()

print("database schema initialized")
PY

echo "running seed module..."

python - <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(".").resolve()))

from app.db.seed import seed_db

seed_db()

print("database seeded successfully")
PY

echo "verifying database using SQLAlchemy..."

python - <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(".").resolve()))

from sqlalchemy import text
from app.db.session import engine

with engine.connect() as conn:

    tables = conn.execute(text(
        "SELECT table_name FROM information_schema.tables WHERE table_schema='public'"
    )).fetchall()

    if not tables:
        try:
            tables = conn.execute(text(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )).fetchall()
        except:
            tables = []

    tables = [t[0] for t in tables]

    print("tables found:", tables)

    if "restaurants" not in tables:
        raise SystemExit("ERROR: restaurants table missing")

    r = conn.execute(text("SELECT COUNT(*) FROM restaurants")).scalar()
    m = conn.execute(text("SELECT COUNT(*) FROM menu_items")).scalar()
    t = conn.execute(text("SELECT COUNT(*) FROM tags")).scalar()

    print("restaurants:", r)
    print("menu_items:", m)
    print("tags:", t)

print("database verification successful")
PY

echo "backend repair completed successfully"
