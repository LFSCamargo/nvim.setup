import { Link } from 'react-router-dom';
import { Reveal } from '@/shared/components/reveal';

export function Trackpad() {
  return (
    <section id="trackpad" className="mx-auto max-w-6xl px-6 py-20">
      <Reveal className="max-w-2xl">
        <p className="font-mono text-[10px] tracking-[0.16em] text-muted">
          03 / A SMALL MACOS HELPER
        </p>
        <h2 className="mt-5 text-[clamp(2.1rem,4vw,3.4rem)] leading-tight font-medium tracking-[-0.04em]">
          Sideways swipes,
          <br />
          <span className="text-muted">your choice.</span>
        </h2>
        <p className="mt-6 text-sm leading-7 text-muted">
          Warp, Terminal.app, and iTerm do not pass sideways trackpad gestures
          through to Neovim. An optional Swift helper watches those gestures
          while a supported terminal is frontmost, then asks Neovim to scroll
          the editor or sidebar through a local socket. It runs as a macOS user
          LaunchAgent and needs Accessibility permission. Git, language tools,
          and AI chats do not depend on it.
        </p>
      </Reveal>
      <div className="mt-10 grid gap-4 md:grid-cols-2">
        <Reveal>
          <div className="h-full rounded-2xl border border-line bg-glass p-6">
            <p className="font-mono text-[10px] tracking-[0.12em] text-muted">
              WITH THE HELPER
            </p>
            <h3 className="mt-4 text-lg font-medium">Swipe naturally.</h3>
            <p className="mt-3 text-sm leading-7 text-muted">
              Leave the install option on. After installation, allow
              nvim-setup-hscroll in macOS Accessibility settings. The helper
              starts at login and forwards horizontal gestures to a running
              Neovim instance.
            </p>
          </div>
        </Reveal>
        <Reveal>
          <div className="h-full rounded-2xl border border-line bg-glass p-6">
            <p className="font-mono text-[10px] tracking-[0.12em] text-muted">
              WITHOUT THE HELPER
            </p>
            <h3 className="mt-4 text-lg font-medium">Keep it simple.</h3>
            <p className="mt-3 text-sm leading-7 text-muted">
              Turn off the helper in the installer below. A standard install
              stops an existing LaunchAgent; an isolated preview leaves your
              current one alone. Use Option or Ctrl plus the mouse wheel to move
              sideways, or turn on Settings → Scrollbars and drag. Terminals
              that already pass side-wheel events need no helper.
            </p>
          </div>
        </Reveal>
      </div>
      <Reveal className="mt-7">
        <Link
          to="/docs/editor"
          className="text-sm text-foreground/80 hover:text-foreground"
        >
          Read the scrolling guide ↗
        </Link>
      </Reveal>
    </section>
  );
}
