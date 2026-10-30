import {
  memo,
  useCallback,
  useEffect,
  useRef,
  type CSSProperties,
} from 'react';
import { animate, useReducedMotion } from 'motion/react';
import { useTheme } from '@/hooks/use-theme';
import { cn } from '@/lib/utils';

type GlowingEffectProps = {
  blur?: number;
  inactiveZone?: number;
  proximity?: number;
  spread?: number;
  variant?: 'default' | 'white';
  glow?: boolean;
  className?: string;
  disabled?: boolean;
  movementDuration?: number;
  borderWidth?: number;
};

export const GlowingEffect = memo(function GlowingEffect({
  blur = 0,
  inactiveZone = 0.7,
  proximity = 64,
  spread = 24,
  variant = 'white',
  glow = false,
  className,
  movementDuration = 2,
  borderWidth = 1,
  disabled,
}: GlowingEffectProps) {
  const reduced = useReducedMotion();
  const { theme } = useTheme();
  const isDisabled = disabled ?? reduced ?? false;
  const containerRef = useRef<HTMLDivElement>(null);
  const lastPosition = useRef({ x: 0, y: 0 });
  const animationFrameRef = useRef(0);

  const handleMove = useCallback(
    (event?: MouseEvent | { x: number; y: number }) => {
      if (!containerRef.current) return;
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }

      animationFrameRef.current = requestAnimationFrame(() => {
        const element = containerRef.current;
        if (!element) return;

        const { left, top, width, height } = element.getBoundingClientRect();
        const mouseX = event?.x ?? lastPosition.current.x;
        const mouseY = event?.y ?? lastPosition.current.y;
        if (event) lastPosition.current = { x: mouseX, y: mouseY };

        const center = [left + width * 0.5, top + height * 0.5];
        const distanceFromCenter = Math.hypot(
          mouseX - center[0],
          mouseY - center[1],
        );
        const inactiveRadius = 0.5 * Math.min(width, height) * inactiveZone;
        if (distanceFromCenter < inactiveRadius) {
          element.style.setProperty('--active', '0');
          return;
        }

        const isActive =
          mouseX > left - proximity &&
          mouseX < left + width + proximity &&
          mouseY > top - proximity &&
          mouseY < top + height + proximity;
        element.style.setProperty('--active', isActive ? '1' : '0');
        if (!isActive) return;

        const currentAngle =
          parseFloat(element.style.getPropertyValue('--start')) || 0;
        const targetAngle =
          (180 * Math.atan2(mouseY - center[1], mouseX - center[0])) / Math.PI +
          90;
        const angleDiff = ((targetAngle - currentAngle + 180) % 360) - 180;
        const newAngle = currentAngle + angleDiff;

        animate(currentAngle, newAngle, {
          duration: movementDuration,
          ease: [0.16, 1, 0.3, 1],
          onUpdate: (value) => {
            element.style.setProperty('--start', String(value));
          },
        });
      });
    },
    [inactiveZone, proximity, movementDuration],
  );

  useEffect(() => {
    if (isDisabled) return undefined;
    const handleScroll = () => handleMove();
    const handlePointerMove = (event: PointerEvent) => handleMove(event);
    window.addEventListener('scroll', handleScroll, { passive: true });
    document.body.addEventListener('pointermove', handlePointerMove, {
      passive: true,
    });
    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
      window.removeEventListener('scroll', handleScroll);
      document.body.removeEventListener('pointermove', handlePointerMove);
    };
  }, [handleMove, isDisabled]);

  const gradient =
    variant === 'white'
      ? theme === 'light'
        ? `repeating-conic-gradient(from 236.84deg at 50% 50%, #18181b, #a1a1aa calc(25% / 5), #18181b calc(100% / 5))`
        : `repeating-conic-gradient(from 236.84deg at 50% 50%, #fff, #a3a3a3 calc(25% / 5), #fff calc(100% / 5))`
      : `radial-gradient(circle, #dd7bbb 10%, #dd7bbb00 20%), repeating-conic-gradient(from 236.84deg at 50% 50%, #dd7bbb 0%, #d79f1e 25%, #5a922c 50%, #4c7894 75%, #dd7bbb 100%)`;

  return (
    <>
      <div
        className={cn(
          'pointer-events-none absolute -inset-px hidden rounded-[inherit] border opacity-0',
          theme === 'light' ? 'border-zinc-900/15' : 'border-white/20',
          glow && 'opacity-100',
          isDisabled && 'block',
        )}
      />
      <div
        ref={containerRef}
        style={
          {
            '--blur': `${blur}px`,
            '--spread': spread,
            '--start': '0',
            '--active': glow ? '1' : '0',
            '--glowingeffect-border-width': `${borderWidth}px`,
            '--gradient': gradient,
          } as CSSProperties
        }
        className={cn(
          'glowing-effect',
          blur > 0 && 'blur-[var(--blur)]',
          isDisabled && 'hidden',
          className,
        )}
      >
        <div className="glowing-effect__beam" />
      </div>
    </>
  );
});
