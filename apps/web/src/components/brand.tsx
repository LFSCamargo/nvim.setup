import { Link } from 'react-router-dom';
import { NeovimLogo } from '@/components/neovim-logo';
import { cn } from '@/lib/utils';

type BrandProps = {
  className?: string;
  onLight?: boolean;
};

export function Brand({ className, onLight = false }: BrandProps) {
  return (
    <Link
      to="/"
      className={cn(
        'flex items-center gap-2.5 text-lg font-semibold tracking-tight whitespace-nowrap transition-colors duration-200',
        onLight ? 'text-zinc-950' : 'text-zinc-100',
        className,
      )}
      aria-label="nvim.setup home"
    >
      <NeovimLogo
        className={cn(
          'size-7 shrink-0 grayscale transition-colors duration-200',
          onLight ? 'text-zinc-950' : 'text-zinc-100',
        )}
      />
      <span>
        nvim<span className="text-zinc-500">.setup</span>
      </span>
    </Link>
  );
}
