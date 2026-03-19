#!/usr/bin/env bash
set -euo pipefail

PATCH_NAME="patch6_flow_improvement_fixed"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=".${PATCH_NAME}_backup_${TIMESTAMP}"

echo "Starting ${PATCH_NAME}..."

# ------------------------------------------------------------
# Resolve frontend directory automatically
# Works if run from:
# 1) project root (contains frontend/)
# 2) frontend root itself
# ------------------------------------------------------------
if [[ -d "frontend/src" && -f "frontend/package.json" ]]; then
  PROJECT_ROOT="$(pwd)"
  FRONTEND_DIR="${PROJECT_ROOT}/frontend"
elif [[ -d "src" && -f "package.json" ]]; then
  FRONTEND_DIR="$(pwd)"
  PROJECT_ROOT="$(cd .. && pwd)"
else
  echo "ERROR: Could not find frontend directory."
  echo "Run this script either from:"
  echo "  - project root that contains frontend/"
  echo "  - or the frontend directory itself"
  exit 1
fi

echo "Resolved frontend directory: ${FRONTEND_DIR}"
cd "${FRONTEND_DIR}"

mkdir -p "${BACKUP_DIR}"
echo "Creating backup at: ${FRONTEND_DIR}/${BACKUP_DIR}"

for path in src package.json tsconfig.json vite.config.ts; do
  if [[ -e "$path" ]]; then
    cp -R "$path" "${BACKUP_DIR}/"
  fi
done

mkdir -p src/pages/recommendations
mkdir -p src/components/recommendations

# ------------------------------------------------------------
# Shared results helpers
# ------------------------------------------------------------
cat > src/components/recommendations/resultSession.ts <<'EOF'
export const RESULT_STORAGE_KEY = "savr:lastRecommendationResult";

export type StoredRecommendationResult = {
  mode: "build" | "describe" | "surprise";
  createdAt: string;
  request?: unknown;
  response: unknown;
};

export function saveRecommendationResult(result: StoredRecommendationResult) {
  sessionStorage.setItem(RESULT_STORAGE_KEY, JSON.stringify(result));
}

export function loadRecommendationResult(): StoredRecommendationResult | null {
  try {
    const raw = sessionStorage.getItem(RESULT_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as StoredRecommendationResult;
  } catch {
    return null;
  }
}

export function clearRecommendationResult() {
  sessionStorage.removeItem(RESULT_STORAGE_KEY);
}
EOF

# ------------------------------------------------------------
# Recommendations hub page
# ------------------------------------------------------------
cat > src/pages/recommendations/RecommendationsHubPage.tsx <<'EOF'
import { useNavigate } from "react-router-dom";

type FlowCard = {
  title: string;
  description: string;
  path: string;
  cta: string;
};

const flows: FlowCard[] = [
  {
    title: "Build a Night",
    description:
      "Choose the vibe, budget, timing, and preferences step by step to build a structured plan.",
    path: "/recommendations/build",
    cta: "Start building",
  },
  {
    title: "Describe the Night",
    description:
      "Write what kind of experience you want in natural language and let the system interpret it.",
    path: "/recommendations/describe",
    cta: "Start describing",
  },
  {
    title: "Surprise Me",
    description:
      "Get quick recommendations with minimal effort when you want something fun and fast.",
    path: "/recommendations/surprise",
    cta: "Get surprised",
  },
];

export default function RecommendationsHubPage() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-neutral-950 text-white">
      <div className="mx-auto max-w-6xl px-6 py-10">
        <div className="mb-10">
          <p className="text-sm uppercase tracking-[0.2em] text-neutral-400">
            Recommendation Flow
          </p>
          <h1 className="mt-2 text-4xl font-semibold tracking-tight">
            Choose how you want to plan your night
          </h1>
          <p className="mt-4 max-w-2xl text-neutral-300">
            Each path now has its own dedicated page so the experience feels focused,
            guided, and easier to follow.
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-3">
          {flows.map((flow) => (
            <button
              key={flow.path}
              onClick={() => navigate(flow.path)}
              className="rounded-2xl border border-neutral-800 bg-neutral-900 p-6 text-left transition hover:border-neutral-700 hover:bg-neutral-800"
            >
              <div className="flex h-full flex-col">
                <h2 className="text-2xl font-semibold">{flow.title}</h2>
                <p className="mt-3 flex-1 text-sm leading-6 text-neutral-300">
                  {flow.description}
                </p>
                <div className="mt-6 text-sm font-medium text-emerald-400">
                  {flow.cta} →
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# Build page
# ------------------------------------------------------------
cat > src/pages/recommendations/BuildNightPage.tsx <<'EOF'
import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { saveRecommendationResult } from "../../components/recommendations/resultSession";

type BuildForm = {
  vibe: string;
  budget: string;
  groupSize: string;
  timeOfDay: string;
  notes: string;
};

const initialState: BuildForm = {
  vibe: "",
  budget: "",
  groupSize: "",
  timeOfDay: "",
  notes: "",
};

export default function BuildNightPage() {
  const navigate = useNavigate();
  const [form, setForm] = useState<BuildForm>(initialState);
  const [loading, setLoading] = useState(false);

  const updateField = (key: keyof BuildForm, value: string) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);

    try {
      const res = await fetch("/api/recommendations/build-night", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });

      if (!res.ok) {
        throw new Error(`Request failed with status ${res.status}`);
      }

      const data = await res.json();

      saveRecommendationResult({
        mode: "build",
        createdAt: new Date().toISOString(),
        request: form,
        response: data,
      });

      navigate("/recommendations/results");
    } catch (error) {
      console.error("Build a Night request failed:", error);
      alert("Could not generate recommendations. Check the console and backend route.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-neutral-950 text-white">
      <div className="mx-auto max-w-3xl px-6 py-10">
        <button
          onClick={() => navigate("/recommendations")}
          className="mb-6 text-sm text-neutral-400 hover:text-white"
        >
          ← Back
        </button>

        <div className="mb-8">
          <p className="text-sm uppercase tracking-[0.2em] text-neutral-400">
            Build a Night
          </p>
          <h1 className="mt-2 text-4xl font-semibold tracking-tight">
            Create a structured night out
          </h1>
          <p className="mt-4 text-neutral-300">
            Focus on one decision flow at a time without dashboard clutter.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5 rounded-2xl border border-neutral-800 bg-neutral-900 p-6">
          <div>
            <label className="mb-2 block text-sm font-medium">Vibe</label>
            <input
              value={form.vibe}
              onChange={(e) => updateField("vibe", e.target.value)}
              placeholder="Cozy, casual, romantic, lively..."
              className="w-full rounded-xl border border-neutral-700 bg-neutral-950 px-4 py-3 outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium">Budget</label>
            <input
              value={form.budget}
              onChange={(e) => updateField("budget", e.target.value)}
              placeholder="$, $$, $$$ or a number range"
              className="w-full rounded-xl border border-neutral-700 bg-neutral-950 px-4 py-3 outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium">Group Size</label>
            <input
              value={form.groupSize}
              onChange={(e) => updateField("groupSize", e.target.value)}
              placeholder="2, 4, 6..."
              className="w-full rounded-xl border border-neutral-700 bg-neutral-950 px-4 py-3 outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium">Time of Day</label>
            <input
              value={form.timeOfDay}
              onChange={(e) => updateField("timeOfDay", e.target.value)}
              placeholder="Lunch, dinner, late night..."
              className="w-full rounded-xl border border-neutral-700 bg-neutral-950 px-4 py-3 outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium">Extra Notes</label>
            <textarea
              value={form.notes}
              onChange={(e) => updateField("notes", e.target.value)}
              rows={5}
              placeholder="Anything else the system should know?"
              className="w-full rounded-xl border border-neutral-700 bg-neutral-950 px-4 py-3 outline-none focus:border-emerald-500"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-emerald-500 px-4 py-3 font-medium text-black transition hover:bg-emerald-400 disabled:opacity-60"
          >
            {loading ? "Generating..." : "Generate Recommendations"}
          </button>
        </form>
      </div>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# Describe page
# ------------------------------------------------------------
cat > src/pages/recommendations/DescribeNightPage.tsx <<'EOF'
import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { saveRecommendationResult } from "../../components/recommendations/resultSession";

export default function DescribeNightPage() {
  const navigate = useNavigate();
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);

    try {
      const res = await fetch("/api/recommendations/describe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt: description }),
      });

      if (!res.ok) {
        throw new Error(`Request failed with status ${res.status}`);
      }

      const data = await res.json();

      saveRecommendationResult({
        mode: "describe",
        createdAt: new Date().toISOString(),
        request: { prompt: description },
        response: data,
      });

      navigate("/recommendations/results");
    } catch (error) {
      console.error("Describe request failed:", error);
      alert("Could not generate recommendations. Check the console and backend route.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-neutral-950 text-white">
      <div className="mx-auto max-w-3xl px-6 py-10">
        <button
          onClick={() => navigate("/recommendations")}
          className="mb-6 text-sm text-neutral-400 hover:text-white"
        >
          ← Back
        </button>

        <div className="mb-8">
          <p className="text-sm uppercase tracking-[0.2em] text-neutral-400">
            Describe the Night
          </p>
          <h1 className="mt-2 text-4xl font-semibold tracking-tight">
            Explain the experience in your own words
          </h1>
          <p className="mt-4 text-neutral-300">
            This page keeps the prompt experience focused and separate from the results.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5 rounded-2xl border border-neutral-800 bg-neutral-900 p-6">
          <div>
            <label className="mb-2 block text-sm font-medium">Your description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={8}
              placeholder="Example: I want a cozy but slightly lively dinner spot with great cocktails for a group of 4..."
              className="w-full rounded-xl border border-neutral-700 bg-neutral-950 px-4 py-3 outline-none focus:border-emerald-500"
            />
          </div>

          <button
            type="submit"
            disabled={loading || !description.trim()}
            className="w-full rounded-xl bg-emerald-500 px-4 py-3 font-medium text-black transition hover:bg-emerald-400 disabled:opacity-60"
          >
            {loading ? "Generating..." : "Generate Recommendations"}
          </button>
        </form>
      </div>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# Surprise page
# ------------------------------------------------------------
cat > src/pages/recommendations/SurpriseMePage.tsx <<'EOF'
import { useNavigate } from "react-router-dom";
import { saveRecommendationResult } from "../../components/recommendations/resultSession";
import { useState } from "react";

export default function SurpriseMePage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  async function handleSurprise() {
    setLoading(true);

    try {
      const res = await fetch("/api/recommendations/surprise", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });

      if (!res.ok) {
        throw new Error(`Request failed with status ${res.status}`);
      }

      const data = await res.json();

      saveRecommendationResult({
        mode: "surprise",
        createdAt: new Date().toISOString(),
        response: data,
      });

      navigate("/recommendations/results");
    } catch (error) {
      console.error("Surprise request failed:", error);
      alert("Could not generate recommendations. Check the console and backend route.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-neutral-950 text-white">
      <div className="mx-auto max-w-3xl px-6 py-10">
        <button
          onClick={() => navigate("/recommendations")}
          className="mb-6 text-sm text-neutral-400 hover:text-white"
        >
          ← Back
        </button>

        <div className="rounded-2xl border border-neutral-800 bg-neutral-900 p-8 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-neutral-400">
            Surprise Me
          </p>
          <h1 className="mt-3 text-4xl font-semibold tracking-tight">
            Let the platform choose for you
          </h1>
          <p className="mx-auto mt-4 max-w-xl text-neutral-300">
            No long forms. No clutter. Just a fast path to recommendations.
          </p>

          <button
            onClick={handleSurprise}
            disabled={loading}
            className="mt-8 rounded-xl bg-emerald-500 px-6 py-3 font-medium text-black transition hover:bg-emerald-400 disabled:opacity-60"
          >
            {loading ? "Generating..." : "Surprise Me"}
          </button>
        </div>
      </div>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# Results page
# ------------------------------------------------------------
cat > src/pages/recommendations/RecommendationResultsPage.tsx <<'EOF'
import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { clearRecommendationResult, loadRecommendationResult } from "../../components/recommendations/resultSession";

function prettyJson(value: unknown) {
  return JSON.stringify(value, null, 2);
}

export default function RecommendationResultsPage() {
  const navigate = useNavigate();
  const result = useMemo(() => loadRecommendationResult(), []);

  if (!result) {
    return (
      <div className="min-h-screen bg-neutral-950 text-white">
        <div className="mx-auto max-w-3xl px-6 py-10">
          <div className="rounded-2xl border border-neutral-800 bg-neutral-900 p-8">
            <h1 className="text-3xl font-semibold">No recommendation results found</h1>
            <p className="mt-3 text-neutral-300">
              Start a recommendation flow first so results can be displayed here.
            </p>
            <button
              onClick={() => navigate("/recommendations")}
              className="mt-6 rounded-xl bg-emerald-500 px-5 py-3 font-medium text-black"
            >
              Go to Recommendation Hub
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-950 text-white">
      <div className="mx-auto max-w-5xl px-6 py-10">
        <div className="mb-8 flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="text-sm uppercase tracking-[0.2em] text-neutral-400">
              Recommendation Results
            </p>
            <h1 className="mt-2 text-4xl font-semibold tracking-tight">
              Your generated recommendations
            </h1>
            <p className="mt-3 text-neutral-300">
              Generated from the <span className="font-medium text-white">{result.mode}</span> flow.
            </p>
          </div>

          <div className="flex gap-3">
            <button
              onClick={() => navigate("/recommendations")}
              className="rounded-xl border border-neutral-700 px-4 py-2 text-sm"
            >
              New flow
            </button>
            <button
              onClick={() => {
                clearRecommendationResult();
                navigate("/recommendations");
              }}
              className="rounded-xl bg-emerald-500 px-4 py-2 text-sm font-medium text-black"
            >
              Clear and restart
            </button>
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-[1fr_1.2fr]">
          <section className="rounded-2xl border border-neutral-800 bg-neutral-900 p-6">
            <h2 className="text-xl font-semibold">Request</h2>
            <pre className="mt-4 overflow-x-auto rounded-xl bg-neutral-950 p-4 text-sm text-neutral-200">
{prettyJson(result.request ?? { note: "No explicit request body for this flow." })}
            </pre>
          </section>

          <section className="rounded-2xl border border-neutral-800 bg-neutral-900 p-6">
            <h2 className="text-xl font-semibold">Response</h2>
            <pre className="mt-4 max-h-[70vh] overflow-auto rounded-xl bg-neutral-950 p-4 text-sm text-neutral-200">
{prettyJson(result.response)}
            </pre>
          </section>
        </div>
      </div>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# Try to patch router file safely
# ------------------------------------------------------------
ROUTER_FILE=""
for candidate in \
  "src/App.tsx" \
  "src/main.tsx" \
  "src/router.tsx" \
  "src/routes.tsx" \
  "src/app/router.tsx"
do
  if [[ -f "$candidate" ]]; then
    ROUTER_FILE="$candidate"
    break
  fi
done

if [[ -z "$ROUTER_FILE" ]]; then
  echo "ERROR: Could not find router file automatically."
  echo "Patch content files were created, but routes must be wired manually."
  exit 1
fi

echo "Patching router file: $ROUTER_FILE"

PYTHON_BIN="python3"
if [[ -x ".venv/bin/python" ]]; then
  PYTHON_BIN=".venv/bin/python"
fi

"$PYTHON_BIN" - <<PYEOF
from pathlib import Path
import re

router_path = Path("$ROUTER_FILE")
text = router_path.read_text()

imports_to_add = [
    'import RecommendationsHubPage from "./pages/recommendations/RecommendationsHubPage";',
    'import BuildNightPage from "./pages/recommendations/BuildNightPage";',
    'import DescribeNightPage from "./pages/recommendations/DescribeNightPage";',
    'import SurpriseMePage from "./pages/recommendations/SurpriseMePage";',
    'import RecommendationResultsPage from "./pages/recommendations/RecommendationResultsPage";',
]

for imp in imports_to_add:
    if imp not in text:
        if 'from "react-router-dom"' in text or "from 'react-router-dom'" in text:
            lines = text.splitlines()
            insert_at = 0
            for i, line in enumerate(lines):
                if line.startswith("import "):
                    insert_at = i + 1
            lines.insert(insert_at, imp)
            text = "\\n".join(lines)
        else:
            text = imp + "\\n" + text

route_block = """
      <Route path="/recommendations" element={<RecommendationsHubPage />} />
      <Route path="/recommendations/build" element={<BuildNightPage />} />
      <Route path="/recommendations/describe" element={<DescribeNightPage />} />
      <Route path="/recommendations/surprise" element={<SurpriseMePage />} />
      <Route path="/recommendations/results" element={<RecommendationResultsPage />} />
"""

if "/recommendations/build" not in text:
    text = re.sub(
        r"(</Routes>)",
        route_block + r"\\n\\1",
        text,
        count=1
    )

text = text.replace('path="/recommendations" element={<RecommendationsPage />}', 'path="/recommendations-legacy" element={<RecommendationsHubPage />}')
text = text.replace("path='/recommendations' element={<RecommendationsPage />}", "path='/recommendations-legacy' element={<RecommendationsHubPage />}")
text = text.replace('to="/recommendations"', 'to="/recommendations"')

router_path.write_text(text)
PYEOF

# ------------------------------------------------------------
# Patch navigation links in common files
# ------------------------------------------------------------
for navfile in \
  src/components/Sidebar.tsx \
  src/components/Layout.tsx \
  src/components/NavBar.tsx \
  src/components/Navbar.tsx \
  src/pages/Dashboard.tsx \
  src/pages/HomePage.tsx
do
  if [[ -f "$navfile" ]]; then
    "$PYTHON_BIN" - <<PYEOF
from pathlib import Path
p = Path("$navfile")
text = p.read_text()
text = text.replace('to="/recommendations"', 'to="/recommendations"')
text = text.replace("to='/recommendations'", "to='/recommendations'")
text = text.replace('navigate("/recommendations")', 'navigate("/recommendations")')
text = text.replace("navigate('/recommendations')", "navigate('/recommendations')")
p.write_text(text)
PYEOF
  fi
done

echo "Running TypeScript check..."
if command -v npx >/dev/null 2>&1; then
  npx tsc -b || true
else
  echo "npx not found; skipping TypeScript check."
fi

echo
echo "Patch 6 flow improvement applied."
echo "Next steps:"
echo "1) npm run dev"
echo "2) Test /recommendations"
echo "3) Open Build / Describe / Surprise flows"
echo "4) Submit and confirm redirect to /recommendations/results"
