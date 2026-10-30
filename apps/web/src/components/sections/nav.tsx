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
  const itemTone = onLight
    ? 'text-black hover:text-black'
    : 'text-white hover:text-white';

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
        tint={0.06}
        data-nav-shell
        className="pointer-events-auto mx-auto max-w-6xl border border-line nav-glass"
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
                'absolute top-[4.75rem] right-4 left-4 flex-col gap-5 rounded-2xl border border-line bg-glass p-5 text-sm backdrop-blur-xl md:static md:flex md:flex-row md:items-center md:gap-8 md:border-0 md:bg-transparent md:p-0 md:backdrop-blur-none',
                onLight ? 'text-black' : 'text-white',
                menu ? 'flex' : 'hidden md:flex',
              )}
              onClick={() => setMenu(false)}
            >
              {links.map((link) =>
                'to' in link ? (
                  <Link key={link.label} className={itemTone} to={link.to}>
                    {link.label}
                  </Link>
                ) : (
                  <a key={link.label} className={itemTone} href={link.href}>
                    {link.label}
                  </a>
                ),
              )}
              <a
                className={cn(itemTone, 'border-line md:border-l md:pl-8')}
                href={repo}
              >
                GitHub ↗
              </a>
            </div>
            <ThemeSwitch onLight={onLight} />
            <button
              className={cn(
                'rounded-full border border-line px-3 py-1.5 text-xs md:hidden',
                itemTone,
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
