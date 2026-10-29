import { useCallback, useRef, useState } from 'react';

export function useScreenshotLightbox() {
  const [index, setIndex] = useState(0);
  const [isOpen, setOpen] = useState(false);
  const closeRef = useRef<HTMLButtonElement>(null);

  const open = useCallback((nextIndex: number) => {
    setIndex(nextIndex);
    setOpen(true);
  }, []);

  const close = useCallback(() => {
    setOpen(false);
  }, []);

  return { index, isOpen, closeRef, open, close, setIndex };
}
