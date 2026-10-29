# nvim.setup

A portable Neovim config that puts your files, editor, and AI chats in one window.

Codex and Cursor Agent run as real CLI sessions next to your code. Language servers, formatters, and debuggers come with the install. Gruvbox colors sit on a transparent UI, so your terminal keeps the background.

```text
┌──────────────┬────────────────────────────────┬─────────────────┐
│ Files        │  main.ts   utils.ts   +   ×    │ Codex 1  Agent 2│
│              ├────────────────────────────────┼─────────────────┤
│ src/         │                                │                 │
│   main.ts    │           Editor               │    CLI chat     │
│   utils.ts   │                                │                 │
│              │     LSP · format · debug       │  independent    │
│     25%      │              50%               │      25%        │
└──────────────┴────────────────────────────────┴─────────────────┘
```

The file tree and chat pane each take 25% of the window. Focus stays in the editor. Click a pane to focus it; click a running chat to type into it. Click tabs to switch files or sessions without stopping them.

This is a complete setup, not a plugin. `make install` replaces your Neovim config after backing it up.

## Features

- Clickable file tree, editor tabs, and chat tabs
- Independent Codex and Cursor Agent sessions (your login, your permissions)
- TypeScript, JavaScript, React, Vue, Svelte, Rust, Go, Solidity, Lua, HTML, CSS, JSON, YAML, TOML
- Completion, diagnostics, go-to-definition, format-on-demand, Git, and debugging
- Pinned plugins, a lockfile, and Makefile commands for install, capture, update, and validation

## Install

Needs Git and Make. On macOS, install [Homebrew](https://brew.sh) and the Xcode Command Line Tools first.

```sh
git clone https://github.com/LFSCamargo/nvim.setup.git
cd nvim.setup
make deps        # optional if the requirements below are already installed
make install
nvim .
```

Fork the repo and clone your fork if you want a copy you can customize.

`make deps` installs system packages with Homebrew on macOS, or apt, dnf, or pacman on Linux (sudo may be required on Linux). Distro packages can be older than this setup needs; `make doctor` reports incompatible versions.

`make install` checks prerequisites, backs up the existing config, copies `nvim/`, restores pinned plugins, installs parsers and Mason tools, then validates. It needs internet access. Close other Neovim instances first, and do not run it with sudo.

To try this without replacing `~/.config/nvim`:

```sh
NVIM_APPNAME=nvim-preview make install
NVIM_APPNAME=nvim-preview nvim .
```

That preview uses its own config, data, and state directories, so plugins and tools download again.

### Requirements

| Dependency | Purpose |
| --- | --- |
| Neovim 0.12+ | Editor and current Tree-sitter APIs |
| Tree-sitter CLI 0.26.1+ | Parser builds (Homebrew or Cargo, not npm) |
| Node.js 22+ and npm | Web language servers and the debug adapter |
| Git, curl, tar, unzip, Python 3 | Downloads, installation, and checks |
| C/C++ toolchain and Make | Native builds |
| Go and Rust/Cargo | Go tools and the parser CLI |
| ripgrep, fd, fzf | Search and file picking |
| `codex` and `agent` | Optional chat CLIs |

Keep `~/.local/bin` on your PATH, and `~/.cargo/bin` if you use Cargo. The terminal needs true color and mouse support. On Debian/Ubuntu, the scripts add an `fd` wrapper for `fdfind`. If Ctrl+S freezes the terminal, add `stty -ixon` to your shell startup file.

Install and authenticate the chat CLIs separately with the [Codex](https://github.com/openai/codex) and [Cursor CLI](https://cursor.com/docs/cli/overview) docs. Missing CLIs print a notice; the editor still works. Credentials and CLI permissions stay outside this repository.

## Using the editor

Open a project with `nvim .`, or a file with `nvim path/to/file`. Press `i` to insert, `Esc` for normal mode, and `:qa` to quit. The leader key is **Space**; press leader shortcuts as a sequence in normal mode.

| Shortcut or click | Action |
| --- | --- |
| Click a pane | Focus the editor, file tree, or chat |
| Click a tab, `+`, or `×` | Switch, add, or close a file or chat tab |
| `‹` / `›` | Scroll overflowing tabs |
| Ctrl+S | Save (asks for a name if the buffer is unnamed) |
| Ctrl+T / Ctrl+W | Add / close a tab in the focused pane |
| Ctrl+] | Start a new Codex or Cursor Agent session |
| Ctrl+B | Toggle the file tree |
| Ctrl+P / Ctrl+F | Find files / search project text |
| Esc | Send Escape to the focused agent (stop generation, for example) |
| Ctrl+\ Ctrl+N | Leave terminal-input mode (`Esc Esc` also works in other terminals) |
| Ctrl+h/j/k/l | Move between windows in normal mode |
| Space a c / Space a u | Toggle Codex / Cursor Agent |
| Space f | Format the current file |
| gd / gr / K | Definition / references / documentation |
| F5 / Space d b | Start or continue debugging / toggle a breakpoint |

Closing a chat tab stops that CLI. Switching tabs leaves it running. Unsaved files are protected when you close a tab. Running terminals may need an explicit close or `:qa!` after you save.

The full shortcut list, language notes, and debugging details live in [the editor guide](docs/EDITOR.md).

## Languages, format, and debug

Mason installs the language servers and debug adapters. Format with **Space f** (not on save).

| Area | Tools |
| --- | --- |
| TypeScript / JavaScript / React / Vue | vtsls, vue_ls, prettierd |
| Svelte | svelte-language-server, prettierd (needs project Prettier + plugin) |
| Rust | rust-analyzer (Clippy), rustfmt, CodeLLDB |
| Go | gopls, gofmt, Delve |
| Solidity | Nomic Foundation language server |
| Web / config | HTML, CSS, Tailwind, ESLint, JSON, YAML, TOML (Taplo), Lua |
| Debug | Node launch/attach, Chrome attach, Delve, CodeLLDB |

Install project dependencies as usual (`@types/*`, a `tsconfig.json`, ESLint/Tailwind/Prettier config). Custom debug configs can live in `.vscode/launch.json`; load them with `:DebugLoadLaunch`.

## Maintenance

Run these from the repository:

| Command | Purpose |
| --- | --- |
| `make help` | List commands |
| `make doctor` | Check prerequisites |
| `make install` | Back up, deploy, restore plugins, install parsers and tools, validate |
| `make check` | Check shell syntax and compile every Lua file |
| `make validate` | Validate the installed setup |
| `make plugins` / `make parsers` / `make tools` | Restore pinned plugins / install parsers / install missing Mason tools |
| `make update` | Fast-forward from the configured upstream, then install |
| `make upgrade` | Upgrade plugins, refresh parsers, validate, and save the lockfile |
| `make capture` | Copy installed config changes back into this repository |
| `make bump VERSION=1.1.0` | Set this setup's release version |
| `make commitlint` | Check the latest commit message against Conventional Commits |

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

Use `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert`. After `npm install` in this repository, a `commit-msg` hook rejects messages that do not match.

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

| Path | Contents |
| --- | --- |
| `nvim/` | Deployable config, plugin lockfile, and tool installers |
| `scripts/` | Install, update, capture, and validation |
| `docs/EDITOR.md` | Editor, language, and debug reference |
| `docs/VALIDATION.md` | What the packaging checks cover |
| `Makefile` / `VERSION` | Maintenance commands and the setup release version |
| `commitlint.config.mjs` | Conventional Commits rules for `git commit` |

Validation checks startup, mappings, plugin modules, Mason packages, syntax parsers, highlighting, and transparency. Headless maintenance does not start chats. It does not verify CLI login, project dependencies, or every language-server operation.

If something looks off after install, start with `:checkhealth`, `:LspInfo`, `:MasonLog`, `:ConformInfo`, and `:messages`.
