<div align="center">

# nvim.setup

**Your editor. Your agents. One reproducible home.**

Gruvbox colors · transparent backgrounds · clickable pane tabs · macOS & Linux

</div>

```text
┌───────────────────┬───────────────────────────────────┬───────────────────┐
│ FILES             │ main.ts  utils.ts  +  ×           │ Codex 1 Agent 2 + │
│                   ├───────────────────────────────────┼───────────────────┤
│ src/              │                                   │                   │
│   main.ts         │          CODE EDITOR              │    CLI CHAT       │
│   utils.ts        │                                   │                   │
│ package.json      │   completion · LSP · debugging    │  independent      │
│                   │                                   │  running sessions │
│       25%         │                50%                │        25%        │
└───────────────────┴───────────────────────────────────┴───────────────────┘
```

The file tree opens automatically. Codex and Cursor Agent each start in a separate clickable chat tab. Focus stays in the editor. The sidebar is shared; file tabs and chat tabs switch independently. Gruvbox supplies the colors while your terminal supplies the background.

## Get going

Install Git and Make first, then clone **your copy of this repository**:

```bash
git clone https://github.com/YOUR-USER/nvim.setup.git ~/work/nvim.setup
cd ~/work/nvim.setup
make deps
make install
nvim .
```

Already have the prerequisites? Skip `make deps`. It installs system packages and may request sudo on Linux. Close existing Neovim instances before replacing configuration or changing plugin versions.

`make install` checks prerequisites, backs up existing configuration, copies `nvim/` into your config directory, restores locked plugins, installs syntax parsers and Mason tools, then validates the result. Installation needs internet access. CLI login and credentials stay outside this repo.

### Requirements

| Dependency | Purpose |
| --- | --- |
| Neovim **0.12+** | Current Tree-sitter plugin branch and editor APIs |
| Tree-sitter CLI **0.26.1+** | Build syntax parsers; install through Homebrew/Cargo, not npm |
| Node.js **22+**, npm | Web language servers and debug adapter |
| Git, curl, tar, unzip | Download plugins and tools |
| C/C++ toolchain, Make | Build native parsers/tools |
| Go, Rust/Cargo | Go tools and parser CLI installation |
| Python 3 | Portable configuration copy and checks |
| ripgrep, fd, fzf | Project search and file picker |
| `codex`, `agent` (optional) | Interactive AI chats |

`make deps` supports Homebrew on macOS and apt, dnf, or pacman on Linux. On macOS, install [Homebrew](https://brew.sh) and the Xcode Command Line Tools first. On Linux, distro packages can be older than this setup requires: `make doctor` rejects incompatible versions. Install a current [Neovim release](https://github.com/neovim/neovim/releases), update Node with your preferred version manager, and run `cargo install --locked tree-sitter-cli` if needed. Restart your shell after updating PATH. On Debian/Ubuntu, the scripts provide an `fd` wrapper for `fdfind` in `~/.local/bin`.

Keep `~/.local/bin` and, when using Cargo, `~/.cargo/bin` on PATH. The terminal needs mouse support and true color. If Ctrl+S freezes your terminal, disable shell flow control with `stty -ixon` in your shell startup file.

Install and authenticate the chat CLIs separately using the official [Codex](https://github.com/openai/codex) and [Cursor CLI](https://cursor.com/docs/cli/overview) instructions. Missing CLIs produce a notice; the editor still works. No API keys, login sessions, approval overrides or shell aliases are bundled.

## Daily controls

| Shortcut / click | Action |
| --- | --- |
| **Ctrl+S** | Save; ask for a filename when needed |
| **Ctrl+T** | New file tab, or chat CLI selector when chat is focused |
| **Ctrl+W** | Close active pane tab; unsaved files are protected |
| **Ctrl+]** | New chat: choose Codex or Cursor Agent |
| **Click tab** | Switch files or running chat sessions |
| **+ / ×** | Add / close active tab |
| **‹ / ›** | Navigate overflowing tabs |
| **Ctrl+B** | Toggle sidebar |
| **Ctrl+P / Ctrl+F** | Find files / search project text |
| **Tab / Shift+Tab / Enter** | Completion / previous suggestion / accept |
| **Esc Esc** | Leave terminal input mode |
| **Ctrl+h/j/k/l** | Move between panes in normal mode |
| **Space a c / Space a u** | Toggle Codex / Cursor Agent pane |
| **Space f** | Format file |
| **gd / gr / K** | Definition / references / documentation |
| **F5 / Space d b** | Debug / toggle breakpoint |

Closing a chat tab stops its CLI. Switching tabs keeps its process alive. Use `:qa` to quit Neovim; running terminals may require explicit closure or `:qa!` once your files are saved. See [the editor guide](docs/EDITOR.md) for all bindings, language support and debugging details.

## One Makefile, the whole lifecycle

```bash
make help                         # List commands
make doctor                       # Check prerequisites
make install                      # Back up + deploy + plugins + tools + validation
make plugins                      # Restore plugin revisions from the installed lockfile
make parsers                      # Install/update configured syntax parsers
make tools                        # Install missing Mason packages
make validate                     # Check the installed setup
make check                        # Shell syntax + compile all Lua files
make update                       # Fast-forward from Git upstream, then install
make upgrade                      # Upgrade plugins, refresh parsers, validate, save lockfile
make capture                      # Export local config edits back to this repository
make bump VERSION=1.1.0            # Set the setup release version
```

### Save changes for your next machine

Prefer editing `nvim/` in this repository and running `make install`. If you edited your installed config instead:

```bash
make capture
git diff
make check
make validate
git add .
git commit -m "Customize editor setup"
git push
```

Capture exports only `init.lua`, `lua/`, `scripts/` and `lazy-lock.json`; it does not collect editor caches or CLI credentials. Review changes before committing.

### Update versus upgrade

**`make update`** refuses a dirty repository, pulls the configured upstream using fast-forward only, then deploys that checkout. Without an upstream, it reapplies the local checkout. It does not commit or push anything.

**`make upgrade`** intentionally advances plugin versions in your installed config and copies the new lockfile into this repo after validation. Review and commit that diff. It does not upgrade Neovim or already installed Mason tools. Use `:Mason` for tool updates; use your OS package manager for Neovim and other system dependencies. Go/Rust toolchains and project dependencies remain your responsibility.

**`VERSION`** identifies this setup's release, independently of Neovim's version. After a tested change:

```bash
make bump VERSION=1.1.0
git add .
git commit -m "Release setup 1.1.0"
git tag v1.1.0
git push --follow-tags
```

Plugin revisions are pinned in `nvim/lazy-lock.json`. Mason tool versions are not pinned. Parser revisions follow the pinned Tree-sitter plugin. Installing on another OS may download different native binaries.

## Backups and recovery

Configuration uses `${XDG_CONFIG_HOME:-~/.config}/${NVIM_APPNAME:-nvim}`. Backups live in `${XDG_STATE_HOME:-~/.local/state}/nvim.setup/backups/`, each containing the previous `config` directory. Symlinked configs are backed up as symlinks. Plugin binaries, caches and Mason tools stay in Neovim's standard data directories.

To restore a backup, close Neovim and move the current config aside before putting the backup back:

```bash
# Default paths; use your XDG paths if customized.
mv ~/.config/nvim ~/.config/nvim.before-restore
cp -R ~/.local/state/nvim.setup/backups/CHOOSE-BACKUP/config ~/.config/nvim
```

A failed download leaves the new config in place and retains the old backup. Fix the reported dependency/network error and rerun `make install`, or restore your backup. Earlier plugin versions can be reapplied using the corresponding Git commit and `make install`. Shared plugin data is not backed up.

For a completely separate preview installation:

```bash
NVIM_APPNAME=nvim-preview make install
NVIM_APPNAME=nvim-preview nvim .
```

This uses separate configuration, data and state directories, so plugins and tools will be downloaded again. Do not run installation using sudo; only `make deps` elevates individual system-package commands.

## Put it on GitHub

This folder is already a Git repository with an initial commit. Create an empty repository on GitHub, then connect and push it:

```bash
git remote add origin git@github.com:YOUR-USER/nvim.setup.git
git push -u origin main
```

Or, if GitHub CLI is configured:

```bash
gh repo create nvim.setup --private --source=. --remote=origin --push
```

No remote is created automatically.

## Inside the box

```text
nvim/                 Deployable Neovim configuration
  init.lua            Options and plugin specifications
  lazy-lock.json      Saved plugin revisions
  lua/config/         Agents, pane tabs, startup, appearance, LSP, debug, keys
  scripts/            Parser and Mason tool installers
scripts/              macOS/Linux install, update, capture and validation
  lua/                Headless plugin management and validation
docs/EDITOR.md        Full editor reference
docs/VALIDATION-HISTORY.md  Historical checks from the original machine
Makefile              Public commands
VERSION               Setup release version
```

Validation checks startup, keybindings, plugin modules, Mason packages, syntax parsers, Vim/Zsh highlighting and transparent highlight groups. Headless maintenance never starts chat CLIs. It does not test your authentication, project dependencies, every language-server operation or an actual Linux install unless run on Linux. For deeper troubleshooting, use `:checkhealth`, `:LspInfo`, `:MasonLog`, `:ConformInfo` and `:messages`.
