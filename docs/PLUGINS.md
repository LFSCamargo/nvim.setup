# Plugins and first-party modules

This setup is not one plugin. It is our Neovim config plus pinned third-party plugins, Mason tools, and Tree-sitter parsers. Use this list when adding or removing pieces; keep it in sync with `nvim/init.lua`, `nvim/lua/config/`, and `nvim/lua/config/tooling.lua`.

## First-party (this repository)

Code we wrote. These live under `nvim/lua/config/` and `scripts/`. They are not Lazy plugins.

| Module       | Path                               | What it does                                                                                                     |
| ------------ | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Agents       | `nvim/lua/config/agents.lua`       | Chat CLI panes (Codex, Cursor Agent, Gemini, Claude, OpenCode), ID resume, Esc, close tab on exit                |
| Session      | `nvim/lua/config/session.lua`      | Per-project tabs, unsaved snapshots, chat UUIDs, Ctrl+Q, `NVIM_CLEAN`; swap files off                            |
| Sidebar      | `nvim/lua/config/sidebar.lua`      | Files / Git / Settings / Extensions panel; Files names stay white unless git-dirty; composer, stage, commit, log |
| Diff         | `nvim/lua/config/diff.lua`         | Read-only staged and unstaged Git diffs in the editor pane, selected from the Git sidebar                        |
| Context menu | `nvim/lua/config/context_menu.lua` | Shared right-click and keyboard menu for Files, Git, editor/chat tabs, and sidebar tabs                          |
| Settings     | `nvim/lua/config/settings.lua`     | User preferences, shipped defaults, live reload, and Settings sidebar tab                                        |
| Extensions   | `nvim/lua/config/extensions.lua`   | User plugin manifest, suggested plugin browser, Mason/Tree-sitter access, Extensions sidebar tab                 |
| Palette      | `nvim/lua/config/palette.lua`      | Searchable quick actions for coding and configuration                                                            |
| Keys         | `nvim/lua/config/keys.lua`         | Global and leader maps, Ctrl shortcuts, user commands                                                            |
| Tabs         | `nvim/lua/config/tabs.lua`         | Clickable editor/chat winbar tabs; colored Devicons on file tabs; transparent bar; Ctrl+P opens here             |
| LSP          | `nvim/lua/config/lsp.lua`          | Server configs and buffer-local LSP keys                                                                         |
| DAP          | `nvim/lua/config/dap.lua`          | Debug adapters and `:DebugLoadLaunch`                                                                            |
| Appearance   | `nvim/lua/config/appearance.lua`   | Gruvbox transparency; selection fills stay visible                                                               |
| Statusline   | `nvim/lua/config/statusline.lua`   | Global muted Gruvbox bar: mode, git, file, diagnostics, LSP, search, cursor                                      |
| Startup      | `nvim/lua/config/startup.lua`      | Interactive layout: tree, editor focus, restore or default chats                                                 |
| Icons        | `nvim/lua/config/icons.lua`        | Colored Devicons for Files/Git glyphs; names stay white unless git-dirty; toggled from Settings                  |
| Format       | `nvim/lua/config/format.lua`       | Conform formatters: StyLua, prettierd, shfmt, Taplo, rustfmt, gofmt                                              |
| Tooling      | `nvim/lua/config/tooling.lua`      | Mason package list and Tree-sitter parser list                                                                   |
| Wrapper      | `scripts/nvim-wrapper.sh`          | `nvim --clean` loads this config without restoring a session                                                     |
| Bootstrap    | `scripts/bootstrap.sh`             | One-shot installer: fetch the repo, deps, icon fonts, then the Neovim config                                     |
| Fonts        | `scripts/fonts.sh`                 | Symbols Nerd Font and a Monocraft Nerd Font face with those glyphs baked in at one cell                          |

`nvim/init.lua` is the entry point (options, Lazy, then the modules above). Do not grow it; put new behavior in a single-purpose config module.

## Installed Neovim plugins (Lazy)

Pinned in `nvim/lazy-lock.json`. Restored by `make plugins`. Declared in `nvim/init.lua`.

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

The Files tree and Git sidebar use [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons). `make install` / `scripts/bootstrap.sh` runs `scripts/fonts.sh`, which installs [Symbols Nerd Font](https://github.com/ryanoasis/nerd-fonts) and a Regular [Monocraft](https://github.com/IdreesInc/Monocraft) face named **Monocraft Nerd Font** into the user font directory (`~/Library/Fonts` on macOS, `~/.local/share/fonts/nvim-setup` on Linux). That face has Nerd Font glyphs baked in at one cell (Warp has no fallback list). If Warp’s terminal font is Monocraft, that setting becomes **Monocraft Nerd Font**. Kitty and Ghostty configs that already exist get fallback/`symbol_map` lines.

## Mason tools (installed binaries)

Listed in `config.tooling.packages`. Installed by `make tools`. Versions are not pinned in the lockfile.

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

Listed in `config.tooling.parsers`. Installed by `make parsers`.

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

## Marketing application

`apps/web` is a separate TypeScript React/Vite application with Tailwind CSS, managed by the pnpm workspace and Nx. It does not add Neovim plugins or change the installed editor. Root `project.json` exposes the existing setup checks as the Nx `setup` project; the web package is the `web` project. Website dependencies and Aceternity UI adaptations are declared in `apps/web/package.json` and `apps/web/THIRD-PARTY-NOTICES.md`. The `/docs` reader loads static markdown from `apps/web/public/guides/` (repo guides are copied there at `vite` start/build). Fenced samples render through `apps/web/src/components/code-block.tsx` (copy, line numbers, wrapping). Titles, canonicals, Open Graph/Twitter tags, and JSON-LD come from `apps/web/src/lib/seo.ts`; crawlers also get `apps/web/public/robots.txt` and `apps/web/public/sitemap.xml` (raw `/guides/*.md` copies are disallowed so they do not compete with `/docs`). A refresh on `/docs/:slug` is recovered by Vite `appType: 'spa'`, a copied `dist/404.html` shell, and `apps/web/public/_redirects`. Format the site with `pnpm format` (Prettier plus `prettier-plugin-tailwindcss`). `make scan` / `pnpm scan` is the OWASP barrier for that tree: Semgrep CE (`p/owasp-top-ten`, `p/javascript`, `p/typescript`, `p/react`, `p/security-audit`) plus `pnpm audit --audit-level=moderate`. CI runs Semgrep plus Prettier, TypeScript, and `pnpm build`; Playwright and the visitor-path suite stay local. A Husky `pre-commit` hook runs `scripts/format-staged.sh` so Prettier fixes staged files before the commit lands. `pnpm-workspace.yaml` sets `minimumReleaseAge`, `trustPolicy: no-downgrade`, and `blockExoticSubdeps` so new or exotic npm packages cannot land immediately.
