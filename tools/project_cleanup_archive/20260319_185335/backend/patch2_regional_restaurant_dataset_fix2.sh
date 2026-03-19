#!/bin/bash
set -euo pipefail

PATCH_NAME="patch2_regional_restaurant_dataset_fix2"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Creating backup at: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

TARGET_SCRIPT="patch2_regional_restaurant_dataset_fix.sh"

if [ -f "$TARGET_SCRIPT" ]; then
  cp "$TARGET_SCRIPT" "${BACKUP_DIR}/$TARGET_SCRIPT"
fi

PYTHON_BIN="python3"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi

echo "Using Python: ${PYTHON_BIN}"
"${PYTHON_BIN}" -m compileall app

echo "Running full restaurant reset + reseed with package-aware module execution..."
PYTHONPATH=. "${PYTHON_BIN}" -m app.db.reset_and_seed_restaurants

echo "Patch 2.2 reseed fix applied successfully."
echo "Backup saved at: ${BACKUP_DIR}"
