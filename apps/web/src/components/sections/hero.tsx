import { FlipWords } from '@/components/ui/flip-words';
import { HoverBorderGradient } from '@/components/ui/hover-border-gradient';
import { Spotlight } from '@/components/ui/spotlight-new';
import { TextGenerateEffect } from '@/components/ui/text-generate-effect';
import { Reveal } from '@/components/reveal';
import { ScreenshotFrame } from '@/components/screenshot-frame';
import { heroWords, screens } from '@/content';

type HeroProps = {
  onOpenScreenshot: (index: number) => void;
};

export function Hero({ onOpenScreenshot }: HeroProps) {
  const screen = screens[0];

  return (
    <section className="relative overflow-x-hidden px-6 pt-28 pb-10 md:pt-32">
      <Spotlight />
      <div
        className="pointer-events-none absolute inset-0 bg-[linear-gradient(var(--grid)_1px,transparent_1px),linear-gradient(90deg,var(--grid)_1px,transparent_1px)] [mask-image:linear-gradient(transparent,rgb(0_0_0/0.55),transparent)] bg-size-[72px_72px]"
        aria-hidden="true"
      />
      <div className="relative z-10 mx-auto max-w-6xl text-center">
        <Reveal>
          <p className="flex items-center justify-center gap-2 font-mono text-[10px] tracking-[0.18em] text-muted">
            <span className="size-1.5 rounded-full bg-foreground shadow-[0_0_14px_rgb(255_255_255/0.4)] dark:shadow-[0_0_14px_rgb(255_255_255/0.4)]" />
            YOUR TERMINAL. YOUR RULES.
          </p>
          <h1 className="mt-7 text-[clamp(3.4rem,8vw,6.6rem)] leading-[0.95] font-medium tracking-[-0.06em]">
            A quieter place
            <br />
            to{' '}
            <FlipWords
              words={heroWords}
              className="font-serif text-[1.08em] tracking-[-0.05em] italic"
            />
            <span
              className="ml-2 inline-block animate-blink font-mono text-[0.72em] font-normal"
              aria-hidden="true"
            >
              ▌
            </span>
          </h1>
          <TextGenerateEffect
            className="mx-auto mt-7 max-w-xl text-base"
            words="The speed of Neovim. A workspace that feels complete. Code, Git, and AI chats — right where you work."
          />
          <div className="mt-8 flex flex-wrap items-center justify-center gap-6">
            <HoverBorderGradient as="a" href="#install">
              Make it yours <span aria-hidden="true">↗</span>
            </HoverBorderGradient>
            <a
              className="inline-flex items-center gap-3 text-xs text-muted hover:text-foreground"
              href="#workspace"
            >
              Explore the workspace <span aria-hidden="true">↓</span>
            </a>
          </div>
          <p className="mt-7 font-mono text-[10px] tracking-[0.12em] text-muted">
            OPEN SOURCE · macOS + Linux · BUILT ON NEOVIM
          </p>
        </Reveal>
        <Reveal className="mt-16">
          <div className="mb-8 flex flex-col items-center gap-4">
            <span className="h-px w-16 bg-line" aria-hidden="true" />
            <p className="max-w-xl font-serif text-[1.7rem] leading-tight tracking-[-0.04em] text-balance italic md:text-[2.15rem]">
              Less switching.
              <span className="text-muted"> More making.</span>
            </p>
          </div>
          <ScreenshotFrame tilt>
            <button
              className="group relative block w-full overflow-hidden bg-zinc-950 text-left"
              onClick={() => onOpenScreenshot(0)}
              aria-label="Enlarge workspace screenshot"
            >
              <img
                src={screen.src}
                alt={screen.alt}
                width={screen.width}
                height={screen.height}
                fetchPriority="high"
                className="block h-auto w-full"
              />
              <span className="absolute right-4 bottom-4 rounded-md border border-white/20 bg-black/70 px-3 py-2 font-mono text-[10px] opacity-0 transition group-hover:opacity-100 group-focus-visible:opacity-100">
                View full screen ↗
              </span>
            </button>
          </ScreenshotFrame>
          <div className="mt-4 flex justify-between font-mono text-[10px] tracking-[0.12em] text-muted">
            <span>01 / THE WORKSPACE</span>
            <span>Actual setup. Real screenshots.</span>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
