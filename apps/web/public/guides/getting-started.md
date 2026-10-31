# Get started

This setup is a complete Neovim workspace, not a plugin. Files, the editor, Git, language tools, and optional AI chats live in one window. You do not need to clone the repo first. The installer backs up your current config, then replaces it.

## What you need

macOS or Linux, and internet access. The installer installs Neovim, Node, Git, and the rest if they are missing. Linux may ask for sudo for system packages.

| Dependency                                              | Purpose                                    |
| ------------------------------------------------------- | ------------------------------------------ |
| Neovim 0.12+                                            | Editor and current Tree-sitter APIs        |
| Tree-sitter CLI 0.26.1+                                 | Parser builds (Homebrew or Cargo, not npm) |
| Node.js 22+ and npm                                     | Web language servers and the debug adapter |
| Git, curl, tar, unzip, Python 3                         | Downloads, installation, and checks        |
| C/C++ toolchain and Make                                | Native builds                              |
| Go and Rust/Cargo                                       | Go tools and the parser CLI                |
| ripgrep, fd, fzf                                        | Search and file picking                    |
| `codex`, `agent`, `gemini`, `claude`, `opencode`, `agy` | Optional chat CLIs                         |

Keep `~/.local/bin` on your PATH, and `~/.cargo/bin` if you use Cargo. The terminal needs true color and mouse support. If Ctrl+S freezes the terminal, add `stty -ixon` to your shell startup file.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash
nvim .
```

Do not pipe that command to sudo. Close other Neovim instances first. The script clones into `~/.local/share/nvim.setup`, installs missing tools (including Neovim 0.12+ and Node 22+), deploys the config, and installs the Nerd Font files used by the Files and Git Devicons. Distro packages can be older than this setup needs; the installer fetches current binaries when it has to. Restart the terminal once so those fonts load.

Fork the repo if you want a copy you can customize, then run `./scripts/bootstrap.sh` from the checkout.

## Try it without replacing your config

```sh
curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash -s -- --preview
NVIM_APPNAME=nvim-preview nvim .
```

Preview uses separate config, data, and state directories, so plugins and tools download again. Your existing Neovim setup stays in place.

## First minutes

Open a project with `nvim .`, or a file with `nvim path/to/file`. Press `i` to insert, `Esc` for normal mode, and Ctrl+Q to quit (unsaved tabs come back next time). The leader key is **Space**.

| Do this         | What happens                                                                      |
| --------------- | --------------------------------------------------------------------------------- |
| Click a pane    | Focus the editor, file tree, or chat                                              |
| Ctrl+B          | Toggle the file tree                                                              |
| Ctrl+G          | Open Git source control                                                           |
| Ctrl+,          | Open Settings (icons, live reload)                                                |
| Ctrl+P / Ctrl+F | Find files / search project text (new editor tab)                                 |
| Ctrl+]          | Start a new Codex, Cursor Agent, Gemini, Claude, OpenCode, or Antigravity session |
| Space f         | Format the current file                                                           |
| gd / gr / K     | Definition / references / documentation                                           |

Install and authenticate the chat CLIs separately: [Codex](https://github.com/openai/codex), [Cursor CLI](https://cursor.com/docs/cli/overview), [Gemini CLI](https://geminicli.com/docs/get-started/installation/), [Claude Code](https://code.claude.com/docs/en/setup), [OpenCode](https://opencode.ai/docs/cli/), and [Antigravity CLI](https://antigravity.google/docs/cli/commands/resume/). Missing CLIs print a notice; the editor still works. Credentials stay outside this repository.

If something looks off after install, start with `:checkhealth`, `:LspInfo`, `:MasonLog`, `:ConformInfo`, and `:messages`.

To change the setup itself, see [Contributing](https://github.com/LFSCamargo/nvim.setup/blob/main/CONTRIBUTING.md) and the [first-change tutorial](https://github.com/LFSCamargo/nvim.setup/blob/main/docs/TUTORIAL.md).
