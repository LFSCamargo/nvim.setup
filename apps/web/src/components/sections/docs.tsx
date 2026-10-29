import { Link } from 'react-router-dom';
import { LiquidGlass } from '@/components/ui/liquid-glass';
import { Reveal } from '@/components/reveal';
import { docLinks, repo } from '@/content';

export function Docs() {
  return (
    <section id="docs" className="mx-auto max-w-6xl px-6 py-24">
      <Reveal className="mb-12 flex flex-col justify-between gap-8 md:flex-row md:items-end">
        <div>
          <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
            03 / A MAP, NOT A MAZE
          </p>
          <h2 className="mt-5 text-[clamp(2.1rem,4vw,3.4rem)] leading-tight font-medium tracking-[-0.04em]">
            Good tools deserve
            <br />
            <span className="font-serif italic">good documentation.</span>
          </h2>
        </div>
        <p className="max-w-sm text-sm leading-7 text-muted">
          Read the guides on this site. Open the same files on GitHub when you
          want the source.
        </p>
      </Reveal>
      <div className="flex flex-col gap-3">
        {docLinks.map((doc) => (
          <Reveal key={doc.slug}>
            <LiquidGlass
              radius={20}
              bevelDepth={12}
              scale={24}
              frost={0.7}
              tint={0.05}
              className="border border-line transition hover:border-foreground/20"
              contentClassName="relative grid grid-cols-[auto_1fr_auto] items-center gap-5 px-5 py-6 md:grid-cols-[3rem_1fr_1fr_auto]"
            >
              <span className="font-mono text-[10px] text-muted">
                {doc.number}
              </span>
              <h3 className="text-xl font-medium tracking-tight">
                <Link
                  to={`/docs/${doc.slug}`}
                  className="hover:text-foreground"
                >
                  {doc.title}
                </Link>
              </h3>
              <p className="col-start-2 text-sm leading-6 text-muted md:col-start-auto">
                {doc.description}
              </p>
              <div className="flex items-center gap-4">
                <Link
                  to={`/docs/${doc.slug}`}
                  className="text-sm text-foreground/80 hover:text-foreground"
                >
                  Read
                </Link>
                <a
                  href={`${repo}/blob/main/${doc.file}`}
                  className="text-2xl text-muted hover:text-foreground"
                  aria-label={`View ${doc.title} on GitHub`}
                >
                  ↗
                </a>
              </div>
            </LiquidGlass>
          </Reveal>
        ))}
      </div>
      <Reveal className="mt-8">
        <Link
          to="/docs"
          className="inline-flex items-center gap-2 text-sm text-foreground/80 hover:text-foreground"
        >
          Open the full documentation ↗
        </Link>
      </Reveal>
    </section>
  );
}
