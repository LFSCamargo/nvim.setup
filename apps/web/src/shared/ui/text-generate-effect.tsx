import { useEffect } from 'react';
import { motion, stagger, useAnimate, useReducedMotion } from 'motion/react';
import { useTheme } from '@/modules/theme/use-theme';
import { cn } from '@/shared/utils';

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
  const { theme } = useTheme();
  const wordsArray = words.split(' ');
  const blur = filter && !reduced && theme === 'dark';

  useEffect(() => {
    if (reduced) return;
    void animate(
      'span',
      { opacity: 1, filter: blur ? 'blur(0px)' : 'none' },
      { duration, delay: stagger(0.08) },
    );
  }, [animate, blur, duration, reduced]);

  return (
    <p className={cn('leading-relaxed text-muted', className)}>
      <motion.span ref={scope}>
        {wordsArray.map((word, index) => (
          <motion.span
            key={`${word}-${index}`}
            className="inline"
            style={{
              opacity: reduced ? 1 : 0,
              filter: blur ? 'blur(8px)' : 'none',
            }}
          >
            {word}{' '}
          </motion.span>
        ))}
      </motion.span>
    </p>
  );
}
