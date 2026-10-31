import { cleanup, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { InfiniteMarquee } from '@/shared/ui/infinite-marquee';

const originalOffsetWidth = Object.getOwnPropertyDescriptor(
  HTMLElement.prototype,
  'offsetWidth',
);

afterEach(() => {
  cleanup();
  if (originalOffsetWidth) {
    Object.defineProperty(
      HTMLElement.prototype,
      'offsetWidth',
      originalOffsetWidth,
    );
  }
});

describe('InfiniteMarquee', () => {
  beforeEach(() => {
    window.ResizeObserver = class {
      private readonly callback: ResizeObserverCallback;

      constructor(callback: ResizeObserverCallback) {
        this.callback = callback;
      }

      observe() {
        this.callback([], this);
      }

      unobserve() {}

      disconnect() {}
    } as unknown as typeof ResizeObserver;

    Object.defineProperty(HTMLElement.prototype, 'offsetWidth', {
      configurable: true,
      get() {
        if (this.hasAttribute('data-marquee-viewport')) {
          return 2000;
        }
        if (this.hasAttribute('data-marquee-sequence')) {
          return 400;
        }
        return 0;
      },
    });
  });

  it('renders two equal looping halves that fill a wide viewport', () => {
    render(
      <InfiniteMarquee aria-label="A little less friction. Files, code, Git, AI.">
        <span>Files ↗</span>
        <span>Git ↗</span>
      </InfiniteMarquee>,
    );

    const viewport = document.querySelector('[data-marquee-viewport]');
    const groups = document.querySelectorAll('[data-marquee-group]');
    const track = document.querySelector('[data-marquee-track]');

    expect(screen.getByRole('region', { name: /less friction/ })).toBeTruthy();
    expect(groups).toHaveLength(2);
    expect(groups[0]?.children).toHaveLength(6);
    expect(groups[1]?.children).toHaveLength(6);
    expect(groups[0]?.childElementCount).toBe(groups[1]?.childElementCount);
    expect(track?.getAttribute('aria-hidden')).toBe('true');
    expect((track as HTMLElement | null)?.style.animationDuration).toBe('60s');
    expect(viewport?.querySelectorAll('[data-marquee-group] span').length).toBe(
      24,
    );
  });
});
