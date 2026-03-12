import { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";

import { useAuth } from "../../context/AuthContext";

type ProtectedRouteProps = {
  children: ReactNode;
  allowIncompleteOnboarding?: boolean;
  redirectCompletedUsersTo?: string | null;
};

export default function ProtectedRoute({
  children,
  allowIncompleteOnboarding = false,
  redirectCompletedUsersTo = null
}: ProtectedRouteProps) {
  const { token, user, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading...</div>
      </div>
    );
  }

  if (!token) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (!user) {
    return (
      <div className="auth-shell">
        <div className="auth-card">Loading profile...</div>
      </div>
    );
  }

  if (!user.onboarding_completed && !allowIncompleteOnboarding) {
    return <Navigate to="/onboarding" replace state={{ from: location }} />;
  }

  if (user.onboarding_completed && redirectCompletedUsersTo) {
    return <Navigate to={redirectCompletedUsersTo} replace />;
  }

  return <>{children}</>;
}
