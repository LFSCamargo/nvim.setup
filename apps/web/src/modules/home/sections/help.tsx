import { HoverBorderGradient } from '@/shared/ui/hover-border-gradient';
import { Reveal } from '@/shared/ui/reveal';
import { helpUrl, issuesUrl } from '@/shared/site';

export function Help() {
  return (
    <section
      id="help"
      className="relative mx-auto max-w-6xl overflow-x-hidden px-6 pt-16 pb-24"
    >
      <Reveal className="relative z-10 max-w-2xl">
        <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
          YOU DO NOT HAVE TO FIGURE IT OUT ALONE
        </p>
        <h2 className="mt-5 text-[clamp(2.6rem,5vw,4rem)] leading-tight font-medium tracking-[-0.04em]">
          A little stuck?
          <br />
          <span className="font-serif italic">Let us work it out.</span>
        </h2>
        <p className="mt-6 text-sm leading-7 text-muted">
          Installation hiccup? A question about the workflow? Open an issue with
          what you are trying to do. Give us a little context, and we will have
          a better place to start.
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-5">
          <HoverBorderGradient as="a" href={helpUrl}>
            Ask for help <span aria-hidden="true">↗</span>
          </HoverBorderGradient>
          <a
            className="text-xs text-muted hover:text-foreground"
            href={issuesUrl}
          >
            Browse existing questions ↗
          </a>
        </div>
        <p className="mt-6 text-[11px] leading-6 text-muted">
          Include your OS, Neovim version, and the error you are seeing. Leave
          passwords, tokens, and private files out.
        </p>
      </Reveal>
      <div
        className="pointer-events-none absolute top-10 right-0 grid size-80 place-items-center opacity-40 md:opacity-100"
        aria-hidden="true"
      >
        <span className="rotate-12 font-serif text-[9rem] text-muted italic">
          ?
        </span>
        <div className="absolute inset-5 [transform:rotate(-25deg)_scaleY(0.55)] animate-orbit rounded-full border border-line" />
        <div className="absolute inset-0 [transform:rotate(35deg)_scaleY(0.7)] animate-orbit rounded-full border border-line [animation-direction:reverse] [animation-duration:28s]" />
        <div className="absolute inset-11 animate-orbit rounded-full border border-dashed border-line opacity-50 [animation-duration:35s]" />
      </div>
    </section>
  );
}
