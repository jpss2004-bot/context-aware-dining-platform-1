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
