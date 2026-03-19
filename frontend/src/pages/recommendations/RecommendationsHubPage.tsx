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
