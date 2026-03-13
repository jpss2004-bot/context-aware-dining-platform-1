import { InputHTMLAttributes, useId, useState } from "react";

type PasswordFieldProps = Omit<InputHTMLAttributes<HTMLInputElement>, "type"> & {
  label: string;
  hint?: string;
};

export default function PasswordField({
  label,
  hint,
  id,
  className,
  ...props
}: PasswordFieldProps) {
  const generatedId = useId();
  const inputId = id || generatedId;
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div className="form-row">
      <label htmlFor={inputId}>{label}</label>

      <div className={["password-input-shell", className ?? ""].filter(Boolean).join(" ")}>
        <input
          {...props}
          id={inputId}
          type={isVisible ? "text" : "password"}
          className="password-input-shell__input"
        />
        <button
          type="button"
          className="password-toggle"
          onClick={() => setIsVisible((current) => !current)}
          aria-label={isVisible ? "Hide password" : "Show password"}
        >
          {isVisible ? "Hide" : "Show"}
        </button>
      </div>

      {hint ? <small className="muted">{hint}</small> : null}
    </div>
  );
}
