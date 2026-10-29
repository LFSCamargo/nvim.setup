import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { MarkdownView } from '@/components/markdown-view';
import { Nav } from '@/components/sections/nav';
import { SiteFooter } from '@/components/sections/site-footer';
import { LiquidGlass } from '@/components/ui/liquid-glass';
import { docPages, getDocPage, githubDocUrl } from '@/lib/docs';
import { cn } from '@/lib/utils';

const groups = ['Start', 'Reference'] as const;

export function DocsPage() {
  const { slug } = useParams();
  const page = getDocPage(slug);
  const [menu, setMenu] = useState(false);
  const [markdown, setMarkdown] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    setMarkdown('');
    setError('');
    fetch(page.src)
      .then((response) => {
        if (!response.ok) throw new Error(`Failed to load ${page.src}`);
        return response.text();
      })
      .then((text) => {
        if (!cancelled) setMarkdown(text);
      })
      .catch(() => {
        if (!cancelled) setError('Could not load this guide.');
      });
    return () => {
      cancelled = true;
    };
  }, [page.src]);

  return (
    <>
      <a
        className="fixed top-[-100px] left-5 z-50 bg-white px-3 py-3 text-black focus:top-3"
        href="#doc"
      >
        Skip to documentation
      </a>
      <Nav />
      <main className="overflow-x-hidden px-4 pt-24 pb-16 md:px-6 md:pt-28">
        <div className="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[16.5rem_minmax(0,1fr)]">
          <aside>
            <LiquidGlass
              radius={20}
              bevelDepth={12}
              scale={24}
              frost={0.7}
              tint={0.06}
              className="border border-line lg:sticky lg:top-24"
              contentClassName="relative p-4"
            >
              <div className="mb-3 flex items-center justify-between gap-3 lg:block">
                <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
                  DOCUMENTATION
                </p>
                <button
                  className="rounded-full border border-line px-3 py-1 text-xs lg:hidden"
                  aria-expanded={menu}
                  aria-controls="docs-nav"
                  onClick={() => setMenu((open) => !open)}
                >
                  {menu ? 'Hide −' : 'Contents +'}
                </button>
              </div>
              <nav
                id="docs-nav"
                aria-label="Documentation"
                className={cn(
                  'flex flex-col gap-5',
                  menu ? 'flex' : 'hidden lg:flex',
                )}
              >
                {groups.map((group) => (
                  <div key={group}>
                    <p className="mb-2 font-mono text-[10px] tracking-[0.14em] text-muted">
                      {group}
                    </p>
                    <ul className="flex flex-col gap-1">
                      {docPages
                        .filter((item) => item.group === group)
                        .map((item) => (
                          <li key={item.slug}>
                            <Link
                              to={`/docs/${item.slug}`}
                              onClick={() => setMenu(false)}
                              className={cn(
                                'block rounded-lg px-3 py-2 text-sm text-muted hover:bg-glass hover:text-foreground',
                                item.slug === page.slug &&
                                  'bg-glass text-foreground',
                              )}
                            >
                              {item.title}
                            </Link>
                          </li>
                        ))}
                    </ul>
                  </div>
                ))}
              </nav>
            </LiquidGlass>
          </aside>
          <article
            id="doc"
            className="rounded-[22px] border border-line bg-surface px-6 py-8 glass-rim md:px-10 md:py-10"
          >
            <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
              {page.group.toUpperCase()} / {page.title.toUpperCase()}
            </p>
            <div className="mt-4 flex flex-wrap items-center justify-between gap-4">
              <p className="max-w-xl text-sm leading-6 text-muted">
                {page.description}
              </p>
              <a
                className="inline-flex items-center gap-2 rounded-full border border-line px-4 py-2 text-xs text-foreground/80 hover:text-foreground"
                href={githubDocUrl(page)}
              >
                View on GitHub ↗
              </a>
            </div>
            <div className="mt-8">
              {error ? (
                <p className="text-sm text-muted">{error}</p>
              ) : markdown ? (
                <MarkdownView markdown={markdown} />
              ) : (
                <p className="text-sm text-muted">Loading guide…</p>
              )}
            </div>
          </article>
        </div>
      </main>
      <SiteFooter />
    </>
  );
}
