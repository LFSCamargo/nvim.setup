import { Link } from 'react-router-dom';
import { NeovimLogo } from '@/shared/layout/neovim-logo';
import { cn } from '@/shared/utils';

type BrandProps = {
  className?: string;
  onLight?: boolean;
};

export function Brand({ className, onLight = false }: BrandProps) {
  const tone = onLight ? 'text-black' : 'text-white';
  return (
    <Link
      to="/"
      className={cn(
        'flex items-center gap-2.5 text-lg font-semibold tracking-tight whitespace-nowrap transition-colors duration-200',
        tone,
        className,
      )}
      aria-label="nvim.setup home"
    >
      <NeovimLogo
        className={cn(
          'size-7 shrink-0 grayscale transition-colors duration-200',
          tone,
        )}
      />
      <span>
        nvim
        <span className={onLight ? 'text-black/60' : 'text-white/60'}>
          .setup
        </span>
      </span>
    </Link>
  );
}
