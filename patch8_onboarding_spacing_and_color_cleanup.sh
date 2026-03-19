#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch8_onboarding_spacing_and_color_cleanup_backup_$STAMP"

FILE="$FRONTEND_DIR/src/styles.css"

if [ ! -f "$FILE" ]; then
  echo "Missing required file: $FILE"
  echo "Run this from the project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src"
cp "$FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch8_onboarding_spacing_and_color_cleanup..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path
import re

styles_path = Path("frontend/src/styles.css")
styles = styles_path.read_text()

def replace_block(pattern: str, replacement: str, label: str) -> str:
    global styles
    new_styles, count = re.subn(pattern, replacement, styles, count=1, flags=re.S)
    if count == 0:
        raise SystemExit(f"Could not find CSS block for {label}")
    return new_styles

styles = replace_block(
    r"\.single-onboarding-shell\s*\{.*?\}",
    """.single-onboarding-shell {
  width: 100%;
  display: flex;
  justify-content: center;
  padding: 0.35rem 0 0.75rem;
}""",
    "single-onboarding-shell"
)

styles = replace_block(
    r"\.single-onboarding-card\s*\{.*?\}",
    """.single-onboarding-card {
  width: min(980px, 100%);
  display: grid;
  gap: 0.95rem;
  padding: 1.1rem 1.2rem 1.15rem;
  border-radius: 1.35rem;
  border: 1px solid rgba(139, 162, 120, 0.16);
  background: linear-gradient(180deg, #f7f2ef 0%, #f5f1eb 100%);
  box-shadow:
    0 12px 30px rgba(83, 97, 67, 0.06),
    0 2px 10px rgba(83, 97, 67, 0.04);
  backdrop-filter: none;
}""",
    "single-onboarding-card"
)

styles = replace_block(
    r"\.single-onboarding-header\s*\{.*?\}",
    """.single-onboarding-header {
  display: grid;
  gap: 0.55rem;
}""",
    "single-onboarding-header"
)

styles = replace_block(
    r"\.single-onboarding-title\s*\{.*?\}",
    """.single-onboarding-title {
  margin: 0;
  font-size: clamp(1.7rem, 2.8vw, 2.25rem);
  line-height: 1.06;
  color: #2a211f;
}""",
    "single-onboarding-title"
)

styles = replace_block(
    r"\.single-onboarding-subtitle\s*\{.*?\}",
    """.single-onboarding-subtitle {
  margin: 0;
  color: #6c6460;
  max-width: 64ch;
  font-size: 0.98rem;
}""",
    "single-onboarding-subtitle"
)

styles = replace_block(
    r"\.single-onboarding-progress-meta\s*\{.*?\}",
    """.single-onboarding-progress-meta {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  font-size: 0.92rem;
  color: #5f5b56;
}""",
    "single-onboarding-progress-meta"
)

styles = replace_block(
    r"\.single-onboarding-progress-track\s*\{.*?\}",
    """.single-onboarding-progress-track {
  width: 100%;
  height: 10px;
  border-radius: 999px;
  background: rgba(151, 170, 130, 0.16);
  overflow: hidden;
}""",
    "single-onboarding-progress-track"
)

styles = replace_block(
    r"\.single-onboarding-progress-fill\s*\{.*?\}",
    """.single-onboarding-progress-fill {
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, #8baa78 0%, #6f905b 100%);
}""",
    "single-onboarding-progress-fill"
)

styles = replace_block(
    r"\.single-onboarding-draft-note\s*\{.*?\}",
    """.single-onboarding-draft-note {
  margin: 0;
  font-size: 0.86rem;
  color: #7a746d;
}""",
    "single-onboarding-draft-note"
)

styles = replace_block(
    r"\.single-onboarding-banner\s*\{.*?\}",
    """.single-onboarding-banner {
  display: flex;
  justify-content: space-between;
  gap: 0.85rem;
  align-items: center;
  padding: 0.85rem 0.95rem;
  border-radius: 0.95rem;
  border: 1px solid rgba(151, 170, 130, 0.2);
  background: linear-gradient(180deg, #eef4e8 0%, #e7efdf 100%);
}""",
    "single-onboarding-banner"
)

styles = replace_block(
    r"\.single-onboarding-stage\s*\{.*?\}",
    """.single-onboarding-stage {
  display: grid;
  gap: 0.8rem;
  padding: 0.45rem 0 0.1rem;
}""",
    "single-onboarding-stage"
)

styles = replace_block(
    r"\.single-onboarding-stage-copy\s*\{.*?\}",
    """.single-onboarding-stage-copy {
  display: grid;
  gap: 0.3rem;
}""",
    "single-onboarding-stage-copy"
)

styles = replace_block(
    r"\.single-onboarding-step-tag\s*\{.*?\}",
    """.single-onboarding-step-tag {
  margin: 0;
  font-size: 0.77rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #93a087;
}""",
    "single-onboarding-step-tag"
)

styles = replace_block(
    r"\.single-onboarding-stage-copy h2\s*\{.*?\}",
    """.single-onboarding-stage-copy h2 {
  margin: 0;
  font-size: clamp(1.18rem, 2vw, 1.55rem);
  color: #2f2926;
  line-height: 1.12;
}""",
    "single-onboarding-stage-copy h2"
)

styles = replace_block(
    r"\.single-onboarding-stage-copy p\s*\{.*?\}",
    """.single-onboarding-stage-copy p {
  margin: 0;
  color: #655f5b;
  font-size: 0.98rem;
}""",
    "single-onboarding-stage-copy p"
)

styles = replace_block(
    r"\.single-onboarding-choice-grid\s*\{.*?\}",
    """.single-onboarding-choice-grid {
  display: grid;
  gap: 0.7rem;
  grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
}""",
    "single-onboarding-choice-grid"
)

styles = replace_block(
    r"\.single-onboarding-choice\s*\{.*?\}",
    """.single-onboarding-choice {
  text-align: left;
  display: grid;
  gap: 0.22rem;
  min-height: 74px;
  padding: 0.78rem 0.9rem;
  border-radius: 0.95rem;
  border: 1px solid rgba(151, 170, 130, 0.18);
  background: linear-gradient(180deg, #faf7f4 0%, #f7f3ee 100%);
  transition: transform 0.14s ease, border-color 0.14s ease, background 0.14s ease, box-shadow 0.14s ease;
}""",
    "single-onboarding-choice"
)

styles = replace_block(
    r"\.single-onboarding-choice:hover\s*\{.*?\}",
    """.single-onboarding-choice:hover {
  transform: translateY(-1px);
  border-color: rgba(125, 156, 102, 0.38);
  box-shadow: 0 8px 16px rgba(103, 117, 85, 0.06);
}""",
    "single-onboarding-choice:hover"
)

styles = replace_block(
    r"\.single-onboarding-choice strong\s*\{.*?\}",
    """.single-onboarding-choice strong {
  font-size: 0.98rem;
  color: #342d2a;
}""",
    "single-onboarding-choice strong"
)

styles = replace_block(
    r"\.single-onboarding-choice p\s*\{.*?\}",
    """.single-onboarding-choice p {
  margin: 0;
  color: #756d69;
  font-size: 0.88rem;
  line-height: 1.25;
}""",
    "single-onboarding-choice p"
)

styles = replace_block(
    r"\.single-onboarding-choice--active\s*\{.*?\}",
    """.single-onboarding-choice--active {
  border-color: rgba(118, 148, 95, 0.6);
  background: linear-gradient(180deg, #eef4e8 0%, #e6efdd 100%);
  box-shadow: 0 8px 18px rgba(112, 139, 91, 0.08);
}""",
    "single-onboarding-choice--active"
)

styles = replace_block(
    r"\.single-onboarding-range-grid\s*\{.*?\}",
    """.single-onboarding-range-grid {
  display: grid;
  gap: 0.85rem;
}""",
    "single-onboarding-range-grid"
)

styles = replace_block(
    r"\.single-onboarding-inline-error\s*\{.*?\}",
    """.single-onboarding-inline-error {
  margin: 0;
  color: #a63b3b;
  font-weight: 700;
  font-size: 0.9rem;
}""",
    "single-onboarding-inline-error"
)

styles = replace_block(
    r"\.single-onboarding-summary-list\s*\{.*?\}",
    """.single-onboarding-summary-list {
  display: grid;
  gap: 0.65rem;
}""",
    "single-onboarding-summary-list"
)

# add/replace nested summary item block
summary_item_pattern = r"\.single-onboarding-summary-list \.item\s*\{.*?\}"
summary_item_replacement = """.single-onboarding-summary-list .item {
  border: 1px solid rgba(151, 170, 130, 0.14);
  background: linear-gradient(180deg, #faf7f3 0%, #f6f2ec 100%);
  padding: 0.8rem 0.95rem;
}"""
if re.search(summary_item_pattern, styles, flags=re.S):
    styles = re.sub(summary_item_pattern, summary_item_replacement, styles, count=1, flags=re.S)
else:
    styles += "\n\n" + summary_item_replacement + "\n"

styles = replace_block(
    r"\.single-onboarding-actions\s*\{.*?\}",
    """.single-onboarding-actions {
  display: flex;
  justify-content: space-between;
  gap: 0.8rem;
  align-items: center;
  padding-top: 0.1rem;
}""",
    "single-onboarding-actions"
)

# tighten form controls inside onboarding
extra_rules = """
.single-onboarding-card .form-row label {
  margin-bottom: 0.32rem;
  font-size: 0.9rem;
  color: #544e4b;
}

.single-onboarding-card .form-row input,
.single-onboarding-card .form-row textarea,
.single-onboarding-card .form-row select {
  background: #fbf8f4;
  border: 1px solid rgba(151, 170, 130, 0.18);
  color: #342d2a;
}

.single-onboarding-card .form-row textarea {
  min-height: 132px;
}

.single-onboarding-card .button-row {
  gap: 0.6rem;
}

.single-onboarding-card .ui-button {
  box-shadow: none;
}

.single-onboarding-card .success,
.single-onboarding-card .error {
  margin: 0;
}
"""
if ".single-onboarding-card .form-row label" not in styles:
    styles += "\n\n" + extra_rules + "\n"

# responsive compaction
media_pattern = r"@media \(max-width: 900px\) \{.*?\.single-onboarding-actions \{\s*flex-direction: column;\s*align-items: stretch;\s*\}\s*\}"
media_replacement = """@media (max-width: 900px) {
  .single-onboarding-card {
    padding: 0.95rem;
    gap: 0.85rem;
  }

  .single-onboarding-choice-grid {
    grid-template-columns: 1fr;
  }

  .single-onboarding-banner,
  .single-onboarding-actions {
    flex-direction: column;
    align-items: stretch;
  }
}"""
if re.search(media_pattern, styles, flags=re.S):
    styles = re.sub(media_pattern, media_replacement, styles, count=1, flags=re.S)
else:
    styles += "\n\n" + media_replacement + "\n"

styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 8 applied successfully."
echo "Files changed:"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) refresh /profile/preferences"
echo "2) confirm the matte gray overlay is gone"
echo "3) confirm the card blends with the SAVR cream/green palette"
echo "4) confirm more options fit on screen before scrolling"
echo "5) confirm the page still feels guided and not cramped"

