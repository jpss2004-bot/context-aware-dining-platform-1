#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

if [[ -d "$ROOT_DIR/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend"
elif [[ -d "$ROOT_DIR/frontend/frontend/src" ]]; then
  FRONTEND_DIR="$ROOT_DIR/frontend/frontend"
else
  echo "Error: could not find frontend/src from ROOT_DIR=$ROOT_DIR" >&2
  echo "Run this script from the project root, or pass the project root as the first argument." >&2
  exit 1
fi

python3 - <<PY
from pathlib import Path

styles_path = Path(r"$FRONTEND_DIR/src/styles.css")
text = styles_path.read_text()

marker = "/* PHASE 9 VISUAL CONSISTENCY AND CONTRAST FIX */"
if marker in text:
    raise SystemExit("Phase 9 marker already exists in styles.css. Aborting to avoid duplicate patch.")

text += """

/* PHASE 9 VISUAL CONSISTENCY AND CONTRAST FIX */
:root {
  --phase9-surface: rgba(255, 250, 244, 0.97);
  --phase9-surface-soft: rgba(250, 244, 238, 0.96);
  --phase9-surface-muted: rgba(246, 239, 232, 0.94);
  --phase9-border: rgba(120, 30, 90, 0.12);
  --phase9-border-strong: rgba(120, 30, 90, 0.2);
  --phase9-text-main: #2f2926;
  --phase9-text-soft: #685f59;
  --phase9-text-strong: #241f1c;
  --phase9-input-bg: rgba(255, 252, 248, 0.96);
  --phase9-chip-bg: rgba(120, 30, 90, 0.06);
  --phase9-chip-accent-bg: rgba(201, 162, 71, 0.16);
  --phase9-chip-success-bg: rgba(111, 117, 89, 0.14);
}

body {
  color: var(--phase9-text-main);
}

.app-sidebar {
  background: linear-gradient(180deg, rgba(249, 243, 237, 0.98), rgba(245, 238, 230, 0.96));
}

.app-navbar,
.app-sidebar,
.card,
.ui-card,
.auth-card,
.hero-card,
.sidebar-profile-card,
.navbar-meta-card,
.sidebar-footer-card,
.item,
.auth-switch-card,
.auth-intro-block,
.build-summary {
  backdrop-filter: blur(12px);
}

.sidebar-profile-card,
.navbar-meta-card,
.sidebar-footer-card,
.ui-card,
.card,
.auth-card,
.hero-card,
.auth-switch-card,
.auth-intro-block,
.build-summary {
  background: linear-gradient(180deg, var(--phase9-surface), var(--phase9-surface-soft));
  border: 1px solid var(--phase9-border);
  box-shadow: var(--shadow-soft);
  color: var(--phase9-text-main);
}

.item {
  background: linear-gradient(180deg, rgba(255, 252, 248, 0.98), rgba(247, 241, 234, 0.96));
  border: 1px solid rgba(120, 30, 90, 0.08);
  color: var(--phase9-text-main);
}

.hero-card {
  background:
    linear-gradient(135deg, rgba(120, 30, 90, 0.045), rgba(201, 162, 71, 0.07)),
    linear-gradient(180deg, var(--phase9-surface), var(--phase9-surface-soft));
}

.ui-card,
.card,
.auth-card,
.hero-card {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.ui-card__header {
  align-items: flex-start;
  margin-bottom: 1rem;
}

.ui-card__actions {
  align-self: flex-start;
}

.ui-card__body {
  display: grid;
  gap: 1rem;
  flex: 1 1 auto;
  min-width: 0;
}

.grid > .ui-card,
.grid > .card,
.grid > section.card,
.grid > .auth-card,
.grid > .hero-card {
  height: 100%;
}

.ui-card__title,
.page-title,
.navbar-title,
.sidebar-brand,
.auth-card h3 {
  color: var(--phase9-text-strong);
}

.ui-card__subtitle,
.navbar-subtitle,
.muted,
.auth-switch-card .muted,
.auth-intro-block .muted,
.sidebar-profile-card .muted,
.item .muted,
.card .muted,
.ui-card .muted {
  color: var(--phase9-text-soft) !important;
}

.sidebar-link {
  color: var(--phase9-text-soft);
}

.sidebar-link:hover,
.sidebar-link--active {
  color: var(--phase9-text-main);
}

.sidebar-link--active {
  background: linear-gradient(135deg, rgba(120, 30, 90, 0.08), rgba(201, 162, 71, 0.12));
  border-color: var(--phase9-border-strong);
}

.navbar-date-chip {
  background: rgba(255, 250, 244, 0.96);
  color: var(--color-wine);
  border: 1px solid var(--phase9-border);
}

.kpi {
  color: var(--color-wine);
}

input,
select,
textarea,
.ui-input,
.password-input-shell {
  background: var(--phase9-input-bg) !important;
  color: var(--phase9-text-main) !important;
  border: 1px solid var(--phase9-border) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.7);
}

input::placeholder,
textarea::placeholder {
  color: #8a7f78 !important;
}

input:focus,
select:focus,
textarea:focus,
.ui-input:focus,
.password-input-shell:focus-within {
  border-color: rgba(120, 30, 90, 0.28) !important;
  box-shadow: 0 0 0 4px rgba(120, 30, 90, 0.08) !important;
}

.password-input-shell__input {
  background: transparent !important;
  color: var(--phase9-text-main) !important;
}

.password-toggle {
  background: rgba(120, 30, 90, 0.08) !important;
  color: var(--color-wine) !important;
  border: 1px solid rgba(120, 30, 90, 0.12);
}

.password-toggle:hover {
  background: rgba(120, 30, 90, 0.14) !important;
}

.ui-badge,
.badge,
.ui-badge--default,
.ui-badge--accent,
.ui-badge--success,
.ui-badge--warning {
  font-weight: 700;
}

.ui-badge--default {
  background: var(--phase9-chip-bg);
  color: var(--color-wine);
  border-color: rgba(120, 30, 90, 0.12);
}

.ui-badge--accent {
  background: var(--phase9-chip-accent-bg);
  color: #6e5618;
  border-color: rgba(201, 162, 71, 0.28);
}

.ui-badge--success {
  background: var(--phase9-chip-success-bg);
  color: #485240;
  border-color: rgba(111, 117, 89, 0.25);
}

.ui-badge--warning {
  background: rgba(201, 139, 134, 0.16);
  color: #7d544e;
  border-color: rgba(201, 139, 134, 0.28);
}

.dashboard-chip,
.experience-rating-pill {
  background: rgba(120, 30, 90, 0.05) !important;
  color: var(--phase9-text-main) !important;
  border: 1px solid rgba(120, 30, 90, 0.1) !important;
}

.segmented-option,
.rating-selector,
.multi-select-chip {
  background: rgba(255, 252, 248, 0.96) !important;
  color: var(--phase9-text-main) !important;
  border: 1px solid rgba(120, 30, 90, 0.12) !important;
  box-shadow: none;
}

.segmented-option:hover,
.rating-selector:hover,
.multi-select-chip:hover {
  border-color: rgba(120, 30, 90, 0.2) !important;
  background: rgba(255, 248, 241, 0.98) !important;
}

.segmented-option--active,
.rating-selector--active,
.multi-select-chip--active {
  background: linear-gradient(135deg, rgba(120, 30, 90, 0.08), rgba(201, 162, 71, 0.14)) !important;
  color: var(--phase9-text-main) !important;
  border-color: rgba(120, 30, 90, 0.22) !important;
}

.error {
  color: #6c2323 !important;
  background: rgba(201, 139, 134, 0.14) !important;
  border-color: rgba(201, 139, 134, 0.28) !important;
}

.success {
  color: #43513a !important;
  background: rgba(111, 117, 89, 0.14) !important;
  border-color: rgba(111, 117, 89, 0.26) !important;
}

.auth-card {
  background:
    linear-gradient(135deg, rgba(120, 30, 90, 0.04), rgba(201, 162, 71, 0.06)),
    linear-gradient(180deg, var(--phase9-surface), var(--phase9-surface-soft)) !important;
}

.auth-switch-card,
.auth-intro-block {
  background: linear-gradient(180deg, rgba(255, 251, 246, 0.98), rgba(247, 241, 234, 0.96)) !important;
}

.restaurant-card,
.recommendation-card,
.experience-card {
  height: 100%;
}

.restaurant-card .ui-card__body,
.recommendation-card .ui-card__body,
.experience-card .ui-card__body {
  align-content: start;
}

.button-row {
  align-items: stretch;
}

.button-row > .ui-button,
.button-row > a > .ui-button,
.button-row > a.ui-button,
.button-row > button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

@media (min-width: 761px) {
  .grid-2 > .ui-card,
  .grid-2 > .card,
  .grid-3 > .ui-card,
  .grid-3 > .card {
    min-height: 100%;
  }
}

@media (max-width: 1100px) {
  .app-sidebar {
    gap: 0.9rem;
  }

  .sidebar-profile-card,
  .sidebar-footer-card,
  .auth-switch-card,
  .auth-intro-block,
  .item {
    padding: 0.95rem;
  }
}

@media (max-width: 760px) {
  .app-navbar,
  .page-shell,
  .auth-shell {
    padding-left: 1rem;
    padding-right: 1rem;
  }

  .ui-card,
  .card,
  .auth-card,
  .hero-card,
  .item,
  .auth-switch-card,
  .auth-intro-block {
    padding: 1rem;
  }

  .ui-card__header {
    gap: 0.75rem;
  }

  .ui-card__title {
    font-size: 1.55rem;
  }

  .navbar-title {
    line-height: 1;
  }
}
"""
styles_path.write_text(text)
PY

echo "Phase 9 visual consistency and contrast fix applied successfully in: $FRONTEND_DIR"
echo "Updated file:"
echo " - src/styles.css"
