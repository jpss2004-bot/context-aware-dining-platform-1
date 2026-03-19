#!/usr/bin/env bash
set -Eeuo pipefail

# Conservative project cleanup script
# - Run from project root
# - Does NOT modify source files
# - Keeps runtime/import paths intact
# - Archives clutter instead of deleting most things
# - Removes only safe generated junk

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d_%H%M%S")"
ARCHIVE_BASE="$ROOT/tools/project_cleanup_archive/$STAMP"
ARCHIVE_MISC="$ARCHIVE_BASE/misc"
ARCHIVE_SCRIPTS="$ARCHIVE_BASE/old_scripts"
ARCHIVE_BACKUPS="$ARCHIVE_BASE/backups"
ARCHIVE_BUNDLES="$ARCHIVE_BASE/bundles"
LOG_DIR="$ARCHIVE_BASE/logs"
MANIFEST="$LOG_DIR/manifest.txt"
SUMMARY="$LOG_DIR/summary.txt"

DRY_RUN="${DRY_RUN:-0}"

mkdir -p "$ARCHIVE_MISC" "$ARCHIVE_SCRIPTS" "$ARCHIVE_BACKUPS" "$ARCHIVE_BUNDLES" "$LOG_DIR"

touch "$MANIFEST" "$SUMMARY"

log() {
  echo "$1"
  echo "$1" >> "$SUMMARY"
}

record_move() {
  printf 'MOVED | %s -> %s\n' "$1" "$2" >> "$MANIFEST"
}

record_delete() {
  printf 'DELETED | %s\n' "$1" >> "$MANIFEST"
}

record_skip() {
  printf 'SKIPPED | %s\n' "$1" >> "$MANIFEST"
}

safe_move() {
  local src="$1"
  local dest_dir="$2"

  if [ ! -e "$src" ]; then
    return 0
  fi

  mkdir -p "$dest_dir"
  local base
  base="$(basename "$src")"
  local dest="$dest_dir/$base"

  if [ -e "$dest" ]; then
    dest="${dest}_$STAMP"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY RUN] move: $src -> $dest"
    record_move "$src" "$dest"
  else
    mv "$src" "$dest"
    echo "Moved: $src -> $dest"
    record_move "$src" "$dest"
  fi
}

safe_delete() {
  local path="$1"

  if [ ! -e "$path" ]; then
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY RUN] delete: $path"
    record_delete "$path"
  else
    rm -rf "$path"
    echo "Deleted: $path"
    record_delete "$path"
  fi
}

is_project_root() {
  [ -d "$ROOT/backend" ] || [ -d "$ROOT/frontend" ] || [ -f "$ROOT/package.json" ]
}

if ! is_project_root; then
  echo "This does not look like the project root."
  echo "Run this from the root folder of the project."
  exit 1
fi

log "Starting conservative cleanup in: $ROOT"
log "Archive folder: $ARCHIVE_BASE"
if [ "$DRY_RUN" = "1" ]; then
  log "Mode: DRY RUN"
else
  log "Mode: LIVE"
fi

# -------------------------------------------------------------------
# 1) Remove safe generated junk everywhere
# -------------------------------------------------------------------
log ""
log "Removing safe generated junk..."

find "$ROOT" \
  \( -path "$ARCHIVE_BASE" -o -path "$ROOT/.git" -o -path "$ROOT/node_modules" -o -path "$ROOT/frontend/node_modules" -o -path "$ROOT/backend/.venv" -o -path "$ROOT/.venv" \) -prune \
  -o -type f \( -name ".DS_Store" -o -name "Thumbs.db" -o -name "*.pyc" -o -name "*.pyo" -o -name "*.tmp" -o -name "*.log" \) -print0 |
while IFS= read -r -d '' file; do
  safe_delete "$file"
done

find "$ROOT" \
  \( -path "$ARCHIVE_BASE" -o -path "$ROOT/.git" -o -path "$ROOT/node_modules" -o -path "$ROOT/frontend/node_modules" -o -path "$ROOT/backend/.venv" -o -path "$ROOT/.venv" \) -prune \
  -o -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" -o -name ".ruff_cache" -o -name ".coverage" -o -name "htmlcov" -o -name ".parcel-cache" \) -print0 |
while IFS= read -r -d '' dir; do
  safe_delete "$dir"
done

# -------------------------------------------------------------------
# 2) Archive obvious root clutter: duplicate exported bundles
# -------------------------------------------------------------------
log ""
log "Archiving duplicate/export bundle files from root..."

for file in \
  "$ROOT/backend.zip" \
  "$ROOT/frontend.zip" \
  "$ROOT/context-aware-dining-platform.zip"
do
  if [ -f "$file" ]; then
    safe_move "$file" "$ARCHIVE_BUNDLES"
  fi
done

# -------------------------------------------------------------------
# 3) Archive patch-era backup folders
# -------------------------------------------------------------------
log ""
log "Archiving old backup folders..."

find "$ROOT" -maxdepth 1 -type d \
  \( -name ".patch*_backup_*" -o -name "*backup*" -o -name ".backup_*" \) -print0 |
while IFS= read -r -d '' dir; do
  case "$dir" in
    "$ARCHIVE_BASE"|"$ROOT/.git"|"$ROOT/backend"|"$ROOT/frontend"|"$ROOT/tests"|"$ROOT/scripts"|"$ROOT/tools")
      record_skip "$dir"
      ;;
    *)
      safe_move "$dir" "$ARCHIVE_BACKUPS"
      ;;
  esac
done

# -------------------------------------------------------------------
# 4) Archive loose old shell scripts at project root
# Keep only clearly current utility folders intact
# -------------------------------------------------------------------
log ""
log "Archiving loose root-level patch/fix scripts..."

find "$ROOT" -maxdepth 1 -type f -name "*.sh" -print0 |
while IFS= read -r -d '' file; do
  base="$(basename "$file")"

  case "$base" in
    project_cleanup_safe.sh)
      record_skip "$file"
      ;;
    start.sh|run.sh|dev.sh|test.sh|build.sh|deploy.sh)
      record_skip "$file"
      ;;
    *)
      safe_move "$file" "$ARCHIVE_SCRIPTS"
      ;;
  esac
done

# -------------------------------------------------------------------
# 5) Archive common junk directories that are not runtime-critical
# Very conservative: only obvious clutter folders at root
# -------------------------------------------------------------------
log ""
log "Archiving obvious clutter folders at root..."

for dir in \
  "$ROOT/tmp" \
  "$ROOT/temp" \
  "$ROOT/.tmp" \
  "$ROOT/.temp" \
  "$ROOT/debug" \
  "$ROOT/debug_outputs" \
  "$ROOT/old" \
  "$ROOT/old_scripts" \
  "$ROOT/archive" \
  "$ROOT/archives"
do
  if [ -d "$dir" ]; then
    safe_move "$dir" "$ARCHIVE_MISC"
  fi
done

# -------------------------------------------------------------------
# 6) Frontend build artifacts (safe)
# -------------------------------------------------------------------
log ""
log "Cleaning safe frontend build artifacts..."

for dir in \
  "$ROOT/frontend/dist" \
  "$ROOT/frontend/.vite" \
  "$ROOT/frontend/coverage" \
  "$ROOT/frontend/test-results" \
  "$ROOT/frontend/playwright-report"
do
  if [ -e "$dir" ]; then
    safe_delete "$dir"
  fi
done

# -------------------------------------------------------------------
# 7) Backend test/build artifacts (safe)
# -------------------------------------------------------------------
log ""
log "Cleaning safe backend/test artifacts..."

for dir in \
  "$ROOT/backend/.pytest_cache" \
  "$ROOT/backend/htmlcov" \
  "$ROOT/backend/.coverage" \
  "$ROOT/test-results" \
  "$ROOT/playwright-report" \
  "$ROOT/coverage"
do
  if [ -e "$dir" ]; then
    safe_delete "$dir"
  fi
done

# -------------------------------------------------------------------
# 8) Empty file scan only (report, do not delete)
# -------------------------------------------------------------------
log ""
log "Scanning for empty files (report only)..."

find "$ROOT" \
  \( -path "$ARCHIVE_BASE" -o -path "$ROOT/.git" -o -path "$ROOT/node_modules" -o -path "$ROOT/frontend/node_modules" -o -path "$ROOT/backend/.venv" -o -path "$ROOT/.venv" \) -prune \
  -o -type f -empty -print |
while IFS= read -r file; do
  printf 'EMPTY FILE | %s\n' "$file" >> "$MANIFEST"
done

# -------------------------------------------------------------------
# 9) Empty directory cleanup for obvious junk only
# -------------------------------------------------------------------
log ""
log "Cleaning empty junk directories..."

find "$ROOT" \
  \( -path "$ARCHIVE_BASE" -o -path "$ROOT/.git" -o -path "$ROOT/node_modules" -o -path "$ROOT/frontend/node_modules" -o -path "$ROOT/backend/.venv" -o -path "$ROOT/.venv" \) -prune \
  -o -type d -empty -print0 |
while IFS= read -r -d '' dir; do
  case "$dir" in
    "$ROOT"|"$ROOT/backend"|"$ROOT/frontend"|"$ROOT/tests"|"$ROOT/scripts"|"$ROOT/tools"|"$ARCHIVE_BASE"|"$ARCHIVE_MISC"|"$ARCHIVE_SCRIPTS"|"$ARCHIVE_BACKUPS"|"$ARCHIVE_BUNDLES"|"$LOG_DIR")
      record_skip "$dir"
      ;;
    *)
      safe_delete "$dir"
      ;;
  esac
done

# -------------------------------------------------------------------
# 10) Write guide file
# -------------------------------------------------------------------
README_FILE="$ARCHIVE_BASE/README_cleanup.txt"
cat > "$README_FILE" <<EOF
Project cleanup archive
Timestamp: $STAMP

This cleanup was conservative:
- source files were not edited
- app/runtime paths were preserved
- most clutter was archived instead of destroyed
- only safe generated junk was deleted

See:
- logs/manifest.txt
- logs/summary.txt
EOF

log ""
log "Cleanup complete."
log "Archive: $ARCHIVE_BASE"
log "Manifest: $MANIFEST"
log "Summary: $SUMMARY"

echo
echo "Done."
