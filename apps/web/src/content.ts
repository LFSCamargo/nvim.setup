export const repo = 'https://github.com/LFSCamargo/nvim.setup';
export const site = 'https://lfscamargo.github.io/nvim.setup';
export const siteName = 'nvim.setup';
export const siteTitle = 'nvim.setup — A quieter place to build.';
export const siteDescription =
  'A considered Neovim workspace. Code, Git, and AI chats in one terminal. Explore the setup, read the documentation, and make it yours.';
export const docs = `${repo}/blob/main/docs`;
export const helpUrl = `${repo}/issues/new/choose`;
export const issuesUrl = `${repo}/issues`;
export const aceternitySpotlight =
  'https://ui.aceternity.com/components/spotlight-new';
export const aceternityLiquidGlass =
  'https://ui.aceternity.com/components/liquid-glass';

export const commands = {
  standard: [
    'curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash',
    'nvim .',
  ].join('\n'),
  preview: [
    'curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash -s -- --preview',
    'NVIM_APPNAME=nvim-preview nvim .',
  ].join('\n'),
} as const;

export type InstallMode = keyof typeof commands;

export const screens = [
  {
    id: 'workspace',
    label: 'The workspace',
    src: '/assets/editor.png',
    width: 1916,
    height: 1016,
    caption:
      'Files, code, and a place to think. Your terminal, thoughtfully arranged.',
    alt: 'Real Neovim setup screenshot showing the nvim-tree file sidebar and editor tabs',
  },
  {
    id: 'git',
    label: 'Source control',
    src: '/assets/git.png',
    width: 1916,
    height: 1016,
    caption: 'See what changed. Stage with a click. Keep your code in view.',
    alt: 'Real Neovim setup screenshot showing grouped Git changes, the commit composer, and history',
  },
  {
    id: 'layout',
    label: 'The layout',
    src: '/assets/layout.png',
    width: 1916,
    height: 1016,
    caption:
      'Git on the left. Codex on the right. Your buffer stays in the middle.',
    alt: 'Real Neovim setup screenshot showing Git changes beside the editor and a Codex session',
  },
  {
    id: 'agents',
    label: 'AI agents',
    src: '/assets/agents.png',
    width: 1916,
    height: 1016,
    caption:
      'Codex, Cursor Agent, Gemini, Claude, and OpenCode run as real CLI sessions in the right pane. Your login, your permissions.',
    alt: 'Real Neovim setup screenshot showing a Codex session chatting beside open source files',
  },
] as const;

export type Screen = (typeof screens)[number];

export const features = [
  {
    number: '01',
    title: 'Files, in a real tree.',
    description:
      'The left 20% is nvim-tree. Click a file to open it in the mid editor. Ctrl+B toggles the tree. Ctrl+P finds files, including hidden ones. Ctrl+F searches the project.',
    tag: 'File tree',
  },
  {
    number: '02',
    title: 'Editor tabs that stay put.',
    description:
      'Click a tab to switch, + to add, × to close. Unsaved buffers are protected. :q on the last window keeps the mid pane so the layout does not collapse.',
    tag: 'Clickable tabs',
  },
  {
    number: '03',
    title: 'Git, without the detour.',
    description:
      'Ctrl+G opens source control beside your code: stage, unstage, revert, commit, and a commit log. Status loads in the background, so you can switch back to Files while it finishes.',
    tag: 'Asynchronous source control',
  },
  {
    number: '04',
    title: 'Chats with your own agents.',
    description:
      'The right 25% runs the real Codex, Cursor Agent, Gemini, Claude, and OpenCode CLIs. Your login, your permissions. Multiple sessions, ID resume, Esc to stop generation. Closing a tab stops that CLI; switching leaves it running.',
    tag: 'Optional AI tools',
  },
  {
    number: '05',
    title: 'LSP, format, and debug.',
    description:
      'Mason installs language servers for TypeScript, Vue, Svelte, Rust, Go, Solidity, Lua, and web configs. gd / gr / K, completion, Space f to format, F5 to debug. Not on save — when you ask.',
    tag: 'Language tools',
  },
  {
    number: '06',
    title: 'A workspace that remembers.',
    description:
      'Ctrl+Q snapshots this project’s tabs, unsaved files, and chat UUIDs. Open the same directory later and they come back. nvim --clean starts blank without overwriting the last session.',
    tag: 'Session persistence',
  },
] as const;

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

export const docLinks = [
  {
    number: '01',
    title: 'Get started',
    description: 'Install, requirements, and the first minutes in the editor.',
    slug: 'getting-started',
    file: 'README.md',
  },
  {
    number: '02',
    title: 'The workspace',
    description: 'Files, Git, AI chats, LSP, format, debug, and sessions.',
    slug: 'workspace',
    file: 'docs/EDITOR.md',
  },
  {
    number: '03',
    title: 'The editor guide',
    description: 'Shortcuts, panes, languages, and your daily workflow.',
    slug: 'editor',
    file: 'docs/EDITOR.md',
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
] as const;

export const heroWords = ['build.', 'think.', 'ship.'] as const;
