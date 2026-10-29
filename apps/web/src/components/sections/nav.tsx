import { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Brand } from '@/components/brand';
import { ThemeSwitch } from '@/components/theme-switch';
import { LiquidGlass } from '@/components/ui/liquid-glass';
import { useNavContrast } from '@/hooks/use-nav-contrast';
import { repo } from '@/content';
import { cn } from '@/lib/utils';

const links = [
  { href: '/#workspace', label: 'Workspace' },
  { href: '/#install', label: 'Install' },
  { to: '/docs', label: 'Documentation' },
  { href: '/#help', label: 'Get help' },
] as const;

export function Nav() {
  const [menu, setMenu] = useState(false);
  const headerRef = useRef<HTMLElement>(null);
  const onLight = useNavContrast(headerRef);
  const linkTone = onLight ? 'hover:text-zinc-950' : 'hover:text-white';

  return (
    <header
      ref={headerRef}
      className="pointer-events-none fixed inset-x-0 top-0 z-30 px-4 pt-4 md:px-6"
    >
      <LiquidGlass
        radius={22}
        bevelDepth={12}
        scale={28}
        aberration={2}
        frost={0.8}
        tint={onLight ? 0.14 : 0.08}
        data-rim={onLight ? 'light' : 'dark'}
        className={cn(
          'pointer-events-auto mx-auto max-w-6xl border glass-rim backdrop-blur-xl transition-[border-color,box-shadow] duration-200',
          onLight ? 'border-zinc-900/12' : 'border-white/12',
        )}
      >
        <nav
          className="flex h-16 items-center gap-3 px-5"
          aria-label="Main navigation"
        >
          <Brand onLight={onLight} />
          <div className="ml-auto flex items-center gap-3">
            <div
              id="nav-links"
              className={cn(
                'absolute top-[4.75rem] right-4 left-4 flex-col gap-5 rounded-2xl border p-5 text-sm md:static md:flex md:flex-row md:items-center md:gap-8 md:border-0 md:bg-transparent md:p-0',
                onLight
                  ? 'border-zinc-900/10 bg-zinc-50/95 text-zinc-600'
                  : 'border-white/10 bg-zinc-950/95 text-zinc-400',
                menu ? 'flex' : 'hidden md:flex',
              )}
              onClick={() => setMenu(false)}
            >
              {links.map((link) =>
                'to' in link ? (
                  <Link key={link.label} className={linkTone} to={link.to}>
                    {link.label}
                  </Link>
                ) : (
                  <a key={link.label} className={linkTone} href={link.href}>
                    {link.label}
                  </a>
                ),
              )}
              <a
                className={cn(
                  linkTone,
                  onLight ? 'border-zinc-900/15' : 'border-white/15',
                  'md:border-l md:pl-8',
                )}
                href={repo}
              >
                GitHub ↗
              </a>
            </div>
            <ThemeSwitch onLight={onLight} />
            <button
              className={cn(
                'rounded-full border px-3 py-1.5 text-xs md:hidden',
                onLight ? 'border-zinc-900/15' : 'border-white/15',
              )}
              aria-expanded={menu}
              aria-controls="nav-links"
              onClick={() => setMenu((open) => !open)}
            >
              {menu ? 'Close −' : 'Menu +'}
            </button>
          </div>
        </nav>
      </LiquidGlass>
    </header>
  );
}
