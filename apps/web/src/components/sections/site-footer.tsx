import { Link } from 'react-router-dom';
import { Brand } from '@/components/brand';
import { aceternityLiquidGlass, aceternitySpotlight, repo } from '@/content';
import { useTheme } from '@/hooks/use-theme';

export function SiteFooter() {
  const { theme } = useTheme();

  return (
    <footer className="mx-auto max-w-6xl overflow-hidden border-t border-line px-6 pt-8 pb-10">
      <div className="flex flex-wrap items-center justify-between gap-5">
        <Brand className="text-base" onLight={theme === 'light'} />
        <p className="text-xs text-muted">
          A small setup. A lot of possibility.
        </p>
        <div className="flex flex-wrap gap-5 text-[11px] text-muted">
          <Link to="/docs">Docs</Link>
          <a href={repo}>Source ↗</a>
          <a href={`${repo}/blob/main/README.md`}>Readme ↗</a>
          <a href={aceternitySpotlight}>Motion: Aceternity UI ↗</a>
          <a href={aceternityLiquidGlass}>Liquid glass ↗</a>
        </div>
      </div>
      <span
        className="mt-8 block text-[clamp(3.2rem,10vw,8rem)] leading-none font-medium tracking-[-0.06em] text-wash"
        aria-hidden="true"
      >
        make something.
      </span>
    </footer>
  );
}
