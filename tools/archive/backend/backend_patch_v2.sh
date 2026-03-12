#!/bin/bash
set -e

echo "starting backend stabilization patch..."

# make sure we are in the backend root
if [ ! -d "app" ] || [ ! -f "requirements.txt" ]; then
  echo "error: run this script from the backend root directory"
  exit 1
fi

mkdir -p backups

timestamp=$(date +"%Y%m%d_%H%M%S")

echo "creating backups..."
cp requirements.txt "backups/requirements.txt.${timestamp}.bak"

if [ -f "app/api/deps.py" ]; then
  cp app/api/deps.py "backups/deps.py.${timestamp}.bak"
fi

if [ -f "app/core/security.py" ]; then
  cp app/core/security.py "backups/security.py.${timestamp}.bak"
fi

echo "patching requirements.txt to use a bcrypt version compatible with passlib..."
python3 - <<'PY'
from pathlib import Path

path = Path("requirements.txt")
text = path.read_text()

lines = text.splitlines()
new_lines = []
found_bcrypt = False

for line in lines:
    if line.strip().startswith("bcrypt=="):
        new_lines.append("bcrypt==4.0.1")
        found_bcrypt = True
    else:
        new_lines.append(line)

if not found_bcrypt:
    new_lines.append("bcrypt==4.0.1")

path.write_text("\n".join(new_lines) + "\n")
print("requirements.txt updated")
PY

echo "writing a safe default-user seed module..."
cat > app/db/seed_default_user.py <<'EOF'
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.user import User
from app.core.security import hash_password


DEFAULT_EMAIL = "jp@example.com"
DEFAULT_PASSWORD = "StrongPass123"


def seed_default_user() -> None:
    db: Session = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == DEFAULT_EMAIL.lower()).first()

        if existing:
            print(f"default user already exists: {DEFAULT_EMAIL}")
            return

        user = User(
            first_name="JP",
            last_name="Samano",
            email=DEFAULT_EMAIL.lower(),
            hashed_password=hash_password(DEFAULT_PASSWORD),
            is_active=True,
            onboarding_completed=False,
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        print(f"default user created: {DEFAULT_EMAIL}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_default_user()
EOF

echo "verifying app/api/deps.py exists and contains the expected auth dependency..."
python3 - <<'PY'
from pathlib import Path
import sys

deps_path = Path("app/api/deps.py")

if not deps_path.exists():
    print("error: app/api/deps.py does not exist")
    sys.exit(1)

text = deps_path.read_text()

required_snippets = [
    "OAuth2PasswordBearer",
    "tokenUrl=\"/api/auth/token\"",
    "def get_current_user",
    "decode_token",
    "UserRepository",
]

missing = [snippet for snippet in required_snippets if snippet not in text]

if missing:
    print("warning: app/api/deps.py is missing expected content:")
    for item in missing:
        print(f" - {item}")
else:
    print("app/api/deps.py looks structurally correct")
PY

echo "clearing python cache..."
find . -name "__pycache__" -type d -exec rm -rf {} + || true
find . -name "*.pyc" -delete || true

echo "updating bcrypt dependency in the active virtual environment..."
if [ -x ".venv/bin/pip" ]; then
  .venv/bin/pip install "bcrypt==4.0.1"
elif command -v pip >/dev/null 2>&1; then
  pip install "bcrypt==4.0.1"
else
  echo "warning: pip not found automatically; requirements were patched but bcrypt was not reinstalled yet"
fi

echo "running default user seed..."
if [ -x ".venv/bin/python" ]; then
  .venv/bin/python -m app.db.seed_default_user
else
  python3 -m app.db.seed_default_user
fi

echo ""
echo "patch complete"
echo ""
echo "next steps:"
echo "1. restart backend: uvicorn app.main:app --reload"
echo "2. open: http://127.0.0.1:8000/docs"
echo "3. test login with:"
echo "   email: jp@example.com"
echo "   password: StrongPass123"
