#!/bin/zsh
set -e

echo "applying phase 4 shell polish..."

cat > src/components/ui/Button.tsx <<'EOF'
import { ButtonHTMLAttributes, forwardRef } from "react";

type ButtonVariant = "primary" | "secondary" | "ghost";
type ButtonSize = "sm" | "md" | "lg";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
  size?: ButtonSize;
  fullWidth?: boolean;
};

function getClassName(
  variant: ButtonVariant,
  size: ButtonSize,
  fullWidth: boolean,
  className?: string
) {
  return [
    "ui-button",
    `ui-button--${variant}`,
    `ui-button--${size}`,
    fullWidth ? "ui-button--full" : "",
    className ?? ""
  ]
    .filter(Boolean)
    .join(" ");
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = "primary",
    size = "md",
    fullWidth = false,
    className,
    type = "button",
    ...props
  },
  ref
) {
  return (
    <button
      ref={ref}
      type={type}
      className={getClassName(variant, size, fullWidth, className)}
      {...props}
    />
  );
});

export default Button;
EOF

cat > src/components/ui/Card.tsx <<'EOF'
import { HTMLAttributes, ReactNode } from "react";

type CardProps = HTMLAttributes<HTMLDivElement> & {
  title?: ReactNode;
  subtitle?: ReactNode;
  actions?: ReactNode;
};

export default function Card({
  title,
  subtitle,
  actions,
  className = "",
  children,
  ...props
}: CardProps) {
  return (
    <section className={["ui-card", className].filter(Boolean).join(" ")} {...props}>
      {title || subtitle || actions ? (
        <div className="ui-card__header">
          <div className="ui-card__header-copy">
            {title ? <h3 className="ui-card__title">{title}</h3> : null}
            {subtitle ? <p className="ui-card__subtitle">{subtitle}</p> : null}
          </div>
          {actions ? <div className="ui-card__actions">{actions}</div> : null}
        </div>
      ) : null}
      <div className="ui-card__body">{children}</div>
    </section>
  );
}
EOF

cat > src/components/ui/Input.tsx <<'EOF'
import { forwardRef, InputHTMLAttributes } from "react";

type InputProps = InputHTMLAttributes<HTMLInputElement> & {
  label?: string;
  hint?: string;
  error?: string;
};

const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, hint, error, className = "", id, ...props },
  ref
) {
  const generatedId = id ?? props.name ?? "ui-input";

  return (
    <label className="ui-field" htmlFor={generatedId}>
      {label ? <span className="ui-field__label">{label}</span> : null}
      <input
        ref={ref}
        id={generatedId}
        className={["ui-input", className].filter(Boolean).join(" ")}
        {...props}
      />
      {error ? (
        <span className="ui-field__error">{error}</span>
      ) : hint ? (
        <span className="ui-field__hint">{hint}</span>
      ) : null}
    </label>
  );
});

export default Input;
EOF

cat > src/components/ui/Badge.tsx <<'EOF'
import { HTMLAttributes } from "react";

type BadgeTone = "default" | "accent" | "success" | "warning";

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: BadgeTone;
};

export default function Badge({
  tone = "default",
  className = "",
  children,
  ...props
}: BadgeProps) {
  return (
    <span
      className={["ui-badge", `ui-badge--${tone}`, className].filter(Boolean).join(" ")}
      {...props}
    >
      {children}
    </span>
  );
}
EOF

cat > src/components/navigation/Sidebar.tsx <<'EOF'
import { NavLink } from "react-router-dom";

type SidebarProps = {
  userName?: string;
  onLogout: () => void;
};

const navItems = [
  { to: "/dashboard", label: "Dashboard", short: "OV" },
  { to: "/onboarding", label: "Onboarding", short: "ON" },
  { to: "/recommendations", label: "Recommendations", short: "RE" },
  { to: "/restaurants", label: "Restaurants", short: "RS" },
  { to: "/experiences", label: "Experiences", short: "EX" }
];

export default function Sidebar({ userName, onLogout }: SidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand-block">
        <div className="sidebar-brand-mark">CA</div>

        <div>
          <p className="sidebar-eyebrow">Dining Intelligence</p>
          <h1 className="sidebar-brand">Context-Aware Dining</h1>
        </div>
      </div>

      <div className="sidebar-profile-card">
        <div className="sidebar-profile-card__top">
          <p className="sidebar-section-label">Signed in</p>
          <span className="sidebar-online-pill">Live</span>
        </div>

        <strong className="sidebar-user-name">{userName || "Guest user"}</strong>

        <p className="muted">
          Taste-led restaurant discovery and recommendation workflows.
        </p>
      </div>

      <nav className="sidebar-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              ["sidebar-link", isActive ? "sidebar-link--active" : ""]
                .filter(Boolean)
                .join(" ")
            }
          >
            <span className="sidebar-link__icon">{item.short}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-footer-card">
          <p className="sidebar-section-label">Workspace status</p>
          <p className="muted">UI shell upgraded and ready for deeper page-level polish.</p>
        </div>

        <button
          className="button ghost sidebar-logout"
          type="button"
          onClick={onLogout}
        >
          Logout
        </button>
      </div>
    </aside>
  );
}
EOF

cat > src/components/navigation/Navbar.tsx <<'EOF'
import { useLocation } from "react-router-dom";

type NavbarProps = {
  userName?: string;
};

const titleMap: Record<
  string,
  { eyebrow: string; title: string; subtitle: string }
> = {
  "/dashboard": {
    eyebrow: "Overview",
    title: "Dining command center",
    subtitle:
      "Track onboarding, jump into recommendation modes, and keep the product feeling polished."
  },
  "/onboarding": {
    eyebrow: "Profile setup",
    title: "Taste and preference onboarding",
    subtitle:
      "Capture the signals that drive more accurate recommendation outputs."
  },
  "/recommendations": {
    eyebrow: "Recommendation studio",
    title: "Plan the right dining experience",
    subtitle:
      "Run build-your-night, describe-your-night, and surprise-me flows from one workspace."
  },
  "/restaurants": {
    eyebrow: "Discovery",
    title: "Restaurant browsing",
    subtitle:
      "Inspect seeded venues, compare details, and explore the dining catalog."
  },
  "/experiences": {
    eyebrow: "Memory layer",
    title: "Dining experience history",
    subtitle:
      "Log visits, preserve context, and strengthen future recommendations."
  }
};

export default function Navbar({ userName }: NavbarProps) {
  const location = useLocation();

  const content = titleMap[location.pathname] ?? {
    eyebrow: "Workspace",
    title: "Context-Aware Dining Platform",
    subtitle: "Premium recommendation workflows with a cleaner dashboard shell."
  };

  const today = new Date().toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric"
  });

  return (
    <header className="app-navbar">
      <div className="navbar-copy">
        <p className="navbar-eyebrow">{content.eyebrow}</p>
        <h2 className="navbar-title">{content.title}</h2>
        <p className="navbar-subtitle">{content.subtitle}</p>
      </div>

      <div className="navbar-right">
        <div className="navbar-date-chip">{today}</div>

        <div className="navbar-meta-card">
          <span className="status-dot" />
          <div>
            <p className="navbar-meta-label">Active profile</p>
            <strong>{userName || "Guest user"}</strong>
          </div>
        </div>
      </div>
    </header>
  );
}
EOF

cat > src/components/layout/Layout.tsx <<'EOF'
import { ReactNode } from "react";
import { useNavigate } from "react-router-dom";

import Navbar from "../navigation/Navbar";
import Sidebar from "../navigation/Sidebar";
import { useAuth } from "../../context/AuthContext";

export default function Layout({ children }: { children: ReactNode }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const userName = user
    ? `${user.first_name} ${user.last_name}`.trim()
    : "Guest user";

  return (
    <div className="app-frame">
      <Sidebar userName={userName} onLogout={handleLogout} />

      <div className="app-main-column">
        <Navbar userName={userName} />

        <main className="page-shell">
          <div className="page-content">{children}</div>
        </main>
      </div>
    </div>
  );
}
EOF

cat > src/styles.css <<'EOF'
:root {
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  line-height: 1.5;
  font-weight: 400;
  color: #e7eefc;
  background:
    radial-gradient(circle at top left, rgba(56, 189, 248, 0.13), transparent 24%),
    radial-gradient(circle at top right, rgba(168, 85, 247, 0.12), transparent 22%),
    radial-gradient(circle at bottom center, rgba(45, 212, 191, 0.08), transparent 24%),
    linear-gradient(180deg, #07111f 0%, #0b1527 48%, #0e1a30 100%);
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;

  --bg-panel: rgba(9, 17, 31, 0.82);
  --bg-card: rgba(15, 23, 42, 0.86);
  --bg-card-strong: rgba(15, 23, 42, 0.94);
  --border-soft: rgba(148, 163, 184, 0.14);
  --border-strong: rgba(96, 165, 250, 0.2);
  --text-main: #e7eefc;
  --text-soft: #93a4bc;
  --text-faint: #64748b;
  --accent-a: #3b82f6;
  --accent-b: #8b5cf6;
  --accent-c: #22c55e;
  --shadow-soft: 0 18px 40px rgba(2, 6, 23, 0.34);
  --shadow-strong: 0 22px 60px rgba(2, 6, 23, 0.42);
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
  color: var(--text-main);
  background:
    radial-gradient(circle at top left, rgba(56, 189, 248, 0.13), transparent 24%),
    radial-gradient(circle at top right, rgba(168, 85, 247, 0.12), transparent 22%),
    radial-gradient(circle at bottom center, rgba(45, 212, 191, 0.08), transparent 24%),
    linear-gradient(180deg, #07111f 0%, #0b1527 48%, #0e1a30 100%);
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
  grid-template-columns: 310px minmax(0, 1fr);
}

.app-main-column {
  min-width: 0;
  display: flex;
  flex-direction: column;
  position: relative;
}

.app-main-column::before {
  content: "";
  position: absolute;
  inset: 0 0 auto 0;
  height: 220px;
  pointer-events: none;
  background: linear-gradient(180deg, rgba(59, 130, 246, 0.06), transparent);
}

.app-sidebar {
  position: sticky;
  top: 0;
  height: 100vh;
  padding: 1.25rem;
  border-right: 1px solid var(--border-soft);
  background: rgba(6, 12, 24, 0.9);
  backdrop-filter: blur(22px);
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}

.sidebar-brand-block {
  display: flex;
  align-items: center;
  gap: 0.95rem;
  padding: 0.25rem 0.15rem 0.6rem;
}

.sidebar-brand-mark {
  width: 3.05rem;
  height: 3.05rem;
  border-radius: 1rem;
  display: grid;
  place-items: center;
  font-weight: 800;
  font-size: 0.95rem;
  color: #eff6ff;
  background: linear-gradient(135deg, var(--accent-a) 0%, var(--accent-b) 100%);
  box-shadow: 0 18px 40px rgba(37, 99, 235, 0.28);
}

.sidebar-eyebrow,
.navbar-eyebrow,
.sidebar-section-label,
.navbar-meta-label {
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  font-size: 0.71rem;
  color: #8ec5ff;
}

.sidebar-brand {
  margin: 0.12rem 0 0;
  font-size: 1.06rem;
  line-height: 1.2;
  letter-spacing: -0.02em;
}

.sidebar-profile-card,
.navbar-meta-card,
.sidebar-footer-card {
  border: 1px solid var(--border-soft);
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.88), rgba(15, 23, 42, 0.76));
  border-radius: 1.15rem;
  padding: 1rem;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.03);
}

.sidebar-profile-card__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  margin-bottom: 0.55rem;
}

.sidebar-online-pill {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.24rem 0.55rem;
  font-size: 0.74rem;
  font-weight: 700;
  color: #bbf7d0;
  background: rgba(34, 197, 94, 0.15);
  border: 1px solid rgba(134, 239, 172, 0.16);
}

.sidebar-user-name {
  display: block;
  margin-bottom: 0.35rem;
}

.sidebar-nav {
  display: grid;
  gap: 0.52rem;
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 0.92rem 1rem;
  border-radius: 1rem;
  color: #cbd5e1;
  transition:
    transform 160ms ease,
    background-color 160ms ease,
    color 160ms ease,
    border-color 160ms ease,
    box-shadow 160ms ease;
  border: 1px solid transparent;
}

.sidebar-link:hover {
  transform: translateX(3px);
  background: rgba(30, 41, 59, 0.66);
  color: #f8fafc;
}

.sidebar-link--active {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.18), rgba(124, 58, 237, 0.14));
  color: #f8fafc;
  border-color: var(--border-strong);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.sidebar-link__icon {
  width: 2rem;
  height: 2rem;
  border-radius: 0.75rem;
  display: inline-grid;
  place-items: center;
  font-size: 0.7rem;
  font-weight: 800;
  color: #dbeafe;
  background: rgba(37, 99, 235, 0.16);
  border: 1px solid rgba(96, 165, 250, 0.12);
  flex: 0 0 auto;
}

.sidebar-footer {
  margin-top: auto;
  display: grid;
  gap: 0.75rem;
}

.sidebar-footer-card p:last-child {
  margin-bottom: 0;
}

.sidebar-logout {
  width: 100%;
}

.app-navbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.8rem 2rem 0.75rem;
  position: relative;
  z-index: 1;
}

.navbar-copy {
  max-width: 820px;
}

.navbar-title {
  margin: 0.18rem 0 0.45rem;
  font-size: clamp(1.9rem, 2.8vw, 2.65rem);
  line-height: 1.02;
  letter-spacing: -0.035em;
}

.navbar-subtitle {
  max-width: 760px;
  margin: 0;
  color: var(--text-soft);
}

.navbar-right {
  display: flex;
  align-items: stretch;
  gap: 0.8rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.navbar-date-chip {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.75rem 1rem;
  background: rgba(15, 23, 42, 0.74);
  border: 1px solid var(--border-soft);
  color: #dbeafe;
  min-height: 56px;
}

.navbar-meta-card {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  min-width: 220px;
}

.status-dot {
  width: 0.62rem;
  height: 0.62rem;
  border-radius: 999px;
  background: linear-gradient(135deg, #60a5fa, #c084fc);
  box-shadow: 0 0 0 4px rgba(96, 165, 250, 0.12);
  flex: 0 0 auto;
}

.page-shell {
  min-height: 100%;
  padding: 0.5rem 2rem 2.25rem;
  position: relative;
  z-index: 1;
}

.page-content {
  width: min(1220px, 100%);
  display: grid;
  gap: 1.2rem;
}

.page-title {
  margin: 0 0 0.55rem;
  font-size: clamp(1.9rem, 2.4vw, 2.35rem);
  letter-spacing: -0.035em;
  font-weight: 800;
}

.muted {
  color: var(--text-soft);
}

.card,
.ui-card,
.auth-card,
.item,
.json-box {
  position: relative;
  overflow: hidden;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.94) 0%, rgba(15, 23, 42, 0.84) 100%);
  border: 1px solid var(--border-soft);
  box-shadow: var(--shadow-soft);
}

.card,
.auth-card,
.ui-card {
  border-radius: 1.35rem;
  padding: 1.35rem;
}

.card::before,
.ui-card::before,
.auth-card::before {
  content: "";
  position: absolute;
  inset: 0 0 auto 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.12), transparent);
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

.ui-card__header-copy {
  min-width: 0;
}

.ui-card__title {
  margin: 0;
  font-size: 1.08rem;
  letter-spacing: -0.02em;
}

.ui-card__subtitle {
  margin: 0.34rem 0 0;
  color: var(--text-soft);
}

.ui-card__actions {
  flex: 0 0 auto;
}

.ui-card__body {
  display: grid;
  gap: 0.95rem;
}

.grid {
  display: grid;
  gap: 1rem;
}

.grid-2 {
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
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
  gap: 0.48rem;
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
  padding: 0.9rem 1rem;
  background: rgba(15, 23, 42, 0.76);
  color: #eff6ff;
  outline: none;
  transition:
    border-color 160ms ease,
    box-shadow 160ms ease,
    background-color 160ms ease,
    transform 160ms ease;
}

.form-row input::placeholder,
.form-row textarea::placeholder,
.ui-input::placeholder {
  color: var(--text-faint);
}

.form-row input:focus,
.form-row textarea:focus,
.form-row select:focus,
.ui-input:focus {
  border-color: rgba(96, 165, 250, 0.56);
  box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.14);
  background: rgba(15, 23, 42, 0.96);
  transform: translateY(-1px);
}

.form-row textarea {
  min-height: 124px;
  resize: vertical;
}

.ui-field {
  display: grid;
  gap: 0.45rem;
}

.ui-field__hint {
  color: var(--text-soft);
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
  border-radius: 0.98rem;
  padding: 0.84rem 1.12rem;
  font-weight: 700;
  transition:
    transform 160ms ease,
    box-shadow 160ms ease,
    background-color 160ms ease,
    opacity 160ms ease,
    border-color 160ms ease;
}

.button:hover,
.ui-button:hover {
  transform: translateY(-1px);
}

.button:active,
.ui-button:active {
  transform: translateY(0);
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
  background: linear-gradient(135deg, var(--accent-a) 0%, var(--accent-b) 100%);
  box-shadow: 0 14px 30px rgba(59, 130, 246, 0.28);
}

.button.secondary,
.ui-button--secondary {
  color: #eff6ff;
  background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
  border: 1px solid rgba(148, 163, 184, 0.16);
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
  padding: 0.96rem 1.16rem;
}

.ui-button--full {
  width: 100%;
}

.error,
.success {
  border-radius: 1rem;
  padding: 0.88rem 1rem;
  border: 1px solid transparent;
  margin-bottom: 1rem;
}

.error {
  background: rgba(127, 29, 29, 0.22);
  border-color: rgba(248, 113, 113, 0.2);
}

.success {
  color: #bbf7d0;
  background: rgba(20, 83, 45, 0.22);
  border-color: rgba(74, 222, 128, 0.2);
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
  width: min(520px, 100%);
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
  padding: 0.38rem 0.72rem;
  font-size: 0.82rem;
  font-weight: 700;
  margin-right: 0.45rem;
  margin-bottom: 0.45rem;
  backdrop-filter: blur(10px);
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
  font-size: 2.3rem;
  line-height: 1;
  font-weight: 800;
  letter-spacing: -0.05em;
}

.json-box {
  border-radius: 1rem;
  padding: 1rem;
}

hr {
  border: 0;
  border-top: 1px solid var(--border-soft);
  margin: 1.35rem 0;
}

.recommendation-mode-card {
  cursor: pointer;
  text-align: left;
  transition:
    transform 160ms ease,
    border-color 160ms ease,
    box-shadow 160ms ease,
    background-color 160ms ease;
}

.recommendation-mode-card:hover {
  transform: translateY(-2px);
}

.recommendation-mode-card.active {
  border-color: var(--border-strong);
  box-shadow: var(--shadow-strong);
}

.restaurant-card--active {
  border-color: var(--border-strong);
}

.experience-card,
.recommendation-card,
.restaurant-card {
  transition:
    transform 160ms ease,
    border-color 160ms ease,
    box-shadow 160ms ease;
}

.experience-card:hover,
.recommendation-card:hover,
.restaurant-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-strong);
}

@media (max-width: 1100px) {
  .app-frame {
    grid-template-columns: 1fr;
  }

  .app-sidebar {
    position: relative;
    height: auto;
    border-right: none;
    border-bottom: 1px solid var(--border-soft);
  }
}

@media (max-width: 760px) {
  .app-navbar,
  .page-shell {
    padding-left: 1rem;
    padding-right: 1rem;
  }

  .app-navbar {
    flex-direction: column;
    align-items: stretch;
  }

  .navbar-right {
    justify-content: stretch;
  }

  .navbar-date-chip,
  .navbar-meta-card {
    width: 100%;
  }

  .button-row {
    flex-direction: column;
  }

  .button-row > * {
    width: 100%;
  }

  .grid-2,
  .grid-3 {
    grid-template-columns: 1fr;
  }
}
EOF

echo "phase 4 shell polish applied"
echo "running build..."
npm run build
echo "phase 4 part 1 complete"
