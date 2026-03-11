import { ReactNode } from "react";
import { NavLink, useNavigate } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

export default function Layout({ children }: { children: ReactNode }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="page-shell">
      <header className="topbar">
        <div>
          <div className="brand">Context-Aware Dining Platform</div>
          <div className="muted">
            {user ? `Signed in as ${user.first_name} ${user.last_name}` : "Not signed in"}
          </div>
        </div>

        <nav className="nav-links">
          <NavLink className="nav-link" to="/dashboard">
            Dashboard
          </NavLink>
          <NavLink className="nav-link" to="/onboarding">
            Onboarding
          </NavLink>
          <NavLink className="nav-link" to="/recommendations">
            Recommendations
          </NavLink>
          <NavLink className="nav-link" to="/restaurants">
            Restaurants
          </NavLink>
          <NavLink className="nav-link" to="/experiences">
            Experiences
          </NavLink>
          <button className="nav-link" onClick={handleLogout} type="button">
            Logout
          </button>
        </nav>
      </header>

      <main className="page-content">{children}</main>
    </div>
  );
}
