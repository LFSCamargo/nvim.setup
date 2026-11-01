import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Brand } from '@/shared/components/brand';
import { ThemeSwitch } from '@/modules/theme/components/theme-switch';
import { LiquidGlass } from '@/shared/components/liquid-glass';
import { useNavContrast } from '@/shared/hooks/use-nav-contrast';
import { repo } from '@/shared/constants/site';
import { cn } from '@/shared/utils/cn';

const links = [
  { href: '/#workspace', label: 'Workspace' },
  { href: '/#install', label: 'Install' },
  { to: '/docs', label: 'Documentation' },
  { href: '/#help', label: 'Get help' },
] as const;

function NavLinks({
  className,
  itemClassName,
  onNavigate,
}: {
  className?: string;
  itemClassName: string;
  onNavigate?: () => void;
}) {
  return (
    <div className={className}>
      {links.map((link) =>
        'to' in link ? (
          <Link
            key={link.label}
            className={itemClassName}
            to={link.to}
            onClick={onNavigate}
          >
            {link.label}
          </Link>
        ) : (
          <a
            key={link.label}
            className={itemClassName}
            href={link.href}
            onClick={onNavigate}
          >
            {link.label}
          </a>
        ),
      )}
      <a
        className={cn(
          itemClassName,
          'max-md:mt-1 max-md:border-t max-md:border-line md:border-l md:border-line md:pl-8',
        )}
        href={repo}
        onClick={onNavigate}
      >
        GitHub ↗
      </a>
    </div>
  );
}

export function Nav() {
  const [menu, setMenu] = useState(false);
  const headerRef = useRef<HTMLElement>(null);
  const onLight = useNavContrast(headerRef);
  const itemTone = onLight
    ? 'text-black hover:text-black'
    : 'text-white hover:text-white';

  useEffect(() => {
    if (!menu) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMenu(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [menu]);

  return (
    <header
      ref={headerRef}
      className="pointer-events-none fixed inset-x-0 top-0 z-30 px-3 pt-3 md:px-6 md:pt-4"
    >
      <div className="pointer-events-auto mx-auto max-w-6xl">
        <LiquidGlass
          radius={20}
          bevelDepth={12}
          scale={28}
          aberration={2}
          frost={0.8}
          tint={0.06}
          data-nav-shell
          className="border border-line nav-glass"
        >
          <nav
            className="flex h-14 items-center gap-2 px-3 md:h-16 md:gap-3 md:px-5"
            aria-label="Main navigation"
          >
            <Brand onLight={onLight} className="min-w-0 text-base md:text-lg" />
            <div className="ml-auto flex min-w-0 items-center gap-2 md:gap-3">
              <NavLinks
                className="hidden items-center gap-8 text-sm md:flex"
                itemClassName={itemTone}
              />
              <ThemeSwitch onLight={onLight} />
              <button
                type="button"
                className={cn(
                  'inline-flex size-10 shrink-0 items-center justify-center rounded-full border border-line text-lg leading-none md:hidden',
                  itemTone,
                )}
                aria-expanded={menu}
                aria-controls="nav-links"
                aria-label={menu ? 'Close menu' : 'Open menu'}
                onClick={() => setMenu((open) => !open)}
              >
                <span aria-hidden="true">{menu ? '×' : '☰'}</span>
              </button>
            </div>
          </nav>
        </LiquidGlass>
        {menu ? (
          <div
            id="nav-links"
            className={cn(
              'mt-2 rounded-[20px] border border-line bg-surface p-2 shadow-[0_18px_40px_rgb(0_0_0/0.28)] backdrop-blur-xl md:hidden',
              onLight ? 'text-black' : 'text-white',
            )}
          >
            <NavLinks
              className="flex flex-col"
              itemClassName={cn(
                itemTone,
                'rounded-xl px-4 py-3 text-base font-medium',
              )}
              onNavigate={() => setMenu(false)}
            />
          </div>
        ) : null}
      </div>
    </header>
  );
}
