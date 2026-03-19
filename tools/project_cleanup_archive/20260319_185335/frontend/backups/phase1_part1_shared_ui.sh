#!/bin/zsh
set -e

echo "writing shared ui primitives..."

mkdir -p src/components/ui

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
  { variant = "primary", size = "md", fullWidth = false, className, type = "button", ...props },
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
          <div>
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

echo "shared ui primitives written"
