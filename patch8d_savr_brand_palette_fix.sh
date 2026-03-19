#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch8d_savr_brand_palette_fix_backup_$STAMP"
FILE="$FRONTEND_DIR/src/styles.css"

if [ ! -f "$FILE" ]; then
  echo "Missing required file: $FILE"
  echo "Run this from the project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src"
cp "$FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch8d_savr_brand_palette_fix..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

styles_path = Path("frontend/src/styles.css")
styles = styles_path.read_text()

marker = "/* Patch 8d: SAVR onboarding brand palette alignment */"

block = """
/* Patch 8d: SAVR onboarding brand palette alignment */
.single-onboarding-card {
  background: linear-gradient(180deg, #f6f1eb 0%, #f4eee7 100%) !important;
  border: 1px solid rgba(120, 30, 58, 0.12) !important;
  box-shadow:
    0 14px 34px rgba(40, 40, 40, 0.08),
    0 4px 14px rgba(120, 30, 58, 0.05) !important;
}

.single-onboarding-card,
.single-onboarding-card * {
  color: inherit;
}

.single-onboarding-card {
  color: #282828 !important;
}

.single-onboarding-card .single-onboarding-eyebrow,
.single-onboarding-card .single-onboarding-step-tag {
  color: #781e3a !important;
}

.single-onboarding-card .single-onboarding-title,
.single-onboarding-card .single-onboarding-stage-copy h2,
.single-onboarding-card .single-onboarding-choice strong,
.single-onboarding-card .form-row label {
  color: #282828 !important;
}

.single-onboarding-card .single-onboarding-subtitle,
.single-onboarding-card .single-onboarding-stage-copy p,
.single-onboarding-card .single-onboarding-progress-meta,
.single-onboarding-card .single-onboarding-draft-note,
.single-onboarding-card .single-onboarding-choice p,
.single-onboarding-card .muted {
  color: #5c514b !important;
}

.single-onboarding-card .single-onboarding-progress-track {
  background: rgba(120, 30, 58, 0.10) !important;
}

.single-onboarding-card .single-onboarding-progress-fill {
  background: linear-gradient(90deg, #781e3a 0%, #9b3d4a 100%) !important;
}

.single-onboarding-card .single-onboarding-banner {
  background: linear-gradient(180deg, rgba(201, 164, 39, 0.12), rgba(201, 164, 39, 0.08)) !important;
  border: 1px solid rgba(201, 164, 39, 0.20) !important;
}

.single-onboarding-card .single-onboarding-choice {
  background: linear-gradient(180deg, #fbf7f2 0%, #f7f1ea 100%) !important;
  border: 1px solid rgba(120, 30, 58, 0.10) !important;
  box-shadow: none !important;
}

.single-onboarding-card .single-onboarding-choice:hover {
  border-color: rgba(120, 30, 58, 0.28) !important;
  box-shadow: 0 8px 18px rgba(120, 30, 58, 0.06) !important;
}

.single-onboarding-card .single-onboarding-choice--active {
  background: linear-gradient(180deg, rgba(111, 133, 89, 0.16), rgba(111, 133, 89, 0.10)) !important;
  border-color: rgba(111, 133, 89, 0.46) !important;
  box-shadow: 0 8px 18px rgba(111, 133, 89, 0.08) !important;
}

.single-onboarding-card .form-row input,
.single-onboarding-card .form-row textarea,
.single-onboarding-card .form-row select {
  background: #fcf8f3 !important;
  border: 1px solid rgba(120, 30, 58, 0.12) !important;
  color: #282828 !important;
}

.single-onboarding-card .form-row input::placeholder,
.single-onboarding-card .form-row textarea::placeholder {
  color: #8a7d76 !important;
}

.single-onboarding-card .single-onboarding-inline-error,
.single-onboarding-card .error {
  color: #9d2f2f !important;
}

.single-onboarding-card .success {
  color: #5d7348 !important;
}

.single-onboarding-card .single-onboarding-summary-list .item {
  background: linear-gradient(180deg, #faf5ef 0%, #f6efe8 100%) !important;
  border: 1px solid rgba(120, 30, 58, 0.08) !important;
}
"""

if marker not in styles:
    styles += "\n\n" + block + "\n"

styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 8d applied successfully."
echo "Files changed:"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) refresh /profile/preferences"
echo "2) confirm the onboarding uses SAVR cream, wine, olive, charcoal, and gold accents"
echo "3) confirm text is dark charcoal and fully readable"
echo "4) confirm active choices feel on-brand, not gray or muddy"
