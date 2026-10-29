import { motion, useReducedMotion } from 'motion/react';
import { useTheme } from '@/hooks/use-theme';

type SpotlightProps = {
  gradientFirst?: string;
  gradientSecond?: string;
  gradientThird?: string;
  translateY?: number;
  width?: number;
  height?: number;
  smallWidth?: number;
  duration?: number;
  xOffset?: number;
};

const darkFirst =
  'radial-gradient(68.54% 68.72% at 55.02% 31.46%, hsla(0, 0%, 100%, .09) 0, hsla(0, 0%, 80%, .03) 50%, hsla(0, 0%, 60%, 0) 80%)';
const darkSecond =
  'radial-gradient(50% 50% at 50% 50%, hsla(0, 0%, 100%, .07) 0, hsla(0, 0%, 80%, .02) 80%, transparent 100%)';
const darkThird =
  'radial-gradient(50% 50% at 50% 50%, hsla(0, 0%, 100%, .05) 0, hsla(0, 0%, 70%, .02) 80%, transparent 100%)';
const lightFirst =
  'radial-gradient(68.54% 68.72% at 55.02% 31.46%, hsla(0, 0%, 0%, .08) 0, hsla(0, 0%, 20%, .03) 50%, hsla(0, 0%, 40%, 0) 80%)';
const lightSecond =
  'radial-gradient(50% 50% at 50% 50%, hsla(0, 0%, 0%, .06) 0, hsla(0, 0%, 20%, .02) 80%, transparent 100%)';
const lightThird =
  'radial-gradient(50% 50% at 50% 50%, hsla(0, 0%, 0%, .04) 0, hsla(0, 0%, 30%, .02) 80%, transparent 100%)';

export function Spotlight({
  gradientFirst,
  gradientSecond,
  gradientThird,
  translateY = -350,
  width = 560,
  height = 1380,
  smallWidth = 240,
  duration = 7,
  xOffset = 100,
}: SpotlightProps = {}) {
  const reduced = useReducedMotion();
  const { theme } = useTheme();
  const first = gradientFirst ?? (theme === 'light' ? lightFirst : darkFirst);
  const second =
    gradientSecond ?? (theme === 'light' ? lightSecond : darkSecond);
  const third = gradientThird ?? (theme === 'light' ? lightThird : darkThird);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: reduced ? 0 : 1.5 }}
      className="pointer-events-none absolute inset-0 overflow-hidden"
      aria-hidden="true"
    >
      {[-1, 1].map((side) => (
        <motion.div
          key={side}
          animate={reduced ? undefined : { x: [0, side * xOffset, 0] }}
          transition={{
            duration,
            repeat: Infinity,
            repeatType: 'reverse',
            ease: 'easeInOut',
          }}
          className={`pointer-events-none absolute top-0 h-full w-full ${
            side === -1 ? 'left-0' : 'right-0'
          }`}
        >
          <div
            className={`absolute top-0 ${side === -1 ? 'left-0' : 'right-0'}`}
            style={{
              transform: `translateY(${translateY}px) rotate(${side * 45}deg)`,
              background: first,
              width,
              height,
            }}
          />
          <div
            className={`absolute top-0 origin-top ${
              side === -1
                ? 'left-0 origin-top-left'
                : 'right-0 origin-top-right'
            }`}
            style={{
              transform:
                side === -1
                  ? 'rotate(-45deg) translate(5%, -50%)'
                  : 'rotate(45deg) translate(-5%, -50%)',
              background: second,
              width: smallWidth,
              height,
            }}
          />
          <div
            className={`absolute top-0 ${
              side === -1
                ? 'left-0 origin-top-left'
                : 'right-0 origin-top-right'
            }`}
            style={{
              transform:
                side === -1
                  ? 'rotate(-45deg) translate(-180%, -70%)'
                  : 'rotate(45deg) translate(180%, -70%)',
              background: third,
              width: smallWidth,
              height,
            }}
          />
        </motion.div>
      ))}
    </motion.div>
  );
}
