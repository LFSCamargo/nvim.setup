# Plugins and first-party modules

This setup is not one plugin. It is our Neovim config plus pinned third-party plugins, Mason tools, and Tree-sitter parsers. Use this list when adding or removing pieces; keep it in sync with `nvim/init.lua`, `nvim/lua/modules/`, and `nvim/lua/modules/tooling/init.lua`.

## First-party (this repository)

Code we wrote. These live under `nvim/lua/modules/` and `scripts/`. They are not Lazy plugins.

| Module       | Path                                     | What it does                                                                                                                                                                                          |
| ------------ | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Agents       | `nvim/lua/modules/agents/init.lua`       | Chat CLI panes (Codex, Cursor Agent, Gemini, Claude, OpenCode, Antigravity), ID resume, Esc, close tab on exit                                                                                        |
| Session      | `nvim/lua/modules/session/init.lua`      | Per-project tabs, unsaved snapshots, chat UUIDs, Ctrl+Q, `NVIM_CLEAN`; swap files off                                                                                                                 |
| Sidebar      | `nvim/lua/modules/sidebar/init.lua`      | Files / Git / Settings / Extensions panel (yellow active tab with black text/icon and solid point, transparent inactive tabs with hollow ``); Files names stay white unless git-dirty; composer, log |
| Diff         | `nvim/lua/modules/diff/init.lua`         | Read-only staged and unstaged Git diffs in the editor pane, selected from the Git sidebar                                                                                                             |
| Context menu | `nvim/lua/modules/context_menu/init.lua` | Shared right-click and keyboard menu for Files, Git, editor/chat tabs, and sidebar tabs                                                                                                               |
| Settings     | `nvim/lua/modules/settings/init.lua`     | User preferences, shipped defaults, live reload, and Settings sidebar tab                                                                                                                             |
| Extensions   | `nvim/lua/modules/extensions/init.lua`   | User plugin manifest, suggested plugin browser, Mason/Tree-sitter access, Extensions sidebar tab                                                                                                      |
| Palette      | `nvim/lua/modules/palette/init.lua`      | Searchable quick actions for coding and configuration                                                                                                                                                 |
| Keys         | `nvim/lua/modules/keys/init.lua`         | Global and leader maps, Ctrl shortcuts, user commands                                                                                                                                                 |
| Tabs         | `nvim/lua/modules/tabs/init.lua`         | Clickable editor/chat winbar tabs; yellow active tab, transparent inactive tabs; editor ``/`` left, agents `+` ``/`` right; Ctrl+P opens here                                                     |
| LSP          | `nvim/lua/modules/lsp/init.lua`          | Server configs and buffer-local LSP keys                                                                                                                                                              |
| DAP          | `nvim/lua/modules/dap/init.lua`          | Debug adapters and `:DebugLoadLaunch`                                                                                                                                                                 |
| Appearance   | `nvim/lua/modules/appearance/init.lua`   | Gruvbox transparency; selection, statusline, and top-bar fills stay visible                                                                                                                           |
| Statusline   | `nvim/lua/modules/statusline/init.lua`   | Global muted Gruvbox bar: mode, git, file, diagnostics, LSP, search, cursor                                                                                                                           |
| Startup      | `nvim/lua/modules/startup/init.lua`      | Interactive layout: tree, editor focus, restore or default chats                                                                                                                                      |
| Icons        | `nvim/lua/modules/icons/init.lua`        | Colored Devicons for Files/Git glyphs; names stay white unless git-dirty; toggled from Settings                                                                                                       |
| Format       | `nvim/lua/modules/format/init.lua`       | Conform formatters: StyLua, prettierd, shfmt, Taplo, rustfmt, gofmt                                                                                                                                   |
| Images       | `nvim/lua/modules/images/init.lua`       | Opens PNG/JPEG/GIF/WebP/SVG and similar files in the system viewer (`open` / `xdg-open`)                                                                                                              |
| Tooling      | `nvim/lua/modules/tooling/init.lua`      | Mason package list and Tree-sitter parser list                                                                                                                                                        |
| Wrapper      | `scripts/nvim-wrapper.sh`                | `nvim --clean` loads this config without restoring a session                                                                                                                                          |
| Bootstrap    | `scripts/bootstrap.sh`                   | One-shot installer: fetch the repo, deps, icon fonts, then the Neovim config                                                                                                                          |
| Fonts        | `scripts/fonts.sh`                       | Symbols Nerd Font and a Monocraft Nerd Font face with one-cell Devicons and pixelated Powerline glyphs                                                                                                |

`nvim/init.lua` is the entry point (options, Lazy, then the modules above). Add behavior to its owning module. `agents/antigravity.lua` reads workspace conversation IDs; `sidebar/tree.lua` owns the file-tree options and highlights; `sidebar/status.lua` parses Git status; `shared/buffer.lua` updates read-only UI buffers. Lazy specs live in `modules/plugins/ui.lua` and `modules/plugins/tools.lua`, assembled by `modules/plugins/init.lua`. See [Architecture](ARCHITECTURE.md) for module boundaries.

## Installed Neovim plugins (Lazy)

Pinned in `nvim/lazy-lock.json`. Restored by `make plugins`. Declared in `nvim/lua/modules/plugins/`.

| Plugin                                                                | Role                                                  |
| --------------------------------------------------------------------- | ----------------------------------------------------- |
| [lazy.nvim](https://github.com/folke/lazy.nvim)                       | Plugin manager                                        |
| [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim)           | Colorscheme (transparent)                             |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)   | File icons in the Files tree and Git                  |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)           | File tree (Files tab)                                 |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua)                        | Find files and live grep                              |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)           | Hunk signs, blame, preview/stage hunk                 |
| [vim-fugitive](https://github.com/tpope/vim-fugitive)                 | `:Git` status, blame, log, diff                       |
| [trouble.nvim](https://github.com/folke/trouble.nvim)                 | Project diagnostics list                              |
| [which-key.nvim](https://github.com/folke/which-key.nvim)             | Keybinding popup (no mapping icons)                   |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax parsers (`main` branch)                        |
| [mason.nvim](https://github.com/mason-org/mason.nvim)                 | Installs language servers, formatters, debug adapters |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)            | Language-server configs                               |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)                       | Completion                                            |
| [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp)               | LSP completion source                                 |
| [cmp-buffer](https://github.com/hrsh7th/cmp-buffer)                   | Buffer completion source                              |
| [cmp-path](https://github.com/hrsh7th/cmp-path)                       | Path completion source                                |
| [conform.nvim](https://github.com/stevearc/conform.nvim)              | Format on demand (Space f)                            |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap)                  | Debugger                                              |
| [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)                | Debugger panels                                       |
| [nvim-nio](https://github.com/nvim-neotest/nvim-nio)                  | Async IO for dap-ui                                   |
| [nvim-dap-go](https://github.com/leoluz/nvim-dap-go)                  | Delve adapter helper                                  |

The Files tree and Git sidebar use [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons). `make install` / `scripts/bootstrap.sh` runs `scripts/fonts.sh`, which installs [Symbols Nerd Font](https://github.com/ryanoasis/nerd-fonts) and a Regular [Monocraft](https://github.com/IdreesInc/Monocraft) face named **Monocraft Nerd Font** into the user font directory (`~/Library/Fonts` on macOS, `~/.local/share/fonts/nvim-setup` on Linux). That face has Nerd Font Devicons baked in at one cell, plus pixelated Powerline points and chevrons (Warp has no fallback list). If Warp’s terminal font is Monocraft, that setting becomes **Monocraft Nerd Font**. Kitty and Ghostty configs that already exist get fallback/`symbol_map` lines.

## Mason tools (installed binaries)

Listed in `modules.tooling.packages`. Installed by `make tools`. Versions are not pinned in the lockfile.

| Package                                  | Used for                                                 |
| ---------------------------------------- | -------------------------------------------------------- |
| vtsls                                    | TypeScript / JavaScript / React (and Vue TS plugin host) |
| vue-language-server                      | Vue                                                      |
| svelte-language-server                   | Svelte                                                   |
| html-lsp, css-lsp                        | HTML / CSS                                               |
| tailwindcss-language-server              | Tailwind                                                 |
| eslint-lsp                               | ESLint                                                   |
| rust-analyzer                            | Rust (Clippy check)                                      |
| gopls                                    | Go                                                       |
| nomicfoundation-solidity-language-server | Solidity                                                 |
| taplo                                    | TOML (LSP + format)                                      |
| json-lsp, yaml-language-server           | JSON / YAML                                              |
| lua-language-server                      | Lua                                                      |
| prettierd                                | Format JS/TS/Vue/Svelte/HTML/CSS/JSON/YAML/Markdown      |
| stylua                                   | Format Lua                                               |
| shfmt                                    | Format shell scripts                                     |
| js-debug-adapter                         | Node and Chrome debug                                    |
| delve                                    | Go debug                                                 |
| codelldb                                 | Rust debug                                               |

## Tree-sitter parsers

Listed in `modules.tooling.parsers`. Installed by `make parsers`.

bash, css, go, gomod, html, javascript, json, lua, markdown, markdown_inline, rust, solidity, svelte, toml, tsx, typescript, vim, vimdoc, vue, yaml, zsh.

## Optional CLIs (not installed by this repo)

Authenticate separately. Missing binaries print a notice; the editor still works.

| Binary     | Chat pane    | Resume                                                  |
| ---------- | ------------ | ------------------------------------------------------- |
| `codex`    | Codex        | `codex resume <uuid>`                                   |
| `agent`    | Cursor Agent | `agent --resume=<uuid>`                                 |
| `gemini`   | Gemini       | `gemini --resume <uuid>` (new chats use `--session-id`) |
| `claude`   | Claude       | `claude --resume <uuid>`                                |
| `opencode` | OpenCode     | `opencode --session <id>`                               |
| `agy`      | Antigravity  | `agy --conversation <id>`                               |

## Marketing application

`apps/web` is a separate TypeScript React/Vite application with Tailwind CSS, managed by the pnpm workspace and Nx. It does not add Neovim plugins or change the installed editor. Root `project.json` exposes the existing setup checks as the Nx `setup` project; the web package is the `web` project. Website dependencies and Aceternity UI adaptations are declared in `apps/web/package.json` and `apps/web/THIRD-PARTY-NOTICES.md`. The `/docs` reader loads static markdown from `apps/web/public/guides/` (repo guides are copied there at `vite` start/build). Fenced samples render through `apps/web/src/shared/components/code-block.tsx` (copy, line numbers, wrapping). Titles, canonicals, Open Graph/Twitter tags, and JSON-LD come from `apps/web/src/shared/utils/seo.ts`; crawlers also get `apps/web/public/robots.txt` and `apps/web/public/sitemap.xml` (raw `/guides/*.md` copies are disallowed so they do not compete with `/docs`). A refresh on `/docs/:slug` is recovered by Vite `appType: 'spa'`, a copied `dist/404.html` shell, and `apps/web/public/_redirects`. Format the site with `pnpm format` (Prettier plus `prettier-plugin-tailwindcss`). `make scan` / `pnpm scan` is the OWASP barrier for that tree: Semgrep CE (`p/owasp-top-ten`, `p/javascript`, `p/typescript`, `p/react`, `p/security-audit`) plus `pnpm audit --audit-level=moderate`. CI runs Semgrep plus Prettier, TypeScript, and `pnpm build`; Playwright and the visitor-path suite stay local. A Husky `pre-commit` hook runs `scripts/format-staged.sh` so Prettier fixes staged files before the commit lands. `pnpm-workspace.yaml` sets `minimumReleaseAge`, `trustPolicy: no-downgrade`, and `blockExoticSubdeps` so new or exotic npm packages cannot land immediately.
