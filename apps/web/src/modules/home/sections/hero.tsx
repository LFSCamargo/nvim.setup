import { useEffect, useRef } from 'react';
import { useReducedMotion } from 'motion/react';
import { FlipWords } from '@/shared/components/flip-words';
import { HoverBorderGradient } from '@/shared/components/hover-border-gradient';
import { Spotlight } from '@/shared/components/spotlight-new';
import { TextGenerateEffect } from '@/shared/components/text-generate-effect';
import { Reveal } from '@/shared/components/reveal';
import { heroWords } from '@/modules/home/content';

export function Hero() {
  const reduced = useReducedMotion();
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const video = videoRef.current;
    if (!video || reduced !== false) return;
    video.muted = true;
    const pending = video.play();
    if (pending) void pending.catch(() => {});
  }, [reduced]);

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
            <span className="size-1.5 rounded-full bg-foreground shadow-[0_0_14px_rgb(20_20_22/0.28)] dark:shadow-[0_0_14px_rgb(255_255_255/0.4)]" />
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
              data-hero-caret
              className="ml-1 inline-block h-[0.72em] w-[0.08em] translate-y-[0.08em] animate-blink bg-foreground align-middle"
              aria-hidden="true"
            />
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
          <div
            data-demo
            data-rim="dark"
            className="overflow-hidden rounded-[18px] border border-white/12 bg-zinc-950"
          >
            <video
              ref={videoRef}
              className="block aspect-video h-auto w-full bg-zinc-950"
              src="/assets/nvim-setup-demo.mp4"
              poster="/assets/nvim-setup-demo-poster.jpg"
              width={1920}
              height={1080}
              controls
              playsInline
              muted
              loop={reduced !== true}
              preload="metadata"
              aria-label="Demo of nvim.setup"
            />
          </div>
          <div className="mt-4 flex justify-between font-mono text-[10px] tracking-[0.12em] text-muted">
            <span>THE DEMO</span>
            <span>A launch film of the real setup.</span>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
