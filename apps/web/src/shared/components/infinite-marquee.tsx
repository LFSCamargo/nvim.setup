import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { cn } from '@/shared/utils/cn';
import { marqueeCopies, marqueeDurationSeconds } from '@/shared/utils/marquee';

const SPEED_PX_PER_SECOND = 40;
const SEQUENCE_CLASS =
  'flex w-max shrink-0 items-center gap-10 pr-10 whitespace-nowrap';

type InfiniteMarqueeProps = {
  children: ReactNode;
  'aria-label': string;
  className?: string;
  speed?: number;
};

export function InfiniteMarquee({
  children,
  'aria-label': ariaLabel,
  className,
  speed = SPEED_PX_PER_SECOND,
}: InfiniteMarqueeProps) {
  const viewportRef = useRef<HTMLDivElement>(null);
  const sequenceRef = useRef<HTMLDivElement>(null);
  const [copies, setCopies] = useState(4);
  const [duration, setDuration] = useState('80s');

  useLayoutEffect(() => {
    const viewport = viewportRef.current;
    const sequence = sequenceRef.current;
    if (!viewport || !sequence) {
      return undefined;
    }

    const sync = () => {
      const nextCopies = marqueeCopies(
        viewport.offsetWidth,
        sequence.offsetWidth,
      );
      setCopies(nextCopies);
      setDuration(
        `${marqueeDurationSeconds(nextCopies, sequence.offsetWidth, speed)}s`,
      );
    };

    sync();
    const observer = new ResizeObserver(sync);
    observer.observe(viewport);
    observer.observe(sequence);
    return () => observer.disconnect();
  }, [children, speed]);

  return (
    <div
      ref={viewportRef}
      data-marquee-viewport
      role="region"
      aria-label={ariaLabel}
      className={cn(
        'relative overflow-hidden [mask-image:linear-gradient(to_right,transparent,black_6%,black_94%,transparent)]',
        className,
      )}
    >
      <div
        ref={sequenceRef}
        data-marquee-sequence
        className={cn(
          SEQUENCE_CLASS,
          'pointer-events-none invisible absolute top-0 left-0',
        )}
        aria-hidden
      >
        {children}
      </div>
      <div
        data-marquee-track
        className="marquee-track flex w-max"
        style={{ animationDuration: duration }}
        aria-hidden
      >
        {[0, 1].map((half) => (
          <div key={half} data-marquee-group className="flex shrink-0">
            {Array.from({ length: copies }, (_, copy) => (
              <div key={copy} className={SEQUENCE_CLASS}>
                {children}
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
