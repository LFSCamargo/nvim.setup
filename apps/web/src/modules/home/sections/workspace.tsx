import { useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { GlowingEffect } from '@/shared/ui/glowing-effect';
import { LiquidGlass } from '@/shared/ui/liquid-glass';
import { Reveal } from '@/shared/ui/reveal';
import { ScreenshotFrame } from '@/modules/home/screenshots/screenshot-frame';
import { features, screens } from '@/modules/home/content';
import { cn } from '@/shared/utils';

type WorkspaceProps = {
  onOpenScreenshot: (index: number) => void;
};

export function Workspace({ onOpenScreenshot }: WorkspaceProps) {
  const [screen, setScreen] = useState(0);
  const reduced = useReducedMotion();
  const current = screens[screen] ?? screens[0];

  return (
    <section
      id="workspace"
      className="mx-auto max-w-6xl px-6 pt-24 pb-20 md:pt-28"
    >
      <Reveal className="mb-12 flex flex-col justify-between gap-8 md:flex-row md:items-end">
        <div>
          <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
            01 / FEEL AT HOME
          </p>
          <h2 className="mt-5 text-[clamp(2.1rem,4vw,3.4rem)] leading-tight font-medium tracking-[-0.04em]">
            Everything in place.
            <br />
            <span className="text-muted">Nothing in your way.</span>
          </h2>
        </div>
        <p className="max-w-sm text-sm leading-7 text-muted">
          A familiar layout, with Neovim underneath. Move with your keyboard.
          Click when it is easier. Keep the tools. Lose the context switching.
        </p>
      </Reveal>
      <Reveal>
        <div className="mb-4 flex min-w-0 items-center justify-between gap-4">
          <div
            className="flex min-w-0 flex-wrap rounded-xl border border-line bg-glass p-1"
            aria-label="Screenshot views"
          >
            {screens.map((item, index) => (
              <button
                key={item.id}
                aria-pressed={screen === index}
                onClick={() => setScreen(index)}
                className={cn(
                  'relative rounded-lg px-4 py-2 text-xs text-muted',
                  screen === index && 'text-foreground',
                )}
              >
                {screen === index ? (
                  <motion.span
                    layoutId="active-view"
                    className="absolute inset-0 rounded-lg bg-foreground/10"
                    transition={{ duration: reduced ? 0 : 0.25 }}
                  />
                ) : null}
                <span className="relative">{item.label}</span>
              </button>
            ))}
          </div>
          <span className="hidden font-mono text-[10px] tracking-[0.14em] text-muted sm:inline">
            CAPTURED FROM THE APPLICATION ↗
          </span>
        </div>
        <ScreenshotFrame>
          <button
            className="group relative block w-full overflow-hidden bg-zinc-950 text-left"
            onClick={() => onOpenScreenshot(screen)}
            aria-label={`Enlarge ${current.label.toLowerCase()} screenshot`}
          >
            <AnimatePresence mode="wait">
              <motion.img
                key={current.src}
                initial={{ opacity: reduced ? 1 : 0.4 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: reduced ? 1 : 0.4 }}
                transition={{ duration: 0.18 }}
                src={current.src}
                alt={current.alt}
                width={current.width}
                height={current.height}
                loading="lazy"
                className="block h-auto w-full"
              />
            </AnimatePresence>
            <span className="absolute right-4 bottom-4 rounded-md border border-white/20 bg-black/70 px-3 py-2 font-mono text-[10px] opacity-0 transition group-hover:opacity-100 group-focus-visible:opacity-100">
              Take a closer look ↗
            </span>
          </button>
        </ScreenshotFrame>
        <p className="mt-5 text-center text-sm text-muted">{current.caption}</p>
      </Reveal>
      <div className="mt-16 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
        {features.map((feature) => (
          <Reveal key={feature.number}>
            <LiquidGlass
              radius={22}
              bevelDepth={14}
              scale={32}
              frost={0.7}
              tint={0.06}
              className="relative h-full border border-line p-6"
            >
              <GlowingEffect spread={32} glow proximity={80} />
              <div className="flex justify-between font-mono text-[11px] text-muted">
                <span>{feature.number}</span>
                <span aria-hidden="true">↗</span>
              </div>
              <h3 className="mt-6 text-lg font-medium tracking-tight">
                {feature.title}
              </h3>
              <p className="mt-3 text-sm leading-7 text-muted">
                {feature.description}
              </p>
              <span className="mt-6 block font-mono text-[10px] tracking-[0.12em] text-foreground/80 uppercase">
                {feature.tag}
              </span>
            </LiquidGlass>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
