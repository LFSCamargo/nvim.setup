import { afterEach, describe, expect, it } from 'vitest';
import {
  THEME_KEY,
  applyTheme,
  isTheme,
  preferredTheme,
  readStoredTheme,
  readTheme,
} from '@/modules/theme/theme';

afterEach(() => {
  window.localStorage.removeItem(THEME_KEY);
  applyTheme('dark');
});

describe('theme', () => {
  it('accepts only light and dark values', () => {
    expect(isTheme('light')).toBe(true);
    expect(isTheme('dark')).toBe(true);
    expect(isTheme('system')).toBe(false);
  });

  it('defaults to dark unless the visitor prefers light', () => {
    expect(preferredTheme()).toBe('dark');
    expect(readTheme()).toBe('dark');
  });

  it('applies the theme class, data attribute, and color scheme', () => {
    applyTheme('light');
    expect(document.documentElement.classList.contains('dark')).toBe(false);
    expect(document.documentElement.dataset.theme).toBe('light');
    expect(document.documentElement.style.colorScheme).toBe('light');
    applyTheme('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('reads a stored preference', () => {
    window.localStorage.setItem(THEME_KEY, 'light');
    expect(readStoredTheme()).toBe('light');
    expect(readTheme()).toBe('light');
  });
});
