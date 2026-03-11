import { Link } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

export default function DashboardPage() {
  const { user } = useAuth();

  return (
    <>
      <section className="card">
        <h1 className="page-title">Dashboard</h1>
        <p className="muted">
          Welcome back{user ? `, ${user.first_name}` : ""}. Your backend is connected and ready.
        </p>
      </section>

      <section className="grid grid-3">
        <div className="card">
          <p className="kpi">{user?.onboarding_completed ? "Done" : "Pending"}</p>
          <p className="muted">Onboarding status</p>
          <Link to="/onboarding">Go to onboarding</Link>
        </div>

        <div className="card">
          <p className="kpi">3 Modes</p>
          <p className="muted">Recommendation flows supported</p>
          <Link to="/recommendations">Open recommendations</Link>
        </div>

        <div className="card">
          <p className="kpi">Seeded</p>
          <p className="muted">Restaurant dataset loaded</p>
          <Link to="/restaurants">Browse restaurants</Link>
        </div>
      </section>

      <section className="card">
        <h2>Next useful actions</h2>
        <div className="button-row">
          <Link className="button" to="/onboarding">
            Complete onboarding
          </Link>
          <Link className="button secondary" to="/recommendations">
            Get recommendations
          </Link>
          <Link className="button ghost" to="/experiences">
            Log an experience
          </Link>
        </div>
      </section>
    </>
  );
}
