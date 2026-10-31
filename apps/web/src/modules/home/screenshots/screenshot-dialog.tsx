import { useEffect, type RefObject } from 'react';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { screens } from '@/modules/home/content';

type ScreenshotDialogProps = {
  index: number;
  open: boolean;
  closeRef: RefObject<HTMLButtonElement | null>;
  onClose: () => void;
  onIndexChange: (index: number) => void;
};

export function ScreenshotDialog({
  index,
  open,
  closeRef,
  onClose,
  onIndexChange,
}: ScreenshotDialogProps) {
  const reduced = useReducedMotion();
  const screen = screens[index] ?? screens[0];
  const duration = reduced ? 0 : 0.32;

  useEffect(() => {
    if (!open) {
      return undefined;
    }
    const previous = document.activeElement as HTMLElement | null;
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    document.documentElement.dataset.lightbox = 'open';
    const frame = window.requestAnimationFrame(() => {
      closeRef.current?.focus();
    });
    return () => {
      window.cancelAnimationFrame(frame);
      document.body.style.overflow = originalOverflow;
      delete document.documentElement.dataset.lightbox;
      previous?.focus();
    };
  }, [closeRef, open]);

  useEffect(() => {
    if (!open) {
      return undefined;
    }

    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        event.preventDefault();
        onClose();
        return;
      }
      if (event.key === 'ArrowRight') {
        event.preventDefault();
        onIndexChange((index + 1) % screens.length);
      }
      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        onIndexChange((index - 1 + screens.length) % screens.length);
      }
    }

    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [index, onClose, onIndexChange, open]);

  if (typeof document === 'undefined') {
    return null;
  }

  return createPortal(
    <AnimatePresence>
      {open ? (
        <motion.div
          className="flex items-center justify-center p-5 md:p-8"
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 1000,
            backgroundColor: 'rgba(0, 0, 0, 0.82)',
          }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration }}
        >
          <button
            type="button"
            aria-label="Dismiss screenshot"
            className="absolute inset-0"
            onClick={onClose}
          />
          <motion.div
            role="dialog"
            aria-modal="true"
            aria-labelledby="screenshot-dialog-title"
            className="relative flex flex-col overflow-hidden rounded-2xl border border-white/12 bg-zinc-950 text-zinc-100 shadow-[0_24px_80px_rgb(0_0_0/0.45)]"
            style={{
              width: 'min(64rem, calc(100vw - 2.5rem))',
              height: 'min(46rem, calc(100vh - 5rem))',
            }}
            initial={reduced ? false : { opacity: 0, y: 18, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduced ? undefined : { opacity: 0, y: 12, scale: 0.98 }}
            transition={{ duration, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="flex items-center justify-between gap-4 border-b border-white/10 px-5 py-3">
              <div className="min-w-0">
                <p
                  id="screenshot-dialog-title"
                  className="truncate text-sm font-medium tracking-tight"
                >
                  {screen.label}
                </p>
                <p className="font-mono text-[10px] tracking-[0.14em] text-zinc-500">
                  {String(index + 1).padStart(2, '0')} / {screens.length}
                </p>
              </div>
              <button
                ref={closeRef}
                type="button"
                className="rounded-full border border-white/15 px-3 py-1.5 text-xs text-zinc-300 hover:text-white"
                onClick={onClose}
                aria-label="Close screenshot"
              >
                Close ×
              </button>
            </div>
            <div className="flex min-h-0 flex-1 items-center justify-center overflow-hidden bg-black px-4 py-4">
              <img
                src={screen.src}
                alt={screen.alt}
                width={screen.width}
                height={screen.height}
                className="max-h-full max-w-full object-contain"
              />
            </div>
            <div className="flex items-center justify-between gap-4 border-t border-white/10 px-5 py-3">
              <p className="min-w-0 text-sm leading-6 text-zinc-400">
                {screen.caption}
              </p>
              <div className="flex shrink-0 items-center gap-2">
                <button
                  type="button"
                  className="rounded-full border border-white/15 px-3 py-1.5 text-xs text-zinc-300 hover:text-white"
                  onClick={() =>
                    onIndexChange((index - 1 + screens.length) % screens.length)
                  }
                  aria-label="Previous screenshot"
                >
                  ← Prev
                </button>
                <button
                  type="button"
                  className="rounded-full border border-white/15 px-3 py-1.5 text-xs text-zinc-300 hover:text-white"
                  onClick={() => onIndexChange((index + 1) % screens.length)}
                  aria-label="Next screenshot"
                >
                  Next →
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
