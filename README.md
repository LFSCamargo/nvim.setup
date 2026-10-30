# nvim.setup

A portable Neovim config that puts your files, editor, and AI chats in one window.

Codex, Cursor Agent, Gemini, Claude, and OpenCode run as real CLI sessions next to your code. Language servers, formatters, and debuggers come with the install. Gruvbox colors sit on a transparent UI, so your terminal keeps the background.

```text
┌──────────────┬────────────────────────────────┬─────────────────┐
│ Files        │  main.ts   utils.ts   +   ×    │ Codex 1  Agent 2│
│              ├────────────────────────────────┼─────────────────┤
│ src/         │                                │                 │
│   main.ts    │           Editor               │    CLI chat     │
│   utils.ts   │                                │                 │
│              │     LSP · format · debug       │  independent    │
│     20%      │              55%               │      25%        │
└──────────────┴────────────────────────────────┴─────────────────┘
```

The file tree takes 20% of the window and the chat pane takes 25%. Focus stays in the editor. Click a pane to focus it; click a running chat to type into it. Click tabs to switch files or sessions without stopping them.

This is a complete setup, not a plugin. `make install` replaces your Neovim config after backing it up.

## Features

- Clickable file tree, editor tabs, and chat tabs
- File-type Devicons in the Files tree and Git sidebar. Install puts Nerd Font files on the system and, in Warp, uses a Monocraft face with those glyphs at one cell.
- Per-project session restore for editor tabs, unsaved buffers, and AI chats (UUID resume)
- `nvim --clean` for a blank editor that does not restore or overwrite the last session
- Independent Codex, Cursor Agent, Gemini, Claude, and OpenCode sessions (your login, your permissions)
- TypeScript, JavaScript, React, Vue, Svelte, Rust, Go, Solidity, Lua, HTML, CSS, JSON, YAML, TOML
- Completion, diagnostics, go-to-definition, format-on-demand, Git, and debugging
- Pinned plugins, a lockfile, and Makefile commands for install, capture, update, and validation

## Install

You do not need to clone this repository first. One command fetches the setup, installs Neovim and the other dependencies if they are missing, installs icon fonts, then deploys the config.

```sh
curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash
nvim .
```

To try this without replacing `~/.config/nvim`:

```sh
curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash -s -- --preview
NVIM_APPNAME=nvim-preview nvim .
```

Do not pipe the installer to sudo. Close other Neovim instances first. Linux may ask for sudo only for system packages. On macOS, Homebrew and the Xcode Command Line Tools are installed when they are missing.

The script clones into `~/.local/share/nvim.setup` (override with `NVIM_SETUP_HOME`), adds `~/.local/bin` to your shell PATH, runs `make deps`, installs icon fonts (Symbols Nerd Font, Monocraft Nerd Font), then `make install`. Distro packages can be older than this setup needs; if Neovim is missing or below 0.12, or Node is below 22, the installer fetches a current binary into `~/.local/opt`. `make doctor` reports incompatible versions.

Fork the repo and clone your fork if you want a copy you can customize, then run `./scripts/bootstrap.sh` from that checkout (or `make bootstrap`).

```sh
git clone https://github.com/YOUR_USER/nvim.setup.git
cd nvim.setup
./scripts/bootstrap.sh
nvim .
```

`make install` alone still works from a checkout: it checks prerequisites, backs up the existing config, copies `nvim/`, installs icon fonts (Symbols Nerd Font, Monocraft Nerd Font), restores pinned plugins, installs parsers and Mason tools, then validates. It needs internet access. Restart the terminal once so new fonts load.

### Requirements

| Dependency                                       | Purpose                                    |
| ------------------------------------------------ | ------------------------------------------ |
| Neovim 0.12+                                     | Editor and current Tree-sitter APIs        |
| Tree-sitter CLI 0.26.1+                          | Parser builds (Homebrew or Cargo, not npm) |
| Node.js 22+ and npm                              | Web language servers and the debug adapter |
| Git, curl, tar, unzip, Python 3                  | Downloads, installation, and checks        |
| C/C++ toolchain and Make                         | Native builds                              |
| Go and Rust/Cargo                                | Go tools and the parser CLI                |
| ripgrep, fd, fzf                                 | Search and file picking                    |
| `codex`, `agent`, `gemini`, `claude`, `opencode` | Optional chat CLIs                         |

Keep `~/.local/bin` on your PATH, and `~/.cargo/bin` if you use Cargo. Install places an `nvim` wrapper there so `nvim --clean` opens this setup without restored tabs. The terminal needs true color and mouse support. On Debian/Ubuntu, the scripts add an `fd` wrapper for `fdfind`. If Ctrl+S freezes the terminal, add `stty -ixon` to your shell startup file.

Install and authenticate the chat CLIs separately: [Codex](https://github.com/openai/codex), [Cursor CLI](https://cursor.com/docs/cli/overview), [Gemini CLI](https://geminicli.com/docs/get-started/installation/), [Claude Code](https://code.claude.com/docs/en/setup), and [OpenCode](https://opencode.ai/docs/cli/). Missing CLIs print a notice; the editor still works. Credentials and CLI permissions stay outside this repository.

## Using the editor

Open a project with `nvim .`, or a file with `nvim path/to/file`. Press `i` to insert, `Esc` for normal mode, and Ctrl+Q to quit (unsaved tabs come back next time). `nvim --clean` skips restored tabs and chats. The leader key is **Space**; press leader shortcuts as a sequence in normal mode.

| Shortcut or click                 | Action                                                                                         |
| --------------------------------- | ---------------------------------------------------------------------------------------------- |
| Click a pane                      | Focus the editor, file tree, or chat                                                           |
| Click a tab, `+`, or `×`          | Switch, add, or close a file or chat tab                                                       |
| `‹` / `›`                         | Scroll overflowing tabs                                                                        |
| Ctrl+S                            | Save (asks for a name if the buffer is unnamed)                                                |
| Ctrl+Q                            | Quit and persist this project's tabs and chats                                                 |
| Ctrl+T / Ctrl+W                   | Add / close a tab in the focused pane                                                          |
| Ctrl+]                            | Start a new Codex, Cursor Agent, Gemini, Claude, or OpenCode session                           |
| Ctrl+B                            | Toggle the file tree                                                                           |
| Ctrl+G                            | Open Git source control (commit, stage, unstage, revert, bottom commit log; keyboard or mouse) |
| Ctrl+P / Ctrl+F                   | Find files / search project text (opens a new editor tab)                                      |
| Esc                               | Send Escape to the focused agent (stop generation, for example)                                |
| Ctrl+\ Ctrl+N                     | Leave terminal-input mode (`Esc Esc` also works in other terminals)                            |
| Ctrl+h/j/k/l                      | Move between windows in normal mode                                                            |
| Space a c / a u / a g / a l / a o | Toggle Codex / Cursor Agent / Gemini / Claude / OpenCode                                       |
| Space f                           | Format the current file                                                                        |
| gd / gr / K                       | Definition / references / documentation                                                        |
| F5 / Space d b                    | Start or continue debugging / toggle a breakpoint                                              |

Closing a chat tab stops that CLI. The tab also closes if the CLI process exits. Switching tabs leaves it running. Unsaved files are protected when you close a tab. Git files, commits, and Fugitive views open in the mid editor; `:q` there keeps that pane and a tab. Quitting with Ctrl+Q snapshots unsaved buffers and resumes chat CLIs by ID on the next launch in that directory. `make install` puts a wrapper at `~/.local/bin/nvim` so `nvim --clean` still loads this config. Maintenance scripts set `NVIM_WRAPPER=0` when they need Neovim's factory `--clean`.

The full keybinding list, language notes, and debugging details live in [the editor guide](docs/EDITOR.md). Plugins we wrote versus plugins and tools we install are in [the plugin overview](docs/PLUGINS.md). What `make e2e` covers — and what to add when behavior changes — is in [the E2E test plan](docs/E2E-TESTPLAN.md).

## Languages, format, and debug

Mason installs the language servers and debug adapters. Format with **Space f** (not on save).

| Area                                  | Tools                                                               |
| ------------------------------------- | ------------------------------------------------------------------- |
| TypeScript / JavaScript / React / Vue | vtsls, vue_ls, prettierd                                            |
| Svelte                                | svelte-language-server, prettierd (needs project Prettier + plugin) |
| Rust                                  | rust-analyzer (Clippy), rustfmt, CodeLLDB                           |
| Go                                    | gopls, gofmt, Delve                                                 |
| Solidity                              | Nomic Foundation language server                                    |
| Web / config                          | HTML, CSS, Tailwind, ESLint, JSON, YAML, TOML (Taplo), Lua          |
| Debug                                 | Node launch/attach, Chrome attach, Delve, CodeLLDB                  |

Install project dependencies as usual (`@types/*`, a `tsconfig.json`, ESLint/Tailwind/Prettier config). Custom debug configs can live in `.vscode/launch.json`; load them with `:DebugLoadLaunch`.

## Maintenance

Run these from the repository:

| Command                                        | Purpose                                                                                  |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `make help`                                    | List commands                                                                            |
| `make bootstrap`                               | Fetch the repo if needed, install Neovim and other deps, then install                    |
| `make doctor`                                  | Check prerequisites                                                                      |
| `make install`                                 | Back up, deploy, restore plugins, install icon fonts, parsers and tools, validate        |
| `make fonts`                                   | Install Nerd Font files for Files/Git Devicons (also runs from `make install`)           |
| `make check`                                   | Check shell syntax and compile every Lua file                                            |
| `make e2e`                                     | Simulated UI e2e (chat, session, Git sidebar); see [the test plan](docs/E2E-TESTPLAN.md) |
| `make test`                                    | Run `make check` then `make e2e`                                                         |
| `make validate`                                | Validate the installed setup                                                             |
| `make plugins` / `make parsers` / `make tools` | Restore pinned plugins / install parsers / install missing Mason tools                   |
| `make update`                                  | Fast-forward from the configured upstream, then install                                  |
| `make upgrade`                                 | Upgrade plugins, refresh parsers, validate, and save the lockfile                        |
| `make capture`                                 | Copy installed config changes back into this repository                                  |
| `make bump VERSION=1.1.0`                      | Set this setup's release version                                                         |
| `make commitlint`                              | Check the latest commit message against Conventional Commits                             |
| `make changelog`                               | Validate every commit and regenerate `CHANGELOG.md`                                      |

Prefer editing `nvim/` here and running `make install`. If you edited the installed config instead:

```sh
make capture
git diff
make check
make validate
```

Capture copies only `init.lua`, `lua/`, `scripts/`, and `lazy-lock.json`. It does not collect caches or credentials.

`make update` refuses a dirty repository and uses fast-forward-only Git pulls. With no upstream it reapplies the local checkout. `make upgrade` advances plugin revisions and copies the new lockfile here for review. Neither command commits or pushes.

Plugin versions are pinned in `nvim/lazy-lock.json`. Mason tool versions are not. Use `:Mason` for tool updates, and your package manager for Neovim and system dependencies.

### Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/). A type and subject are required; a scope is optional:

```text
feat: click a chat pane to start typing
fix(agents): send Escape to the focused session
docs: document the e2e check
```

Use `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert`. After `pnpm install` in this repository, a `commit-msg` hook rejects messages that do not match.

After each commit, run `make changelog`. If `CHANGELOG.md` changed, commit it as `chore(changelog): regenerate from commits` before pushing. A `pre-push` hook and CI fail when the file is stale. Regeneration commits are omitted from the changelog so that extra commit does not loop.

`make changelog` lints the full history with those rules and rewrites [CHANGELOG.md](CHANGELOG.md). Conventional commits are grouped by type; older messages without a type go under Other. Tagged `vX.Y.Z` releases become dated sections; untagged commits stay under Unreleased.

Cursor, Claude Code, and Codex follow [AGENTS.md](AGENTS.md). After code changes they write tests, check for spaghetti, run `make test`, review for vulnerabilities, and keep `docs/` in sync. Claude Code also reads [CLAUDE.md](CLAUDE.md); Cursor also loads `.cursor/rules/`.

## Backups and recovery

The installed config lives at `${XDG_CONFIG_HOME:-~/.config}/${NVIM_APPNAME:-nvim}`. Each install moves the previous config to `${XDG_STATE_HOME:-~/.local/state}/nvim.setup/backups/`. Symlinks stay symlinks. Plugin data, caches, and Mason tools are not included.

To restore a backup, close Neovim and move the current config aside first:

```sh
# Default paths; adjust if you use XDG_CONFIG_HOME or NVIM_APPNAME.
mv ~/.config/nvim ~/.config/nvim.before-restore
cp -R ~/.local/state/nvim.setup/backups/CHOOSE-BACKUP/config ~/.config/nvim
```

If a download fails, the new config stays installed and the backup is kept. Fix the reported issue and rerun `make install`, or restore the backup.

## Repository layout

| Path                      | Contents                                                            |
| ------------------------- | ------------------------------------------------------------------- |
| `nvim/`                   | Deployable config, plugin lockfile, and tool installers             |
| `.luarc.json`             | lua-language-server settings so `vim` is a known global             |
| `scripts/`                | Install, update, capture, and validation                            |
| `docs/EDITOR.md`          | Keybindings, language, chat, and debug reference                    |
| `docs/PLUGINS.md`         | First-party modules, Lazy plugins, Mason tools, parsers             |
| `docs/E2E-TESTPLAN.md`    | What `make e2e` covers and how to extend it                         |
| `docs/VALIDATION.md`      | What the packaging checks cover                                     |
| `Makefile` / `VERSION`    | Maintenance commands and the setup release version                  |
| `scripts/scan.sh`         | Semgrep OWASP SAST and moderate-or-higher npm audit                 |
| `commitlint.config.mjs`   | Conventional Commits rules for `git commit`                         |
| `CHANGELOG.md`            | Generated history from validated commits                            |
| `AGENTS.md` / `CLAUDE.md` | Shared instructions for Cursor, Claude Code, and Codex              |
| `.cursor/rules/`          | Cursor agent rules for tests, E2E, changelog commits, and docs sync |

Validation checks startup, mappings, plugin modules, Mason packages, syntax parsers, highlighting, and transparency. Headless maintenance does not start chats. It does not verify CLI login, project dependencies, or every language-server operation.

If something looks off after install, start with `:checkhealth`, `:LspInfo`, `:MasonLog`, `:ConformInfo`, and `:messages`.

## Website workspace

The marketing site lives in `apps/web` as a TypeScript React/Vite app with Tailwind CSS v4. Guides on `/docs` are static markdown under `apps/web/public/guides/`. Each public route sets a unique title, description, canonical, and Open Graph tags; `robots.txt` and `sitemap.xml` list those routes and hide the raw markdown copies. Refreshing a `/docs` URL still serves the app (`404.html` plus `_redirects`). Prettier (with the Tailwind class-sorting plugin) formats the website and related Node files. Nx runs tasks across the pnpm workspace; the existing Makefile remains the entry point for installing and maintaining Neovim. Node.js 22.12+ and pnpm 10.34.9 are needed to develop the website. npm is still required by the Neovim installer for Mason's Node-based tools.

```sh
pnpm install
pnpm dev                  # Nx → web development server
pnpm build                # Nx → production site in apps/web/dist
pnpm format               # Prettier + Tailwind class order
pnpm test:setup           # Nx → make test and workspace checks
pnpm test:web:e2e         # browser checks for the landing page
pnpm scan                 # Semgrep OWASP SAST + moderate-or-higher npm audit
```

`pnpm exec nx show projects` lists the projects. `pnpm exec nx run setup:check` and `pnpm exec nx run setup:e2e` run the existing shell/Lua and simulated Neovim UI checks. Setup tests are never served from Nx's cache. CI and Git hooks use pnpm; do not regenerate an npm lockfile.

`make scan` (or `pnpm scan`) runs Semgrep Community Edition against the JavaScript/TypeScript tree with the OWASP Top Ten, JavaScript, TypeScript, React, and security-audit rulesets, then `pnpm audit --audit-level=moderate`. Findings fail the command. CI runs Semgrep from `.github/workflows/semgrep.yml` (no Semgrep Cloud token) and Prettier, TypeScript, and the production build from `.github/workflows/ci.yml`. Website visitor-path and Playwright checks stay local (`pnpm --filter web test`, `pnpm test:web:e2e`). Local SAST uses `semgrep` on PATH, or the `semgrep/semgrep` Docker image. The workspace also waits seven days before installing newly published package versions (`minimumReleaseAge`) and refuses exotic transitive dependencies.
