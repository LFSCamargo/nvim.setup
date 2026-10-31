import { useEffect, useState, type RefObject } from 'react';
import { isHeaderOverLightBackdrop } from '@/shared/utils/contrast';
import { useTheme } from '@/modules/theme/hooks/use-theme';

export function useNavContrast(headerRef: RefObject<HTMLElement | null>) {
  const { theme } = useTheme();
  const [onLight, setOnLight] = useState(theme === 'light');

  useEffect(() => {
    const header = headerRef.current;
    if (!header) return;
    setOnLight(theme === 'light');
    let frame = 0;

    function measure() {
      if (!headerRef.current) return;
      setOnLight(isHeaderOverLightBackdrop(headerRef.current));
    }

    function schedule() {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(measure);
    }

    measure();
    window.addEventListener('scroll', schedule, { passive: true });
    window.addEventListener('resize', schedule);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener('scroll', schedule);
      window.removeEventListener('resize', schedule);
    };
  }, [headerRef, theme]);

  return onLight;
}
