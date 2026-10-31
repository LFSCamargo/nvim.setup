import { Reveal } from '@/shared/components/reveal';

const steps = [
  {
    number: '01',
    title: 'Find your place',
    text: 'Use Files to open a buffer, Ctrl+P to find a file, or Ctrl+F to search the project. Your editor stays in the center.',
  },
  {
    number: '02',
    title: 'Work beside your tools',
    text: 'Open Git to stage and inspect changes. Use Settings, Themes, or Extensions in the same sidebar to shape your workspace.',
  },
  {
    number: '03',
    title: 'Keep the conversation nearby',
    text: 'Start an agent from the right pane when you need one. It runs as its own CLI session; switching tabs leaves it running.',
  },
] as const;

export function Workflow() {
  return (
    <section id="how-it-works" className="mx-auto max-w-6xl px-6 py-20">
      <Reveal>
        <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
          02 / THE DAILY FLOW
        </p>
        <h2 className="mt-5 text-[clamp(2.1rem,4vw,3.4rem)] leading-tight font-medium tracking-[-0.04em]">
          Open a project.
          <br />
          <span className="text-muted">Stay in the work.</span>
        </h2>
      </Reveal>
      <div className="mt-10 grid gap-4 md:grid-cols-3">
        {steps.map((step) => (
          <Reveal key={step.number}>
            <div className="h-full rounded-2xl border border-line bg-glass p-6">
              <span className="font-mono text-[11px] text-muted">
                {step.number}
              </span>
              <h3 className="mt-6 text-lg font-medium">{step.title}</h3>
              <p className="mt-3 text-sm leading-7 text-muted">{step.text}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
