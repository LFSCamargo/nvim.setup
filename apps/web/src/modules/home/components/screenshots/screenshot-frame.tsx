import type { ReactNode } from 'react';
import { LiquidGlass } from '@/shared/components/liquid-glass';
import { cn } from '@/shared/utils/cn';

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
  const frame = (
    <LiquidGlass
      radius={18}
      bevelDepth={16}
      scale={36}
      aberration={3}
      frost={0.6}
      tint={0.06}
      data-rim="dark"
      className={cn(
        'max-w-full border border-white/12 glass-rim dark:border-white/12',
        tilt && 'hero-tilt origin-bottom [transform:rotateX(4deg)]',
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

  if (!tilt) return frame;

  return <div className="overflow-x-clip [perspective:1600px]">{frame}</div>;
}
