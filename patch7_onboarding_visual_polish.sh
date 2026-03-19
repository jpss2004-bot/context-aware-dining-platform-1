#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
FRONTEND_DIR="$ROOT/frontend"
STAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_DIR="$ROOT/.patch7_onboarding_visual_polish_backup_$STAMP"

FILE="$FRONTEND_DIR/src/styles.css"

if [ ! -f "$FILE" ]; then
  echo "Missing required file: $FILE"
  echo "Run this from the project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src"
cp "$FILE" "$BACKUP_DIR/frontend/src/styles.css"

echo "Starting patch7_onboarding_visual_polish..."
echo "Resolved frontend directory: $FRONTEND_DIR"
echo "Creating backup at: $BACKUP_DIR"

python3 <<'PY'
from pathlib import Path

styles_path = Path("frontend/src/styles.css")
styles = styles_path.read_text()

old_block = """
.single-onboarding-card {
  width: min(860px, 100%);
  display: grid;
  gap: 1.15rem;
  padding: 1.4rem;
  border-radius: 1.5rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(15, 23, 42, 0.38);
  box-shadow: 0 18px 50px rgba(2, 6, 23, 0.2);
}

.single-onboarding-banner {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  padding: 1rem 1.1rem;
  border-radius: 1rem;
  border: 1px solid rgba(86, 115, 66, 0.2);
  background: rgba(125, 156, 102, 0.08);
}

.single-onboarding-progress-track {
  width: 100%;
  height: 12px;
  border-radius: 999px;
  background: rgba(148, 163, 184, 0.16);
  overflow: hidden;
}

.single-onboarding-choice {
  text-align: left;
  display: grid;
  gap: 0.35rem;
  padding: 1rem 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(148, 163, 184, 0.16);
  background: rgba(15, 23, 42, 0.28);
  transition: transform 0.14s ease, border-color 0.14s ease, background 0.14s ease;
}
"""

new_block = """
.single-onboarding-card {
  width: min(860px, 100%);
  display: grid;
  gap: 1.15rem;
  padding: 1.4rem;
  border-radius: 1.5rem;
  border: 1px solid rgba(125, 156, 102, 0.18);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.94), rgba(248, 250, 246, 0.96));
  box-shadow:
    0 18px 50px rgba(62, 84, 52, 0.08),
    0 4px 14px rgba(62, 84, 52, 0.05);
  backdrop-filter: blur(8px);
}

.single-onboarding-banner {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  padding: 1rem 1.1rem;
  border-radius: 1rem;
  border: 1px solid rgba(125, 156, 102, 0.22);
  background: linear-gradient(180deg, rgba(241, 247, 236, 0.95), rgba(235, 243, 229, 0.92));
}

.single-onboarding-progress-track {
  width: 100%;
  height: 12px;
  border-radius: 999px;
  background: rgba(125, 156, 102, 0.14);
  overflow: hidden;
}

.single-onboarding-choice {
  text-align: left;
  display: grid;
  gap: 0.35rem;
  padding: 1rem 1rem;
  border-radius: 1rem;
  border: 1px solid rgba(125, 156, 102, 0.14);
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.98), rgba(246, 249, 243, 0.98));
  transition: transform 0.14s ease, border-color 0.14s ease, background 0.14s ease, box-shadow 0.14s ease;
}
"""

if old_block not in styles:
    raise SystemExit("Expected onboarding visual block not found.")

styles = styles.replace(old_block, new_block, 1)

styles = styles.replace(
""".single-onboarding-subtitle {
  margin: 0;
  color: var(--color-text-muted, #7f8b84);
  max-width: 64ch;
}""",
""".single-onboarding-subtitle {
  margin: 0;
  color: #5d675e;
  max-width: 64ch;
}""",
1
)

styles = styles.replace(
""".single-onboarding-progress-meta {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  font-size: 0.95rem;
}""",
""".single-onboarding-progress-meta {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  font-size: 0.95rem;
  color: #4e5c4f;
}""",
1
)

styles = styles.replace(
""".single-onboarding-choice:hover {
  transform: translateY(-1px);
  border-color: rgba(125, 156, 102, 0.4);
}""",
""".single-onboarding-choice:hover {
  transform: translateY(-1px);
  border-color: rgba(125, 156, 102, 0.42);
  box-shadow: 0 8px 20px rgba(82, 110, 67, 0.08);
}""",
1
)

styles = styles.replace(
""".single-onboarding-choice p {
  margin: 0;
  color: var(--color-text-muted, #7f8b84);
  font-size: 0.93rem;
}""",
""".single-onboarding-choice p {
  margin: 0;
  color: #667167;
  font-size: 0.93rem;
}""",
1
)

styles = styles.replace(
""".single-onboarding-choice--active {
  border-color: rgba(125, 156, 102, 0.8);
  background: rgba(125, 156, 102, 0.14);
}""",
""".single-onboarding-choice--active {
  border-color: rgba(103, 136, 84, 0.78);
  background: linear-gradient(180deg, rgba(235, 244, 228, 0.98), rgba(227, 239, 218, 0.98));
  box-shadow: 0 10px 24px rgba(82, 110, 67, 0.1);
}""",
1
)

styles = styles.replace(
""".single-onboarding-inline-error {
  margin: 0;
  color: #b43a3a;
  font-weight: 700;
  font-size: 0.94rem;
}""",
""".single-onboarding-inline-error {
  margin: 0;
  color: #a13030;
  font-weight: 700;
  font-size: 0.94rem;
}""",
1
)

styles = styles.replace(
""".single-onboarding-summary-list {
  display: grid;
  gap: 0.8rem;
}""",
""".single-onboarding-summary-list {
  display: grid;
  gap: 0.8rem;
}

.single-onboarding-summary-list .item {
  border: 1px solid rgba(125, 156, 102, 0.12);
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.96), rgba(247, 249, 245, 0.96));
}""",
1
)

if ".single-onboarding-stage-copy h2" in styles:
    styles = styles.replace(
""".single-onboarding-stage-copy h2 {
  margin: 0;
  font-size: clamp(1.35rem, 2.2vw, 1.8rem);
}""",
""".single-onboarding-stage-copy h2 {
  margin: 0;
  font-size: clamp(1.35rem, 2.2vw, 1.8rem);
  color: #233125;
}""",
1
)

if ".single-onboarding-stage-copy p" in styles:
    styles = styles.replace(
""".single-onboarding-stage-copy p {
  margin: 0;
}""",
""".single-onboarding-stage-copy p {
  margin: 0;
  color: #4f5c50;
}""",
1
)

styles_path.write_text(styles)
PY

echo
echo "Running frontend TypeScript check..."
(
  cd "$FRONTEND_DIR"
  npx tsc --noEmit
)

echo
echo "Patch 7 applied successfully."
echo "Files changed:"
echo " - frontend/src/styles.css"
echo
echo "Next steps:"
echo "1) run frontend"
echo "2) open /profile/preferences"
echo "3) confirm the gray matte box is gone"
echo "4) confirm the onboarding card now matches the green/clean SAVR palette"
echo "5) confirm active choices still stand out clearly"
