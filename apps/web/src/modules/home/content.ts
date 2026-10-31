export const screens = [
  {
    id: 'workspace',
    label: 'The workspace',
    src: '/assets/editor.png',
    width: 1920,
    height: 1080,
    caption:
      'Files, code, and a place to think. Your terminal, thoughtfully arranged.',
    alt: 'Real Neovim setup screenshot showing Files, Git, Settings, and Extensions beside editor tabs and init.lua',
  },
  {
    id: 'git',
    label: 'Source control',
    src: '/assets/git.png',
    width: 1920,
    height: 1080,
    caption: 'See what changed. Stage with a click. Keep your code in view.',
    alt: 'Real Neovim setup screenshot showing Git source control, Check Diff, the commit composer, and history',
  },
  {
    id: 'settings',
    label: 'Settings',
    src: '/assets/settings.png',
    width: 1920,
    height: 1080,
    caption:
      'Icons, transparency, indent, search, and session restore. Click a row to change it.',
    alt: 'Real Neovim setup screenshot showing the Settings sidebar with appearance, editing, search, and session preferences',
  },
  {
    id: 'extensions',
    label: 'Extensions',
    src: '/assets/extensions.png',
    width: 1920,
    height: 1080,
    caption:
      'Search Mason packages, see what is installed, and add a GitHub plugin without leaving the sidebar.',
    alt: 'Real Neovim setup screenshot showing the Extensions marketplace with installed Mason language servers and formatters',
  },
  {
    id: 'layout',
    label: 'The layout',
    src: '/assets/layout.png',
    width: 1920,
    height: 1080,
    caption:
      'Git on the left. Codex on the right. Your buffer stays in the middle.',
    alt: 'Real Neovim setup screenshot showing Git changes beside the editor and a Codex session',
  },
  {
    id: 'agents',
    label: 'AI agents',
    src: '/assets/agents.png',
    width: 1920,
    height: 1080,
    caption:
      'Codex, Cursor Agent, Gemini, Claude, OpenCode, and Antigravity run as real CLI sessions in the right pane. Your login, your permissions.',
    alt: 'Real Neovim setup screenshot showing Agent, Codex, and Antigravity tabs beside the editor',
  },
] as const;

export type Screen = (typeof screens)[number];

export const features = [
  {
    number: '01',
    title: 'Files, in a real tree.',
    description:
      'The left 20% is nvim-tree. Click a file to open it in the mid editor. Ctrl+B toggles the tree. Ctrl+P finds files, including hidden ones. Ctrl+F searches the project. Files, Git, Settings, and Extensions share that sidebar.',
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
      'Ctrl+G opens source control beside your code: stage, unstage, revert, commit, and a commit log. Check Diff opens the change in the mid editor. Status loads in the background, so you can switch back to Files while it finishes.',
    tag: 'Asynchronous source control',
  },
  {
    number: '04',
    title: 'Chats with your own agents.',
    description:
      'The right 28% runs the real Codex, Cursor Agent, Gemini, Claude, OpenCode, and Antigravity CLIs. Your login, your permissions. Multiple sessions, ID resume, Esc to stop generation. Closing a tab stops that CLI; switching leaves it running.',
    tag: 'Optional AI tools',
  },
  {
    number: '05',
    title: 'Settings that stay with you.',
    description:
      'Ctrl+, opens Settings next to Files and Git. Icons, transparency, indent, search case, and session restore. Click a row to change it; x restores the default. Preferences persist on this machine.',
    tag: 'User preferences',
  },
  {
    number: '06',
    title: 'Extensions, in the sidebar.',
    description:
      'Click Extensions to search Mason packages, install or uninstall, and add a GitHub plugin. Space p opens the command palette for file search, format, Git, Settings, and appearance.',
    tag: 'Marketplace and palette',
  },
  {
    number: '07',
    title: 'LSP, format, and debug.',
    description:
      'Mason installs language servers for TypeScript, Vue, Svelte, Rust, Go, Solidity, Lua, and web configs. gd / gr / K, completion, Space f to format, F5 to debug. Not on save — when you ask.',
    tag: 'Language tools',
  },
  {
    number: '08',
    title: 'Right-click where you are.',
    description:
      'Right-click, Shift+F10, or :ContextMenu on a file, Git change, or tab. Open, rename, Check Diff, stage, close. The item under the pointer is the one that counts.',
    tag: 'Context menus',
  },
  {
    number: '09',
    title: 'A workspace that remembers.',
    description:
      'Ctrl+Q snapshots this project’s tabs, unsaved files, and chat UUIDs. Open the same directory later and they come back. nvim --clean starts blank without overwriting the last session.',
    tag: 'Session persistence',
  },
] as const;

export const heroWords = ['build.', 'think.', 'ship.'] as const;
