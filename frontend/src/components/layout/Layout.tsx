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
