#!/bin/zsh
set -e

echo "rewriting global styles..."

cat > src/styles.css <<'EOF'
:root {
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  line-height: 1.5;
  font-weight: 400;
  color: #e5eefb;
  background:
    radial-gradient(circle at top left, rgba(59, 130, 246, 0.18), transparent 28%),
    radial-gradient(circle at top right, rgba(244, 114, 182, 0.14), transparent 26%),
    linear-gradient(180deg, #07111f 0%, #0b1527 45%, #0f1c31 100%);
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

* {
  box-sizing: border-box;
}

html {
  min-height: 100%;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
  color: #e5eefb;
  background:
    radial-gradient(circle at top left, rgba(59, 130, 246, 0.18), transparent 28%),
    radial-gradient(circle at top right, rgba(244, 114, 182, 0.14), transparent 26%),
    linear-gradient(180deg, #07111f 0%, #0b1527 45%, #0f1c31 100%);
}

a {
  color: inherit;
  text-decoration: none;
}

button,
input,
textarea,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

#root {
  min-height: 100vh;
}

.app-frame {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 300px minmax(0, 1fr);
}

.app-main-column {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.app-sidebar {
  position: sticky;
  top: 0;
  height: 100vh;
  padding: 1.25rem;
  border-right: 1px solid rgba(148, 163, 184, 0.12);
  background: rgba(7, 15, 29, 0.88);
  backdrop-filter: blur(22px);
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
}

.sidebar-brand-block {
  display: flex;
  align-items: center;
  gap: 0.9rem;
}

.sidebar-brand-mark {
  width: 3rem;
  height: 3rem;
  border-radius: 1rem;
  display: grid;
  place-items: center;
  font-weight: 800;
  color: #eff6ff;
  background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%);
  box-shadow: 0 20px 40px rgba(37, 99, 235, 0.28);
}

.sidebar-eyebrow,
.navbar-eyebrow,
.sidebar-section-label,
.navbar-meta-label {
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  font-size: 0.72rem;
  color: #93c5fd;
}

.sidebar-brand {
  margin: 0.12rem 0 0;
  font-size: 1.05rem;
  line-height: 1.2;
}

.sidebar-profile-card,
.navbar-meta-card {
  border: 1px solid rgba(148, 163, 184, 0.14);
  background: rgba(15, 23, 42, 0.78);
  border-radius: 1.15rem;
  padding: 1rem;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.03);
}

.sidebar-nav {
  display: grid;
  gap: 0.45rem;
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.9rem 1rem;
  border-radius: 1rem;
  color: #cbd5e1;
  transition: transform 160ms ease, background-color 160ms ease, color 160ms ease, border-color 160ms ease;
  border: 1px solid transparent;
}

.sidebar-link:hover {
  transform: translateX(3px);
  background: rgba(30, 41, 59, 0.7);
  color: #f8fafc;
}

.sidebar-link--active {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.18), rgba(124, 58, 237, 0.14));
  color: #f8fafc;
  border-color: rgba(96, 165, 250, 0.2);
}

.sidebar-link__dot,
.status-dot {
  width: 0.6rem;
  height: 0.6rem;
  border-radius: 999px;
  background: linear-gradient(135deg, #60a5fa, #c084fc);
  box-shadow: 0 0 0 4px rgba(96, 165, 250, 0.12);
  flex: 0 0 auto;
}

.sidebar-footer {
  margin-top: auto;
}

.sidebar-logout {
  width: 100%;
}

.app-navbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.6rem 2rem 0.5rem;
}

.navbar-title {
  margin: 0.2rem 0 0.4rem;
  font-size: clamp(1.8rem, 2.8vw, 2.5rem);
  line-height: 1.05;
  letter-spacing: -0.03em;
}

.navbar-subtitle {
  max-width: 760px;
  margin: 0;
  color: #94a3b8;
}

.navbar-meta-card {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  min-width: 220px;
}

.page-shell {
  min-height: 100%;
  padding: 0.5rem 2rem 2rem;
}

.page-content {
  width: min(1180px, 100%);
}

.page-title {
  margin: 0 0 0.55rem;
  font-size: clamp(1.8rem, 2.4vw, 2.3rem);
  letter-spacing: -0.03em;
  font-weight: 800;
}

.muted {
  color: #94a3b8;
}

.card,
.ui-card,
.auth-card,
.item {
  position: relative;
  overflow: hidden;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.92) 0%, rgba(15, 23, 42, 0.84) 100%);
  border: 1px solid rgba(148, 163, 184, 0.14);
  box-shadow: 0 18px 40px rgba(2, 6, 23, 0.34);
}

.card,
.auth-card,
.ui-card {
  border-radius: 1.35rem;
  padding: 1.3rem;
}

.card {
  margin-bottom: 1rem;
}

.ui-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1rem;
}

.ui-card__title {
  margin: 0;
  font-size: 1.05rem;
}

.ui-card__subtitle {
  margin: 0.3rem 0 0;
  color: #94a3b8;
}

.ui-card__body {
  display: grid;
  gap: 0.9rem;
}

.grid {
  display: grid;
  gap: 1rem;
}

.grid-2 {
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
}

.grid-3 {
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.form {
  display: grid;
  gap: 1rem;
}

.form-row {
  display: grid;
  gap: 0.45rem;
}

.form-row label,
.ui-field__label {
  font-size: 0.92rem;
  font-weight: 700;
  color: #dbeafe;
}

.form-row input,
.form-row textarea,
.form-row select,
.ui-input {
  width: 100%;
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 1rem;
  padding: 0.85rem 1rem;
  background: rgba(15, 23, 42, 0.74);
  color: #eff6ff;
  outline: none;
  transition: border-color 160ms ease, box-shadow 160ms ease, background-color 160ms ease;
}

.form-row input::placeholder,
.form-row textarea::placeholder,
.ui-input::placeholder {
  color: #64748b;
}

.form-row input:focus,
.form-row textarea:focus,
.form-row select:focus,
.ui-input:focus {
  border-color: rgba(96, 165, 250, 0.6);
  box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.14);
  background: rgba(15, 23, 42, 0.92);
}

.form-row textarea {
  min-height: 120px;
  resize: vertical;
}

.ui-field {
  display: grid;
  gap: 0.45rem;
}

.ui-field__hint {
  color: #94a3b8;
  font-size: 0.85rem;
}

.ui-field__error,
.error {
  color: #fecaca;
}

.button-row {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.button,
.ui-button {
  border: none;
  border-radius: 0.95rem;
  padding: 0.82rem 1.08rem;
  font-weight: 700;
  transition: transform 160ms ease, box-shadow 160ms ease, background-color 160ms ease, opacity 160ms ease;
}

.button:hover,
.ui-button:hover {
  transform: translateY(-1px);
}

.button:disabled,
.ui-button:disabled {
  opacity: 0.68;
  cursor: not-allowed;
  transform: none;
}

.button,
.button.primary,
.ui-button--primary {
  color: #eff6ff;
  background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%);
  box-shadow: 0 14px 30px rgba(59, 130, 246, 0.3);
}

.button.secondary,
.ui-button--secondary {
  color: #eff6ff;
  background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
}

.button.ghost,
.ui-button--ghost {
  color: #dbeafe;
  background: rgba(30, 41, 59, 0.75);
  border: 1px solid rgba(148, 163, 184, 0.16);
}

.ui-button--sm {
  padding: 0.65rem 0.9rem;
}

.ui-button--lg {
  padding: 0.95rem 1.15rem;
}

.ui-button--full {
  width: 100%;
}

.error,
.success {
  border-radius: 1rem;
  padding: 0.85rem 1rem;
  border: 1px solid transparent;
  margin-bottom: 1rem;
}

.error {
  background: rgba(127, 29, 29, 0.24);
  border-color: rgba(248, 113, 113, 0.22);
}

.success {
  color: #bbf7d0;
  background: rgba(20, 83, 45, 0.24);
  border-color: rgba(74, 222, 128, 0.22);
}

.auth-shell {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 2rem;
  background:
    radial-gradient(circle at 20% 20%, rgba(59, 130, 246, 0.22), transparent 20%),
    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.16), transparent 18%),
    linear-gradient(180deg, #07111f 0%, #0b1527 45%, #0f1c31 100%);
}

.auth-card {
  width: min(500px, 100%);
}

.list {
  display: grid;
  gap: 0.8rem;
}

.item {
  border-radius: 1rem;
  padding: 1rem;
}

.pill,
.ui-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  border-radius: 999px;
  padding: 0.36rem 0.7rem;
  font-size: 0.84rem;
  font-weight: 700;
  margin-right: 0.45rem;
  margin-bottom: 0.45rem;
}

.pill,
.ui-badge--default {
  color: #dbeafe;
  background: rgba(37, 99, 235, 0.18);
  border: 1px solid rgba(96, 165, 250, 0.22);
}

.ui-badge--accent {
  color: #f5d0fe;
  background: rgba(168, 85, 247, 0.18);
  border: 1px solid rgba(216, 180, 254, 0.2);
}

.ui-badge--success {
  color: #bbf7d0;
  background: rgba(34, 197, 94, 0.16);
  border: 1px solid rgba(134, 239, 172, 0.18);
}

.ui-badge--warning {
  color: #fde68a;
  background: rgba(245, 158, 11, 0.16);
  border: 1px solid rgba(252, 211, 77, 0.18);
}

.kpi {
  margin: 0;
  font-size: 2.2rem;
  line-height: 1;
  font-weight: 800;
  letter-spacing: -0.04em;
}

hr {
  border: 0;
  border-top: 1px solid rgba(148, 163, 184, 0.12);
  margin: 1.35rem 0;
}

@media (max-width: 1040px) {
  .app-frame {
    grid-template-columns: 1fr;
  }

  .app-sidebar {
    position: relative;
    height: auto;
    border-right: none;
    border-bottom: 1px solid rgba(148, 163, 184, 0.12);
  }
}

@media (max-width: 720px) {
  .app-navbar,
  .page-shell {
    padding-left: 1rem;
    padding-right: 1rem;
  }

  .app-navbar {
    flex-direction: column;
  }

  .navbar-meta-card {
    width: 100%;
  }

  .button-row {
    flex-direction: column;
  }

  .button-row > * {
    width: 100%;
  }
}
EOF

echo "global styles rewritten"
