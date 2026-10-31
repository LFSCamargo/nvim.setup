export const THEME_KEY = 'nvim.setup.theme';
export const THEME_DARK = '#0b0b0c';
export const THEME_LIGHT = '#f3f2ee';

export type Theme = 'light' | 'dark';

export function isTheme(value: string | null | undefined): value is Theme {
  return value === 'light' || value === 'dark';
}

export function preferredTheme(): Theme {
  if (typeof window === 'undefined' || !window.matchMedia) {
    return 'dark';
  }
  return window.matchMedia('(prefers-color-scheme: light)').matches
    ? 'light'
    : 'dark';
}

export function readStoredTheme(): Theme | null {
  try {
    const stored = window.localStorage?.getItem(THEME_KEY) ?? null;
    return isTheme(stored) ? stored : null;
  } catch {
    return null;
  }
}

export function readTheme(): Theme {
  return readStoredTheme() ?? preferredTheme();
}

export function persistTheme(theme: Theme) {
  try {
    window.localStorage?.setItem(THEME_KEY, theme);
  } catch {
    // Private mode can block storage; the in-memory theme still applies.
  }
}

export function applyTheme(theme: Theme) {
  const root = document.documentElement;
  root.classList.toggle('dark', theme === 'dark');
  root.dataset.theme = theme;
  root.style.colorScheme = theme;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute('content', theme === 'dark' ? THEME_DARK : THEME_LIGHT);
  }
}
