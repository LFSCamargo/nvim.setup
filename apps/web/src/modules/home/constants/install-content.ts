export type InstallMode = 'standard' | 'preview';

export const installSteps = [
  {
    number: '01',
    title: 'Run the installer',
    description:
      'One command. No clone. It installs Neovim, Node, and the rest if they are missing.',
  },
  {
    number: '02',
    title: 'Let it finish',
    description:
      'The script fetches this setup, restores pinned plugins, and installs language tools.',
  },
  {
    number: '03',
    title: 'Make yourself at home',
    description: 'Press i to edit, Esc for normal mode.',
  },
] as const;

export const requirements = [
  {
    name: 'Neovim 0.12+',
    purpose: 'Editor and current Tree-sitter APIs',
    href: 'https://github.com/neovim/neovim/blob/master/INSTALL.md',
  },
  {
    name: 'Node.js 22+ and npm',
    purpose: 'Web language servers and the debug adapter',
    href: 'https://nodejs.org/en/download',
  },
  {
    name: 'Git',
    purpose: 'Clone, status, and the source-control pane',
    href: 'https://git-scm.com/downloads',
  },
  {
    name: 'Homebrew',
    purpose: 'macOS packages when the installer cannot fetch a binary',
    href: 'https://brew.sh',
  },
  {
    name: 'Tree-sitter CLI 0.26.1+',
    purpose: 'Parser builds (Homebrew or Cargo, not npm)',
    href: 'https://tree-sitter.github.io/tree-sitter/creating-parsers/1-getting-started',
  },
  {
    name: 'Go',
    purpose: 'Go language tools',
    href: 'https://go.dev/doc/install',
  },
  {
    name: 'Rust and Cargo',
    purpose: 'Parser CLI and Rust language tools',
    href: 'https://rustup.rs',
  },
  {
    name: 'ripgrep, fd, and fzf',
    purpose: 'Search and file picking',
    href: 'https://github.com/BurntSushi/ripgrep#installation',
  },
  {
    name: 'Codex CLI',
    purpose: 'Optional chat in the right pane',
    href: 'https://github.com/openai/codex',
    optional: true,
  },
  {
    name: 'Cursor Agent CLI',
    purpose: 'Optional chat in the right pane',
    href: 'https://cursor.com/docs/cli/overview',
    optional: true,
  },
  {
    name: 'Gemini CLI',
    purpose: 'Optional chat in the right pane',
    href: 'https://geminicli.com/docs/get-started/installation/',
    optional: true,
  },
  {
    name: 'Claude Code CLI',
    purpose: 'Optional chat in the right pane',
    href: 'https://code.claude.com/docs/en/setup',
    optional: true,
  },
  {
    name: 'OpenCode CLI',
    purpose: 'Optional chat in the right pane',
    href: 'https://opencode.ai/docs/cli/',
    optional: true,
  },
  {
    name: 'Antigravity CLI',
    purpose: 'Optional chat in the right pane',
    href: 'https://antigravity.google/docs/cli/commands/resume/',
    optional: true,
  },
] as const;
