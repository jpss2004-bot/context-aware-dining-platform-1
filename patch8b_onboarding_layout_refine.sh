#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch8b_onboarding_layout_refine_backup_$STAMP"
FILE="$FRONTEND_DIR/src/styles.css"

if [ ! -f "$FILE" ]; then
  echo "Missing required file: $FILE"
  echo "Run this from the project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src"
cp "$FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch8b_onboarding_layout_refine..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path
import re

styles_path = Path("frontend/src/styles.css")
styles = styles_path.read_text()

def replace_prop(block_name: str, replacements: dict[str, str]) -> None:
    global styles
    pattern = rf"(\.{re.escape(block_name)}\s*\{{)(.*?)(\n\}})"
    m = re.search(pattern, styles, flags=re.S)
    if not m:
        raise SystemExit(f"Could not find block .{block_name}")
    body = m.group(2)
    for prop, value in replacements.items():
        prop_pattern = rf"(^\s*{re.escape(prop)}\s*:\s*)([^;]+);"
        if not re.search(prop_pattern, body, flags=re.M):
            body += f"\n  {prop}: {value};"
        else:
            body = re.sub(prop_pattern, rf"\g<1>{value};", body, flags=re.M)
    styles = styles[:m.start(2)] + body + styles[m.end(2):]

replace_prop("single-onboarding-shell", {
    "padding": "0.25rem 0 0.6rem"
})

replace_prop("single-onboarding-card", {
    "width": "min(920px, 100%)",
    "gap": "1rem",
    "padding": "1.15rem 1.15rem 1.05rem"
})

replace_prop("single-onboarding-header", {
    "gap": "0.6rem"
})

replace_prop("single-onboarding-progress-track", {
    "height": "10px"
})

replace_prop("single-onboarding-banner", {
    "padding": "0.9rem 1rem"
})

replace_prop("single-onboarding-stage", {
    "gap": "0.85rem",
    "padding": "0.35rem 0 0.1rem"
})

replace_prop("single-onboarding-stage-copy", {
    "gap": "0.28rem"
})

replace_prop("single-onboarding-choice-grid", {
    "gap": "0.7rem",
    "grid-template-columns": "repeat(auto-fit, minmax(185px, 1fr))"
})

replace_prop("single-onboarding-choice", {
    "gap": "0.22rem",
    "min-height": "72px",
    "padding": "0.82rem 0.9rem"
})

replace_prop("single-onboarding-choice strong", {
    "font-size": "0.98rem"
})

replace_prop("single-onboarding-choice p", {
    "font-size": "0.88rem",
    "line-height": "1.22"
})

replace_prop("single-onboarding-range-grid", {
    "gap": "0.8rem"
})

replace_prop("single-onboarding-summary-list", {
    "gap": "0.65rem"
})

replace_prop("single-onboarding-actions", {
    "gap": "0.75rem",
    "padding-top": "0.1rem"
})

extra = """
.single-onboarding-card .form-row label {
  margin-bottom: 0.3rem;
}

.single-onboarding-card .form-row textarea {
  min-height: 132px;
}

.single-onboarding-card .button-row {
  gap: 0.6rem;
}
"""
if ".single-onboarding-card .form-row label" not in styles:
    styles += "\n" + extra + "\n"

styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 8b applied successfully."
echo "Files changed:"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) refresh /profile/preferences"
echo "2) confirm colors match Patch 7 again"
echo "3) confirm text is readable and no green text blends into the background"
echo "4) confirm spacing is tighter without changing the palette"
