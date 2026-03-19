#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d_%H%M%S")"
ARCHIVE_ROOT="$ROOT/tools/project_cleanup_archive/$STAMP"
ARCHIVE_BACKEND="$ARCHIVE_ROOT/backend"
ARCHIVE_FRONTEND="$ARCHIVE_ROOT/frontend"
ARCHIVE_MISC="$ARCHIVE_ROOT/misc"
LOG_DIR="$ARCHIVE_ROOT/logs"
MANIFEST="$LOG_DIR/manifest.txt"

DRY_RUN="${DRY_RUN:-0}"

mkdir -p "$ARCHIVE_BACKEND" "$ARCHIVE_FRONTEND" "$ARCHIVE_MISC" "$LOG_DIR"
touch "$MANIFEST"

log_move() {
  printf 'MOVED | %s -> %s\n' "$1" "$2" | tee -a "$MANIFEST"
}

log_delete() {
  printf 'DELETED | %s\n' "$1" | tee -a "$MANIFEST"
}

move_to_archive() {
  local src="$1"
  local dest_dir="$2"

  [ -e "$src" ] || return 0

  mkdir -p "$dest_dir"
  local base
  base="$(basename "$src")"
  local dest="$dest_dir/$base"

  if [ -e "$dest" ]; then
    dest="${dest}_$STAMP"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log_move "$src" "$dest"
  else
    mv "$src" "$dest"
    log_move "$src" "$dest"
  fi
}

delete_safe() {
  local path="$1"

  [ -e "$path" ] || return 0

  if [ "$DRY_RUN" = "1" ]; then
    log_delete "$path"
  else
    rm -rf "$path"
    log_delete "$path"
  fi
}

echo "Running targeted cleanup from: $ROOT"
echo "Archive folder: $ARCHIVE_ROOT"
echo "Mode: $([ "$DRY_RUN" = "1" ] && echo "DRY RUN" || echo "LIVE")"
echo

# 1) Delete .DS_Store files
find "$ROOT" -type f -name ".DS_Store" -print0 |
while IFS= read -r -d '' file; do
  delete_safe "$file"
done

# 2) Archive backend patch backup folders
find "$ROOT/backend" -maxdepth 1 -type d -name ".patch*_backup_*" -print0 |
while IFS= read -r -d '' dir; do
  move_to_archive "$dir" "$ARCHIVE_BACKEND"
done

# 3) Archive frontend patch backup folders
find "$ROOT/frontend" -maxdepth 1 -type d -name ".patch*_backup_*" -print0 |
while IFS= read -r -d '' dir; do
  move_to_archive "$dir" "$ARCHIVE_FRONTEND"
done

# 4) Archive backend patch scripts
find "$ROOT/backend" -maxdepth 1 -type f -name "patch*.sh" -print0 |
while IFS= read -r -d '' file; do
  move_to_archive "$file" "$ARCHIVE_BACKEND"
done

# 5) Archive frontend/backups folder
if [ -d "$ROOT/frontend/backups" ]; then
  move_to_archive "$ROOT/frontend/backups" "$ARCHIVE_FRONTEND"
fi

# 6) Archive stray .bak files
find "$ROOT/frontend/src" -type f \( -name "*.bak" -o -name "*.bak.*" \) -print0 |
while IFS= read -r -d '' file; do
  move_to_archive "$file" "$ARCHIVE_MISC"
done

# 7) Delete tsbuildinfo artifact
if [ -f "$ROOT/frontend/tsconfig.app.tsbuildinfo" ]; then
  delete_safe "$ROOT/frontend/tsconfig.app.tsbuildinfo"
fi

echo
echo "Done."
echo "Manifest: $MANIFEST"
