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
