#!/bin/bash

echo "forcing backend to use sqlite for local development..."

BACKEND_DIR=$(pwd)
ENV_FILE="$BACKEND_DIR/.env"
DB_FILE="$BACKEND_DIR/app.db"

# create env if missing
if [ ! -f "$ENV_FILE" ]; then
    echo "creating backend .env"
    touch "$ENV_FILE"
fi

# remove postgres configs
sed -i '' '/DATABASE_URL/d' "$ENV_FILE"

# set sqlite database
echo "DATABASE_URL=sqlite:///$DB_FILE" >> "$ENV_FILE"

echo "database url set to sqlite"

# ensure db exists
if [ ! -f "$DB_FILE" ]; then
    echo "creating sqlite database file"
    touch "$DB_FILE"
fi

echo "rebuilding database schema..."

python - <<'PY'
from app.db.base import Base
from app.db.session import engine

Base.metadata.create_all(bind=engine)

print("database schema verified")
PY

echo "checking database tables..."

python - <<'PY'
import sqlite3

conn = sqlite3.connect("app.db")
cur = conn.cursor()

cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [t[0] for t in cur.fetchall()]

print("tables:", tables)

if "restaurants" not in tables:
    raise SystemExit("restaurants table missing")

print("sqlite database healthy")
conn.close()
PY

echo "sqlite dev database configured successfully"
