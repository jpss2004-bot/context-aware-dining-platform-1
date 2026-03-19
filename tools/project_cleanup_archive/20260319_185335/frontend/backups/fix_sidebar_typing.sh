#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"
SIDEBAR="$ROOT/src/components/navigation/Sidebar.tsx"

if [[ ! -f "$SIDEBAR" ]]; then
  echo "Could not find: $SIDEBAR"
  echo "Run this from the frontend directory."
  exit 1
fi

BACKUP="$SIDEBAR.bak.$(date +%Y%m%d_%H%M%S)"
cp "$SIDEBAR" "$BACKUP"
echo "Backup created: $BACKUP"

python3 <<'PY'
from pathlib import Path
import re
import sys
import os

sidebar = Path(os.environ.get("SIDEBAR_PATH", "src/components/navigation/Sidebar.tsx"))
text = sidebar.read_text(encoding="utf-8")

original = text

# Ensure NavLinkRenderProps type import exists if NavLink is imported from react-router-dom
if 'from "react-router-dom"' in text or "from 'react-router-dom'" in text:
    # Double-quoted import
    text = re.sub(
        r'import\s*\{\s*([^}]*)\s*\}\s*from\s*"react-router-dom";',
        lambda m: (
            f'import {{ {m.group(1)}, type NavLinkRenderProps }} from "react-router-dom";'
            if "NavLinkRenderProps" not in m.group(1)
            else m.group(0)
        ),
        text,
        count=1,
    )
    # Single-quoted import
    text = re.sub(
        r"import\s*\{\s*([^}]*)\s*\}\s*from\s*'react-router-dom';",
        lambda m: (
            f"import {{ {m.group(1)}, type NavLinkRenderProps }} from 'react-router-dom';"
            if "NavLinkRenderProps" not in m.group(1)
            else m.group(0)
        ),
        text,
        count=1,
    )

# Fix className callback destructuring
text = re.sub(
    r'className=\{\(\{\s*isActive\s*\}\)\s*=>',
    'className={({ isActive }: NavLinkRenderProps) =>',
    text
)

# Fix children/render callback destructuring if present
text = re.sub(
    r'\(\{\s*isActive\s*\}\s*\)\s*=>',
    '({ isActive }: NavLinkRenderProps) =>',
    text
)

if text == original:
    print("No changes were made. Sidebar.tsx may already be fixed or use a different pattern.")
else:
    sidebar.write_text(text, encoding="utf-8")
    print("Sidebar.tsx patched successfully.")
PY

