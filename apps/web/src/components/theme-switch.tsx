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
      className="flex rounded-full border border-line p-0.5"
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
                  ? 'bg-black text-white'
                  : 'bg-white text-black'
                : onLight
                  ? 'text-black hover:text-black'
                  : 'text-white hover:text-white',
            )}
          >
            {mode.label}
          </button>
        );
      })}
    </div>
  );
}
