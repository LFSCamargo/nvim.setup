import { useCallback, useEffect, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { cn } from '@/shared/utils';

type FlipWordsProps = {
  words: readonly string[] | string[];
  duration?: number;
  className?: string;
};

export function FlipWords({
  words,
  duration = 3000,
  className,
}: FlipWordsProps) {
  const reduced = useReducedMotion();
  const [currentWord, setCurrentWord] = useState(words[0] ?? '');
  const [isAnimating, setIsAnimating] = useState(false);

  const startAnimation = useCallback(() => {
    setCurrentWord((current) => {
      const index = words.findIndex((word) => word === current);
      return words[index + 1] ?? words[0] ?? '';
    });
    setIsAnimating(true);
  }, [words]);

  useEffect(() => {
    if (reduced || isAnimating) return undefined;
    const timer = window.setTimeout(startAnimation, duration);
    return () => window.clearTimeout(timer);
  }, [duration, isAnimating, reduced, startAnimation]);

  if (reduced) {
    return <span className={cn('inline-block', className)}>{words[0]}</span>;
  }

  return (
    <AnimatePresence onExitComplete={() => setIsAnimating(false)}>
      <motion.span
        key={currentWord}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{
          opacity: 0,
          y: -40,
          x: 40,
          filter: 'blur(8px)',
          scale: 2,
          position: 'absolute',
        }}
        transition={{ type: 'spring', stiffness: 100, damping: 10 }}
        className={cn('relative z-10 inline-block text-left', className)}
      >
        {currentWord.split('').map((letter, index) => (
          <motion.span
            key={`${currentWord}-${index}`}
            initial={{ opacity: 0, y: 10, filter: 'blur(8px)' }}
            animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
            transition={{ delay: index * 0.05, duration: 0.2 }}
            className="inline-block"
          >
            {letter === ' ' ? '\u00a0' : letter}
          </motion.span>
        ))}
      </motion.span>
    </AnimatePresence>
  );
}
