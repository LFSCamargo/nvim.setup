import type { ReactNode } from 'react';
import { LiquidGlass } from '@/components/ui/liquid-glass';
import { cn } from '@/lib/utils';

type ScreenshotFrameProps = {
  children: ReactNode;
  className?: string;
  label?: string;
  tilt?: boolean;
};

export function ScreenshotFrame({
  children,
  className,
  label = '~/your-next-idea',
  tilt = false,
}: ScreenshotFrameProps) {
  return (
    <LiquidGlass
      radius={18}
      bevelDepth={16}
      scale={36}
      aberration={3}
      frost={0.6}
      tint={0.06}
      className={cn(
        'max-w-full border border-white/12 glass-rim dark:border-white/12',
        tilt &&
          'hero-tilt origin-bottom [transform:perspective(1600px)_rotateX(4deg)]',
        className,
      )}
      contentClassName="relative bg-zinc-950"
    >
      <div className="flex h-10 items-center justify-between border-b border-white/10 bg-white/5 px-4 font-mono text-[10px] tracking-wide text-zinc-400">
        <span className="flex gap-1.5" aria-hidden="true">
          <i className="size-1.5 rounded-full border border-zinc-500" />
          <i className="size-1.5 rounded-full border border-zinc-500" />
          <i className="size-1.5 rounded-full border border-zinc-500" />
        </span>
        <span>{label}</span>
        <span className="tracking-[0.2em]">NVIM</span>
      </div>
      {children}
    </LiquidGlass>
  );
}
