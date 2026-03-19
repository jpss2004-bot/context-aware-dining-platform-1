#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch8c_onboarding_text_contrast_fix_backup_$STAMP"
FILE="$FRONTEND_DIR/src/styles.css"

if [ ! -f "$FILE" ]; then
  echo "Missing required file: $FILE"
  echo "Run this from the project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src"
cp "$FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch8c_onboarding_text_contrast_fix..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

styles_path = Path("frontend/src/styles.css")
styles = styles_path.read_text()

extra = """
/* Patch 8c: onboarding text contrast fix */
.single-onboarding-card,
.single-onboarding-card * {
  color: inherit;
}

.single-onboarding-card {
  color: #2f2926;
}

.single-onboarding-card .single-onboarding-eyebrow,
.single-onboarding-card .single-onboarding-step-tag {
  color: #7a866f !important;
}

.single-onboarding-card .single-onboarding-title,
.single-onboarding-card .single-onboarding-stage-copy h2 {
  color: #2f2926 !important;
}

.single-onboarding-card .single-onboarding-subtitle,
.single-onboarding-card .single-onboarding-stage-copy p,
.single-onboarding-card .single-onboarding-progress-meta,
.single-onboarding-card .single-onboarding-draft-note,
.single-onboarding-card .muted {
  color: #5f5a56 !important;
}

.single-onboarding-card .single-onboarding-choice strong {
  color: #312b28 !important;
}

.single-onboarding-card .single-onboarding-choice p {
  color: #69635f !important;
}

.single-onboarding-card .form-row label {
  color: #4f4a46 !important;
}

.single-onboarding-card .form-row input,
.single-onboarding-card .form-row textarea,
.single-onboarding-card .form-row select {
  color: #2f2926 !important;
}

.single-onboarding-card .single-onboarding-inline-error {
  color: #a63b3b !important;
}

.single-onboarding-card .success {
  color: #1f5130 !important;
}

.single-onboarding-card .error {
  color: #8f2f2f !important;
}
"""

marker = "/* Patch 8c: onboarding text contrast fix */"
if marker not in styles:
    styles += "\n\n" + extra + "\n"

styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 8c applied successfully."
echo "Files changed:"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) refresh /profile/preferences"
echo "2) confirm all text inside the onboarding card is now readable"
echo "3) confirm titles are dark and helper text is medium contrast"
echo "4) confirm option descriptions no longer blend into the background"
