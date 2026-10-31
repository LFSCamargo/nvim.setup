import {
  useEffect,
  useState,
  type ComponentPropsWithoutRef,
  type ElementType,
  type ReactNode,
} from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { useTheme } from '@/modules/theme/use-theme';
import { cn } from '@/shared/utils';

type Direction = 'TOP' | 'LEFT' | 'BOTTOM' | 'RIGHT';

type HoverBorderGradientProps<T extends ElementType> = {
  as?: T;
  containerClassName?: string;
  className?: string;
  duration?: number;
  clockwise?: boolean;
  children: ReactNode;
} & Omit<ComponentPropsWithoutRef<T>, 'as' | 'children' | 'className'>;

const darkMovingMap: Record<Direction, string> = {
  TOP: 'radial-gradient(20.7% 50% at 50% 0%, hsl(0, 0%, 100%) 0%, rgba(255, 255, 255, 0) 100%)',
  LEFT: 'radial-gradient(16.6% 43.1% at 0% 50%, hsl(0, 0%, 100%) 0%, rgba(255, 255, 255, 0) 100%)',
  BOTTOM:
    'radial-gradient(20.7% 50% at 50% 100%, hsl(0, 0%, 100%) 0%, rgba(255, 255, 255, 0) 100%)',
  RIGHT:
    'radial-gradient(16.2% 41.2% at 100% 50%, hsl(0, 0%, 100%) 0%, rgba(255, 255, 255, 0) 100%)',
};

const lightMovingMap: Record<Direction, string> = {
  TOP: 'radial-gradient(20.7% 50% at 50% 0%, hsl(0, 0%, 12%) 0%, rgba(20, 20, 22, 0) 100%)',
  LEFT: 'radial-gradient(16.6% 43.1% at 0% 50%, hsl(0, 0%, 12%) 0%, rgba(20, 20, 22, 0) 100%)',
  BOTTOM:
    'radial-gradient(20.7% 50% at 50% 100%, hsl(0, 0%, 12%) 0%, rgba(20, 20, 22, 0) 100%)',
  RIGHT:
    'radial-gradient(16.2% 41.2% at 100% 50%, hsl(0, 0%, 12%) 0%, rgba(20, 20, 22, 0) 100%)',
};

const darkHighlight =
  'radial-gradient(75% 181% at 50% 50%, hsl(0, 0%, 100%) 0%, rgba(255, 255, 255, 0) 100%)';
const lightHighlight =
  'radial-gradient(75% 181% at 50% 50%, hsl(0, 0%, 20%) 0%, rgba(20, 20, 22, 0) 100%)';

export function HoverBorderGradient<T extends ElementType = 'button'>({
  children,
  containerClassName,
  className,
  as,
  duration = 1,
  clockwise = true,
  ...props
}: HoverBorderGradientProps<T>) {
  const Tag = as ?? 'button';
  const reduced = useReducedMotion();
  const { theme } = useTheme();
  const movingMap = theme === 'light' ? lightMovingMap : darkMovingMap;
  const highlight = theme === 'light' ? lightHighlight : darkHighlight;
  const [hovered, setHovered] = useState(false);
  const [direction, setDirection] = useState<Direction>('TOP');

  useEffect(() => {
    if (hovered || reduced) return undefined;
    const interval = window.setInterval(() => {
      setDirection((current) => {
        const directions: Direction[] = ['TOP', 'LEFT', 'BOTTOM', 'RIGHT'];
        const currentIndex = directions.indexOf(current);
        const nextIndex = clockwise
          ? (currentIndex - 1 + directions.length) % directions.length
          : (currentIndex + 1) % directions.length;
        return directions[nextIndex] ?? 'TOP';
      });
    }, duration * 1000);
    return () => window.clearInterval(interval);
  }, [hovered, clockwise, duration, reduced]);

  return (
    <Tag
      {...props}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      className={cn(
        'relative inline-flex w-fit content-center items-center justify-center overflow-visible rounded-full border p-px transition duration-500',
        theme === 'light' ? 'border-zinc-900/20' : 'border-white/15',
        containerClassName,
      )}
    >
      <span
        className={cn(
          'relative z-10 inline-flex items-center gap-3 rounded-[inherit] bg-zinc-950 px-5 py-2.5 text-sm font-medium text-zinc-50',
          className,
        )}
      >
        {children}
      </span>
      <motion.span
        aria-hidden="true"
        className="hover-border-gradient__halo"
        initial={{ background: movingMap[direction] }}
        animate={{
          background: hovered
            ? [movingMap[direction], highlight]
            : movingMap[direction],
        }}
        transition={{ ease: 'linear', duration: reduced ? 0 : duration }}
      />
      <span
        aria-hidden="true"
        className="absolute inset-px z-0 rounded-[inherit] bg-zinc-950"
      />
    </Tag>
  );
}
