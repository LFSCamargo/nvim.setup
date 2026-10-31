import { vi } from 'vitest';
import { applyTheme } from '@/modules/theme/theme';

const memory = new Map<string, string>();
Object.defineProperty(window, 'localStorage', {
  configurable: true,
  value: {
    getItem(key: string) {
      return memory.get(key) ?? null;
    },
    setItem(key: string, value: string) {
      memory.set(key, String(value));
    },
    removeItem(key: string) {
      memory.delete(key);
    },
    clear() {
      memory.clear();
    },
  },
});

window.matchMedia = vi.fn().mockImplementation((query: string) => ({
  matches:
    query.includes('prefers-reduced-motion') ||
    query.includes('prefers-reduced-transparency'),
  addListener() {},
  removeListener() {},
  addEventListener() {},
  removeEventListener() {},
}));
window.IntersectionObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
} as unknown as typeof IntersectionObserver;
window.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
} as unknown as typeof ResizeObserver;
HTMLDialogElement.prototype.showModal = function showModal() {
  this.setAttribute('open', '');
};
HTMLDialogElement.prototype.close = function close() {
  this.removeAttribute('open');
};

applyTheme('dark');
