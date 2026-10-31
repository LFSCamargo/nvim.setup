export const screens = [
  {
    id: 'workspace',
    label: 'The workspace',
    src: '/assets/workspace-2026-10-31.png',
    width: 3420,
    height: 2224,
    caption:
      'Files, code, and a place to think. Your terminal, thoughtfully arranged.',
    alt: 'Neovim in Warp with the Files tree, Swift source in the editor, and a Codex chat',
  },
  {
    id: 'git',
    label: 'Source control',
    src: '/assets/git-2026-10-31.png',
    width: 3420,
    height: 2224,
    caption: 'See what changed. Stage with a click. Keep your code in view.',
    alt: 'Git sidebar with a commit composer, changed files, history, code, and a Codex chat',
  },
  {
    id: 'settings',
    label: 'Settings',
    src: '/assets/settings-2026-10-31.png',
    width: 3420,
    height: 2224,
    caption:
      'Icons, transparency, indent, search, and session restore. Click a row to change it.',
    alt: 'Settings sidebar showing theme, appearance, editing, search, and session preferences',
  },
  {
    id: 'themes',
    label: 'Themes',
    src: '/assets/themes-2026-10-31.png',
    width: 3420,
    height: 2224,
    caption: 'Search a theme, select it, and keep coding with the new palette.',
    alt: 'Themes sidebar with Gruvbox Dark selected and a searchable list of color schemes',
  },
  {
    id: 'extensions',
    label: 'Extensions',
    src: '/assets/extensions-2026-10-31.png',
    width: 3420,
    height: 2224,
    caption:
      'Search Mason packages, see what is installed, and add a GitHub plugin without leaving the sidebar.',
    alt: 'Extensions sidebar with Mason packages, install actions, and installed language tools',
  },
  {
    id: 'rose-pine',
    label: 'Rosé Pine',
    src: '/assets/rose-pine-2026-10-31.png',
    width: 3420,
    height: 2224,
    caption: 'The same workspace, recolored live with the Rosé Pine theme.',
    alt: 'Neovim workspace using the Rosé Pine theme across the sidebar, editor, chat, tabs, and statusline',
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
      'The left 20% is nvim-tree. Click a file to open it in the mid editor. Ctrl+B toggles the tree. Ctrl+P finds files, including hidden ones. Ctrl+F searches the project. Files, Git, Settings, Themes, and Extensions share that sidebar.',
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
      'Ctrl+, opens Settings next to Files and Git. Color theme, icons, transparency, indent, search case, and session restore. Click Color theme to open the Themes sidebar and pick from 20 dark schemes, including Cursor Dark and VS Code Dark+. x restores the default. Preferences persist on this machine.',
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
