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
