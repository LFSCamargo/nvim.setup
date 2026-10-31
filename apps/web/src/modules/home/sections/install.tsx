import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { docs } from '@/shared/site';
import {
  commands,
  installSteps,
  requirements,
  type InstallMode,
} from '@/modules/home/install/content';
import { CodeBlock } from '@/shared/ui/code-block';
import { LiquidGlass } from '@/shared/ui/liquid-glass';
import { Reveal } from '@/shared/ui/reveal';
import { useTheme } from '@/modules/theme/use-theme';
import { cn } from '@/shared/utils';

export function Install() {
  const { theme } = useTheme();
  const inverted = theme === 'dark';
  const [mode, setMode] = useState<InstallMode>('standard');
  const [copy, setCopy] = useState('Copy commands');

  useEffect(() => {
    const timer = window.setTimeout(() => setCopy('Copy commands'), 2500);
    return () => window.clearTimeout(timer);
  }, [copy]);

  async function copyCommands() {
    try {
      await navigator.clipboard.writeText(commands[mode]);
      setCopy('Copied ✓');
    } catch {
      setCopy('Select and copy below');
    }
  }

  return (
    <section
      id="install"
      className={cn(
        'py-20 md:py-24',
        inverted ? 'bg-zinc-100 text-zinc-900' : 'bg-zinc-950 text-zinc-50',
      )}
    >
      <div className="mx-auto grid max-w-6xl min-w-0 gap-12 px-6 lg:grid-cols-2 lg:gap-16">
        <Reveal>
          <p
            className={cn(
              'font-mono text-[10px] tracking-[0.16em]',
              inverted ? 'text-zinc-500' : 'text-zinc-400',
            )}
          >
            02 / FROM HERE TO YOUR TERMINAL
          </p>
          <h2 className="mt-5 text-[clamp(2.4rem,4vw,3.6rem)] leading-tight font-medium tracking-[-0.04em]">
            Less setup.
            <br />
            <span className="font-serif italic">More starting.</span>
          </h2>
          <p
            className={cn(
              'mt-6 max-w-md text-sm leading-7',
              inverted ? 'text-zinc-500' : 'text-zinc-400',
            )}
          >
            One command. A complete workspace. The installer fetches this setup
            and installs Neovim if you do not have it. Choose a fresh install,
            or try it alongside your current configuration.
          </p>
          <ol className="mt-10 flex flex-col gap-7">
            {installSteps.map((step) => (
              <li key={step.number} className="flex gap-4">
                <span
                  className={cn(
                    'grid size-8 shrink-0 place-items-center rounded-full border font-mono text-[10px]',
                    inverted ? 'border-zinc-300' : 'border-zinc-700',
                  )}
                >
                  {step.number}
                </span>
                <div>
                  <h3 className="text-sm font-semibold">{step.title}</h3>
                  <p
                    className={cn(
                      'mt-2 max-w-sm text-sm leading-6',
                      inverted ? 'text-zinc-500' : 'text-zinc-400',
                    )}
                  >
                    {step.description}
                    {step.number === '03' ? (
                      <>
                        {' '}
                        Start with the{' '}
                        <a
                          className={cn(
                            'underline underline-offset-4',
                            inverted ? 'text-zinc-900' : 'text-zinc-50',
                          )}
                          href={`${docs}/EDITOR.md`}
                        >
                          editor guide ↗
                        </a>
                        .
                      </>
                    ) : null}
                  </p>
                </div>
              </li>
            ))}
          </ol>
        </Reveal>
        <Reveal className="min-w-0">
          <LiquidGlass
            radius={20}
            bevelDepth={14}
            scale={30}
            frost={0.5}
            tint={0.04}
            data-rim="dark"
            className="max-w-full border border-zinc-800 text-zinc-100 glass-rim"
            contentClassName="relative bg-zinc-950"
          >
            <div className="flex h-12 items-center justify-between border-b border-white/10 px-5 font-mono text-[10px] tracking-[0.12em] text-zinc-400">
              <span>YOUR TERMINAL</span>
              <span aria-hidden="true">↗</span>
            </div>
            <div
              className="flex gap-5 px-5 pt-4"
              aria-label="Installation method"
            >
              {(
                [
                  ['standard', 'Standard install'],
                  ['preview', 'Try alongside'],
                ] as const
              ).map(([value, label]) => (
                <button
                  key={value}
                  aria-pressed={mode === value}
                  onClick={() => setMode(value)}
                  className={cn(
                    'border-b pb-2 text-xs text-zinc-500',
                    mode === value
                      ? 'border-zinc-100 text-white'
                      : 'border-transparent',
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
            <CodeBlock
              code={commands[mode]}
              language="sh"
              showHeader={false}
              framed={false}
              label={`${mode === 'preview' ? 'Preview' : 'Standard'} installation commands`}
              className="min-h-40"
            />
            <button
              className="flex w-full items-center justify-between border-t border-white/10 bg-white/5 px-5 py-4 text-xs text-zinc-300 hover:bg-white/10 hover:text-white"
              onClick={() => void copyCommands()}
            >
              <span aria-live="polite">{copy}</span>
              <span aria-hidden="true">⧉</span>
            </button>
          </LiquidGlass>
          <p
            className={cn(
              'mt-6 border-l-2 pl-4 text-sm leading-7',
              inverted
                ? 'border-zinc-400 text-zinc-500'
                : 'border-zinc-600 text-zinc-400',
            )}
          >
            {mode === 'standard'
              ? 'This replaces your Neovim configuration after backing it up. Close Neovim first. Do not pipe the installer to sudo.'
              : 'Preview uses separate config, data, and state directories. Your existing Neovim setup stays in place.'}
          </p>
          <p
            className={cn(
              'mt-4 text-sm leading-7',
              inverted ? 'text-zinc-500' : 'text-zinc-400',
            )}
          >
            Requires internet access. Missing Neovim, Node, Git, or Homebrew are
            installed for you. Linux may ask for sudo for system packages.
          </p>
          <Link
            className={cn(
              'mt-5 inline-flex items-center gap-2 text-sm font-semibold',
              inverted ? 'text-zinc-900' : 'text-zinc-50',
            )}
            to="/docs/getting-started"
          >
            Full requirements in the getting started guide ↗
          </Link>
        </Reveal>
      </div>
      <Reveal className="mx-auto mt-16 max-w-6xl px-6">
        <div className="mb-6 flex flex-col justify-between gap-3 md:flex-row md:items-end">
          <div>
            <p
              className={cn(
                'font-mono text-[10px] tracking-[0.16em]',
                inverted ? 'text-zinc-500' : 'text-zinc-400',
              )}
            >
              ON YOUR MACHINE
            </p>
            <h3 className="mt-3 text-xl font-medium tracking-tight">
              Local tools, with install docs.
            </h3>
          </div>
          <p
            className={cn(
              'max-w-md text-sm leading-6',
              inverted ? 'text-zinc-500' : 'text-zinc-400',
            )}
          >
            The installer fetches missing copies. Install them yourself if you
            already manage your toolchain. Chat CLIs are optional.
          </p>
        </div>
        <ul className="grid gap-3 md:grid-cols-2">
          {requirements.map((item) => (
            <li
              key={item.name}
              className={cn(
                'flex items-start justify-between gap-4 rounded-2xl border px-4 py-4',
                inverted
                  ? 'border-zinc-300 bg-white/60'
                  : 'border-zinc-800 bg-zinc-900/60',
              )}
            >
              <div className="min-w-0">
                <p className="text-sm font-medium tracking-tight">
                  {item.name}
                  {'optional' in item && item.optional ? (
                    <span
                      className={cn(
                        'ml-2 font-mono text-[10px] tracking-[0.12em]',
                        inverted ? 'text-zinc-500' : 'text-zinc-400',
                      )}
                    >
                      OPTIONAL
                    </span>
                  ) : null}
                </p>
                <p
                  className={cn(
                    'mt-1 text-sm leading-6',
                    inverted ? 'text-zinc-500' : 'text-zinc-400',
                  )}
                >
                  {item.purpose}
                </p>
              </div>
              <a
                className={cn(
                  'shrink-0 text-xs font-semibold underline-offset-4 hover:underline',
                  inverted ? 'text-zinc-900' : 'text-zinc-50',
                )}
                href={item.href}
                target="_blank"
                rel="noreferrer"
                aria-label={`Install ${item.name}`}
              >
                Install ↗
              </a>
            </li>
          ))}
        </ul>
      </Reveal>
    </section>
  );
}
