#!/bin/bash

echo "----- Backend Database Repair Script -----"

echo "1. backing up .env"
cp .env .env.backup.$(date +%s)

echo "2. fixing DATABASE_URL"
sed -i '' 's|DATABASE_URL=.*|DATABASE_URL=sqlite:///./app.db|' .env

echo "3. removing broken database if exists"
rm -f app.db

echo "4. activating virtual environment"
source .venv/bin/activate

echo "5. reinstalling critical packages"
pip install --quiet sqlalchemy pydantic pydantic-settings

echo "6. initializing database"
python3 -m app.db.init_db

echo "7. verifying database file"
if [ -f "app.db" ]; then
    echo "Database created successfully"
else
    echo "Database creation failed"
    exit 1
fi

echo "8. running quick connection test"
python3 << END
from sqlalchemy import create_engine
engine = create_engine("sqlite:///./app.db")
conn = engine.connect()
print("Database connection successful")
conn.close()
END

echo "----- Backend database repaired -----"
