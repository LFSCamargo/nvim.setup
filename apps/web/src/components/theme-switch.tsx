import { useTheme } from '@/hooks/use-theme';
import type { Theme } from '@/lib/theme';
import { cn } from '@/lib/utils';

const modes: { id: Theme; label: string }[] = [
  { id: 'light', label: 'Light' },
  { id: 'dark', label: 'Dark' },
];

type ThemeSwitchProps = {
  onLight?: boolean;
};

export function ThemeSwitch({ onLight = false }: ThemeSwitchProps) {
  const { theme, setTheme } = useTheme();

  return (
    <div
      role="group"
      aria-label="Color theme"
      className={cn(
        'flex rounded-full border p-0.5',
        onLight ? 'border-zinc-900/15' : 'border-white/15',
      )}
    >
      {modes.map((mode) => {
        const active = theme === mode.id;
        return (
          <button
            key={mode.id}
            type="button"
            aria-pressed={active}
            onClick={() => setTheme(mode.id)}
            className={cn(
              'rounded-full px-2.5 py-1 text-[10px] tracking-[0.12em]',
              active
                ? onLight
                  ? 'bg-zinc-900 text-zinc-50'
                  : 'bg-white/15 text-zinc-100'
                : onLight
                  ? 'text-zinc-600 hover:text-zinc-950'
                  : 'text-zinc-400 hover:text-white',
            )}
          >
            {mode.label}
          </button>
        );
      })}
    </div>
  );
}
