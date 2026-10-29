import { useEffect } from 'react';
import { motion, stagger, useAnimate, useReducedMotion } from 'motion/react';
import { cn } from '@/lib/utils';

type TextGenerateEffectProps = {
  words: string;
  className?: string;
  filter?: boolean;
  duration?: number;
};

export function TextGenerateEffect({
  words,
  className,
  filter = true,
  duration = 0.45,
}: TextGenerateEffectProps) {
  const [scope, animate] = useAnimate();
  const reduced = useReducedMotion();
  const wordsArray = words.split(' ');

  useEffect(() => {
    if (reduced) return;
    void animate(
      'span',
      { opacity: 1, filter: filter ? 'blur(0px)' : 'none' },
      { duration, delay: stagger(0.08) },
    );
  }, [animate, duration, filter, reduced]);

  return (
    <p className={cn('leading-relaxed text-muted', className)}>
      <motion.span ref={scope}>
        {wordsArray.map((word, index) => (
          <motion.span
            key={`${word}-${index}`}
            className="inline"
            style={{
              opacity: reduced ? 1 : 0,
              filter: reduced || !filter ? 'none' : 'blur(8px)',
            }}
          >
            {word}{' '}
          </motion.span>
        ))}
      </motion.span>
    </p>
  );
}
