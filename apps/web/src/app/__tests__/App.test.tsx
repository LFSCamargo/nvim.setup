import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, describe, expect, it, vi } from 'vitest';
import App from '@/app/App';
import { applyTheme, THEME_KEY } from '@/modules/theme/theme';

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  window.localStorage.removeItem(THEME_KEY);
  applyTheme('dark');
});

function markdownFor(url: string) {
  if (url.includes('editor.md')) return '# Neovim setup\n\nKeybindings.';
  return [
    '# Get started',
    '',
    'Install the setup.',
    '',
    '```sh',
    'curl -fsSL https://example.com/bootstrap.sh | bash',
    'nvim .',
    '```',
    '',
  ].join('\n');
}

function stubGuides() {
  vi.stubGlobal(
    'fetch',
    vi.fn(async (input: RequestInfo) => ({
      ok: true,
      text: async () => markdownFor(String(input)),
    })),
  );
}

function renderApp(path = '/') {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>,
  );
}

describe('landing page visitor paths', () => {
  it('switches to isolated preview commands and copies the selected recipe', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    });
    renderApp();
    fireEvent.click(screen.getByRole('button', { name: 'Try alongside' }));
    expect(
      screen.getByLabelText('Preview installation commands').textContent,
    ).toContain('bash -s -- --preview');
    fireEvent.click(screen.getByRole('button', { name: 'Copy commands' }));
    await waitFor(() =>
      expect(writeText).toHaveBeenCalledWith(
        expect.stringContaining('NVIM_APPNAME=nvim-preview nvim .'),
      ),
    );
    expect(writeText).toHaveBeenCalledWith(
      expect.stringContaining('scripts/bootstrap.sh'),
    );
    expect(await screen.findByText('Copied ✓')).toBeTruthy();
  });

  it('offers an honest fallback if clipboard access is denied', async () => {
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText: vi.fn().mockRejectedValue(new Error('denied')) },
      configurable: true,
    });
    renderApp();
    fireEvent.click(screen.getByRole('button', { name: 'Copy commands' }));
    expect(await screen.findByText('Select and copy below')).toBeTruthy();
  });

  it('opens the correct screenshot after switching views and closes the lightbox', async () => {
    renderApp();
    fireEvent.click(screen.getByRole('button', { name: 'Source control' }));
    expect(
      screen
        .getByRole('button', { name: 'Source control' })
        .getAttribute('aria-pressed'),
    ).toBe('true');
    fireEvent.click(
      screen.getByRole('button', { name: 'Enlarge source control screenshot' }),
    );
    const dialog = screen.getByRole('dialog');
    expect(dialog.getAttribute('aria-labelledby')).toBe(
      'screenshot-dialog-title',
    );
    expect(dialog.querySelector('img')?.getAttribute('src')).toBe(
      '/assets/git.png',
    );
    expect(within(dialog).getByText('Source control')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Close screenshot' }));
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull());
    fireEvent.click(screen.getByRole('button', { name: 'The layout' }));
    expect(
      screen
        .getByRole('button', { name: 'The layout' })
        .getAttribute('aria-pressed'),
    ).toBe('true');
    fireEvent.click(
      screen.getByRole('button', { name: 'Enlarge the layout screenshot' }),
    );
    expect(
      screen.getByRole('dialog').querySelector('img')?.getAttribute('src'),
    ).toBe('/assets/layout.png');
    fireEvent.click(screen.getByRole('button', { name: 'Close screenshot' }));
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull());
    fireEvent.click(screen.getByRole('button', { name: 'AI agents' }));
    expect(
      screen
        .getByRole('button', { name: 'AI agents' })
        .getAttribute('aria-pressed'),
    ).toBe('true');
    fireEvent.click(
      screen.getByRole('button', { name: 'Enlarge ai agents screenshot' }),
    );
    expect(
      screen.getByRole('dialog').querySelector('img')?.getAttribute('src'),
    ).toBe('/assets/agents.png');
    fireEvent.click(screen.getByRole('button', { name: 'Next screenshot' }));
    expect(
      screen.getByRole('dialog').querySelector('img')?.getAttribute('src'),
    ).toBe('/assets/editor.png');
    fireEvent.click(screen.getByRole('button', { name: 'Close screenshot' }));
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull());
  });

  it('lets visitors switch between light and dark themes', () => {
    renderApp();
    const light = screen.getByRole('button', { name: 'Light' });
    const dark = screen.getByRole('button', { name: 'Dark' });
    expect(dark.getAttribute('aria-pressed')).toBe('true');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
    fireEvent.click(light);
    expect(light.getAttribute('aria-pressed')).toBe('true');
    expect(document.documentElement.classList.contains('dark')).toBe(false);
    expect(document.documentElement.dataset.theme).toBe('light');
    fireEvent.click(dark);
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('keeps light-mode hero chrome, screenshot rims, and inverted install contrast', () => {
    renderApp();
    fireEvent.click(screen.getByRole('button', { name: 'Light' }));
    const caret = document.querySelector('[data-hero-caret]');
    expect(caret).toBeTruthy();
    expect(caret?.textContent).toBe('');
    expect(
      screen
        .getByRole('button', { name: 'Enlarge workspace screenshot' })
        .closest('[data-rim]')
        ?.getAttribute('data-rim'),
    ).toBe('dark');
    expect(document.querySelector('[data-nav-shell]')).toBeTruthy();
    expect(document.querySelector('header [data-rim]')).toBeNull();
    expect(document.getElementById('install')?.className).toMatch(
      /bg-zinc-950/,
    );
    expect(
      screen.getByRole('link', { name: /Make it yours/ }).className,
    ).toMatch(/border-zinc-900/);
    const glow = document.querySelector(
      '.glowing-effect',
    ) as HTMLElement | null;
    expect(glow?.style.getPropertyValue('--gradient')).toContain('#18181b');
  });

  it('sets the workspace caption as a centered editorial line', () => {
    renderApp();
    expect(
      screen.getByText((_, node) => {
        const text = node?.textContent ?? '';
        return (
          node?.tagName === 'P' &&
          text.includes('Less switching.') &&
          text.includes('More making.')
        );
      }),
    ).toBeTruthy();
  });

  it('renders a light Neovim mark on the dark page and a dark mark over the install band', async () => {
    const raf = vi
      .spyOn(window, 'requestAnimationFrame')
      .mockImplementation((cb) => {
        cb(0);
        return 1;
      });
    renderApp();
    const header = document.querySelector('header');
    expect(header).toBeTruthy();
    const home = within(header!).getByRole('link', {
      name: 'nvim.setup home',
    });
    expect(home.querySelector('svg')?.getAttribute('class')).toContain(
      'text-white',
    );
    const install = document.getElementById('install');
    expect(install).toBeTruthy();
    install!.style.backgroundColor = 'rgb(244, 244, 245)';
    header!.getBoundingClientRect = () =>
      ({
        top: 16,
        left: 0,
        width: 800,
        height: 64,
        bottom: 80,
        right: 800,
        x: 0,
        y: 16,
        toJSON() {
          return {};
        },
      }) as DOMRect;
    install!.getBoundingClientRect = () =>
      ({
        top: 40,
        left: 0,
        width: 800,
        height: 600,
        bottom: 640,
        right: 800,
        x: 0,
        y: 40,
        toJSON() {
          return {};
        },
      }) as DOMRect;
    try {
      fireEvent.scroll(window);
      await waitFor(() =>
        expect(home.querySelector('svg')?.getAttribute('class')).toContain(
          'text-black',
        ),
      );
    } finally {
      raf.mockRestore();
    }
  });

  it('lets visitors pin a published setup version on the installer', () => {
    renderApp();
    const version = screen.getByLabelText('Setup version');
    expect((version as HTMLSelectElement).value).toBe('v1.1.0');
    expect(
      screen.getByLabelText('Standard installation commands').textContent,
    ).toContain('bash -s -- --version v1.1.0');
    fireEvent.change(version, { target: { value: 'main' } });
    expect(
      screen.getByLabelText('Standard installation commands').textContent,
    ).toContain('scripts/bootstrap.sh | bash');
    expect(
      screen.getByLabelText('Standard installation commands').textContent,
    ).not.toContain('--version');
  });

  it('exposes installation, documentation, and a real help destination', () => {
    renderApp();
    expect(
      screen.getByLabelText('Standard installation commands').textContent,
    ).toContain('scripts/bootstrap.sh | bash');
    expect(
      screen
        .getByRole('link', { name: 'Install Neovim 0.12+' })
        .getAttribute('href'),
    ).toBe('https://github.com/neovim/neovim/blob/master/INSTALL.md');
    expect(
      screen
        .getByRole('link', { name: 'Install Codex CLI' })
        .getAttribute('href'),
    ).toBe('https://github.com/openai/codex');
    expect(
      screen
        .getByRole('link', { name: 'Install Antigravity CLI' })
        .getAttribute('href'),
    ).toBe('https://antigravity.google/docs/cli/commands/resume/');
    expect(
      screen
        .getByRole('link', {
          name: 'Full requirements in the getting started guide ↗',
        })
        .getAttribute('href'),
    ).toBe('/docs/getting-started');
    expect(
      screen.getByRole('link', { name: /Make it yours/ }).getAttribute('href'),
    ).toBe('#install');
    expect(
      screen
        .getByRole('link', { name: 'The editor guide' })
        .getAttribute('href'),
    ).toBe('/docs/editor');
    expect(
      screen.getByRole('link', { name: /Ask for help/ }).getAttribute('href'),
    ).toBe('https://github.com/LFSCamargo/nvim.setup/issues/new/choose');
    fireEvent.click(screen.getByRole('button', { name: 'Menu +' }));
    expect(
      screen
        .getByRole('button', { name: 'Close −' })
        .getAttribute('aria-expanded'),
    ).toBe('true');
  });

  it('loops the principles ticker as two equal halves', () => {
    renderApp();
    expect(
      screen.getByRole('region', {
        name: 'A little less friction. Files, code, Git, AI. A lot more flow.',
      }),
    ).toBeTruthy();
    const groups = document.querySelectorAll('[data-marquee-group]');
    expect(groups).toHaveLength(2);
    expect(groups[0]?.childElementCount).toBe(groups[1]?.childElementCount);
    expect(groups[0]?.childElementCount).toBeGreaterThanOrEqual(2);
  });

  it('describes files, git, chats, settings, extensions, and language tools', () => {
    renderApp();
    expect(screen.getByText('Files, in a real tree.')).toBeTruthy();
    expect(screen.getByText('Git, without the detour.')).toBeTruthy();
    expect(screen.getByText('Chats with your own agents.')).toBeTruthy();
    expect(screen.getByText('Settings that stay with you.')).toBeTruthy();
    expect(screen.getByText('Extensions, in the sidebar.')).toBeTruthy();
    expect(screen.getByText('Right-click where you are.')).toBeTruthy();
    expect(screen.getByText('LSP, format, and debug.')).toBeTruthy();
    expect(
      screen.getByText(/Check Diff opens the change in the mid editor/),
    ).toBeTruthy();
  });

  it('sets the home document title and Open Graph description', () => {
    renderApp();
    expect(document.title).toBe('nvim.setup — A quieter place to build.');
    expect(
      document
        .querySelector('meta[name="description"]')
        ?.getAttribute('content'),
    ).toMatch(/Neovim workspace/);
    expect(
      document.querySelector('link[rel="canonical"]')?.getAttribute('href'),
    ).toMatch(/\/$/);
    expect(
      document
        .querySelector('meta[property="og:title"]')
        ?.getAttribute('content'),
    ).toBe('nvim.setup — A quieter place to build.');
    expect(document.getElementById('seo-json-ld')?.textContent).toContain(
      'SoftwareApplication',
    );
  });
});

describe('documentation reader', () => {
  it('opens the on-site getting started guide with a GitHub source link', async () => {
    stubGuides();
    renderApp('/docs');
    expect(
      await screen.findByRole('heading', { level: 1, name: 'Get started' }),
    ).toBeTruthy();
    expect(fetch).toHaveBeenCalledWith('/guides/getting-started.md');
    expect(
      screen
        .getByRole('link', { name: 'View on GitHub ↗' })
        .getAttribute('href'),
    ).toBe('https://github.com/LFSCamargo/nvim.setup/blob/main/README.md');
    expect(
      screen.getByRole('navigation', { name: 'Documentation' }),
    ).toBeTruthy();
  });

  it('lets visitors copy a documentation code sample', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    });
    stubGuides();
    renderApp('/docs');
    await screen.findByRole('heading', { level: 1, name: 'Get started' });
    expect(screen.getByLabelText('terminal code sample').textContent).toContain(
      'bootstrap.sh',
    );
    fireEvent.click(screen.getByRole('button', { name: 'Copy code' }));
    await waitFor(() =>
      expect(writeText).toHaveBeenCalledWith(
        'curl -fsSL https://example.com/bootstrap.sh | bash\nnvim .',
      ),
    );
    expect(await screen.findByText('Copied ✓')).toBeTruthy();
  });

  it('switches sidebar pages and keeps a GitHub destination for the editor guide', async () => {
    stubGuides();
    renderApp('/docs/getting-started');
    await screen.findByRole('heading', { level: 1, name: 'Get started' });
    fireEvent.click(screen.getByRole('link', { name: 'Editor guide' }));
    expect(
      await screen.findByRole('heading', { level: 1, name: 'Neovim setup' }),
    ).toBeTruthy();
    expect(
      screen
        .getByRole('link', { name: 'View on GitHub ↗' })
        .getAttribute('href'),
    ).toBe('https://github.com/LFSCamargo/nvim.setup/blob/main/docs/EDITOR.md');
    expect(document.title).toBe('Editor guide — nvim.setup');
    expect(
      document
        .querySelector('meta[name="description"]')
        ?.getAttribute('content'),
    ).toBe('Keybindings, panes, languages, chat, and debugging.');
  });

  it('sends unknown docs slugs to the getting started guide', async () => {
    stubGuides();
    renderApp('/docs/not-a-real-guide');
    expect(
      await screen.findByRole('heading', { level: 1, name: 'Get started' }),
    ).toBeTruthy();
    expect(document.title).toBe('Get started — nvim.setup');
  });
});
