import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { docs } from '@/shared/constants/site';
import {
  installSteps,
  requirements,
  type InstallMode,
  type InstallPlatform,
} from '@/modules/home/constants/install-content';
import { useInstallVersions } from '@/modules/home/hooks/use-install-versions';
import { installCommands, mainRef } from '@/modules/home/utils/releases';
import { CodeBlock } from '@/shared/components/code-block';
import { LiquidGlass } from '@/shared/components/liquid-glass';
import { Reveal } from '@/shared/components/reveal';
import { useTheme } from '@/modules/theme/hooks/use-theme';
import { cn } from '@/shared/utils/cn';

export function Install() {
  const { theme } = useTheme();
  const inverted = theme === 'dark';
  const [mode, setMode] = useState<InstallMode>('standard');
  const [platform, setPlatform] = useState<InstallPlatform>('macos');
  const [withHscroll, setWithHscroll] = useState(true);
  const { refs, selected, setSelected } = useInstallVersions();
  const recipe = installCommands(
    mode,
    selected,
    platform === 'linux' || withHscroll,
  );
  const [copy, setCopy] = useState('Copy commands');

  useEffect(() => {
    const timer = window.setTimeout(() => setCopy('Copy commands'), 2500);
    return () => window.clearTimeout(timer);
  }, [copy]);

  async function copyCommands() {
    try {
      await navigator.clipboard.writeText(recipe);
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
            04 / FROM HERE TO YOUR TERMINAL
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
            One command. A complete workspace. Pick a release, or follow main.
            The installer fetches that version and installs Neovim if you do not
            have it. Choose a fresh install, or try it alongside your current
            configuration.
          </p>
          <p
            className={cn(
              'mt-5 max-w-md text-sm leading-7',
              inverted ? 'text-zinc-500' : 'text-zinc-400',
            )}
          >
            {platform === 'macos'
              ? 'On macOS, run the command in Warp, Terminal.app, or iTerm. The installer may need Xcode Command Line Tools. Enable Accessibility only if you choose the trackpad helper.'
              : 'On Linux, run the command in your terminal. The installer supports apt, dnf, and pacman and may ask for sudo when installing system packages. No trackpad background helper is needed.'}
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
            <div className="flex gap-5 px-5 pt-4" aria-label="Operating system">
              {(
                [
                  ['macos', 'macOS'],
                  ['linux', 'Linux'],
                ] as const
              ).map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  aria-pressed={platform === value}
                  onClick={() => {
                    setPlatform(value);
                    if (
                      value === 'macos' &&
                      !withHscroll &&
                      selected !== mainRef
                    )
                      setSelected(mainRef);
                  }}
                  className={cn(
                    'border-b pb-2 text-xs text-zinc-500',
                    platform === value
                      ? 'border-zinc-100 text-white'
                      : 'border-transparent',
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
            {platform === 'macos' ? (
              <label className="mx-5 mt-5 flex cursor-pointer items-start gap-3 rounded-lg border border-white/10 p-3 text-xs text-zinc-300">
                <input
                  type="checkbox"
                  checked={withHscroll}
                  onChange={(event) => {
                    setWithHscroll(event.target.checked);
                    if (!event.target.checked && selected !== mainRef)
                      setSelected(mainRef);
                  }}
                  className="mt-0.5 accent-amber-400"
                />
                <span>
                  Install macOS trackpad helper
                  <span className="mt-1 block text-zinc-500">
                    Enables sideways swipes in Warp, Terminal.app, and iTerm.
                    Turn off to skip the background LaunchAgent. The no-helper
                    option uses main until the next release.
                  </span>
                </span>
              </label>
            ) : null}
            <label className="flex items-center justify-between gap-4 px-5 pt-4 text-xs text-zinc-400">
              <span className="shrink-0 tracking-[0.12em]">VERSION</span>
              <select
                aria-label="Setup version"
                value={selected}
                onChange={(event) => setSelected(event.target.value)}
                className="min-w-0 flex-1 bg-transparent text-right text-zinc-100 outline-none"
              >
                {refs.map((item) => (
                  <option
                    key={item.id}
                    value={item.id}
                    disabled={
                      platform === 'macos' &&
                      !withHscroll &&
                      item.id !== mainRef
                    }
                    className="text-zinc-900"
                  >
                    {item.label}
                  </option>
                ))}
              </select>
            </label>
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
              code={recipe}
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
            {platform === 'macos'
              ? 'Requires internet access. Missing Neovim, Node, Git, or Homebrew are installed for you.'
              : 'Requires internet access. Missing Neovim, Node, and Git are installed for you. System packages may prompt for sudo.'}
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
          {requirements
            .filter(
              (item) => !('platform' in item) || item.platform === platform,
            )
            .map((item) => (
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
