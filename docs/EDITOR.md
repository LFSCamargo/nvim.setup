# Neovim setup

Appearance uses Gruvbox syntax colors with transparent backgrounds throughout the editor, file tree, menus, and chat panes. Visual selection, search matches, and the selected completion item keep a fill so they stay visible. The terminal palette stays unchanged. Settings are in `lua/config/appearance.lua`.

Run `nvim .` in a project. Interactive startup opens the file tree at 25% width. If this project has a saved session, editor tabs (including unsaved buffers) and AI chats resume by UUID; otherwise it starts one Codex and one Cursor Agent session. `nvim --clean` skips restore and save, so you get a blank editor plus two fresh chats without clobbering the last session. The chat pane also uses 25% width; keyboard focus stays in the editor. This works with `nvim`, `nvim .`, and `nvim file`. Headless maintenance does not launch chats. Press `i` to edit, `Esc` for normal mode, `:w` to save, and Ctrl+Q to quit (unsaved tabs are snapshotted and restored next time). The leader key is **Space**; press the following keys in sequence in normal mode.

| Keys | Action |
| --- | --- |
| Ctrl+B | Toggle file tree |
| Ctrl+G | Open the Git source-control sidebar |
| Ctrl+F | Search text in project folder |
| Ctrl+T | New editor tab, or CLI selector when focused on chat |
| Ctrl+W | Close focused editor/chat tab; protect unsaved files |
| Ctrl+Q | Quit and persist this project's editor tabs and chats |
| Ctrl+S | Save file (asks for a path for unnamed files) |
| Ctrl+] | Choose Codex or Cursor Agent |
| Ctrl+P / Space f f | Find project files (hidden files included, build/dependency directories excluded) |
| Space f g | Search text in project |
| Space f b | Switch open buffers |
| Space e | Toggle file tree; Enter opens a file |
| Space a c / `:Codex` | Toggle Codex CLI chat pane |
| Space a u / `:CursorAgent` | Toggle Cursor Agent CLI chat pane |
| Esc | Send Escape to the focused agent (for example, to stop output) |
| Ctrl+\ Ctrl+N | Leave terminal input mode; Esc Esc also works in other terminals |
| Ctrl+h/j/k/l | Move between windows; mouse clicks and border dragging also work |
| gd / gr / K | Definition / references / documentation |
| Space r n / Space c a | Rename / code action |
| Ctrl+Space / Tab / Shift+Tab / Enter | Trigger completion or indent / next suggestion / previous / accept selected item |
| Ctrl+k (insert mode) | Signature help |
| Space f | Format current file |
| Space x x / Space x d | Trouble diagnostics / line diagnostic |
| Space g s / Space g b / Space g l | Git status / blame / history |
| Space g d / Space g p / Space h s | Git diff / preview hunk / stage hunk |
| Space d b / F5 | Breakpoint / start or continue debugger |
| F10 / F11 / F12 | Step over / into / out (Mac may require Fn) |
| Space d u / Space d q | Toggle debug panels / terminate debug session |

These Ctrl shortcuts work in normal, insert, and terminal modes. Ctrl+W replaces Vim’s window-command prefix; use Ctrl+h/j/k/l to move between windows and Space w s / Space w v to split. Closing a chat tab stops its CLI. Closing the last editor tab leaves a blank editor. Ctrl+Q (or `:SessionQuit`) writes the project session and quits even with unsaved buffers; closing a tab with Ctrl+W still refuses unsaved files. Use `:qa` if you want Neovim’s usual modified-buffer prompt.

## Language support

TypeScript/JavaScript/React/Node/Bun use vtsls; Vue uses vtsls plus vue_ls; Svelte uses its own server. Rust, Go, Solidity, TOML, JSON, YAML, HTML, CSS, Tailwind, ESLint and Lua servers are installed through Mason. Servers start for relevant files/projects. Completion, hover, definition, references, rename, diagnostics and code actions depend on what each server supports.

Install project dependencies normally. React needs `@types/react` (and usually `@types/react-dom`); Node needs `@types/node`; Bun needs `@types/bun`. Keep a project tsconfig.json. Framework projects should retain their generated TypeScript configs and local framework dependencies. Vue defaults target Vue 3. ESLint and Tailwind require their project configuration/dependencies. Rust uses rust-analyzer and Clippy, Go uses gopls, Solidity uses Nomic Foundation's server and project compiler configuration.

Formatting is explicit (Space f). Prettierd handles web files; Svelte projects need `prettier` and `prettier-plugin-svelte` configured locally. TOML uses Taplo, Rust rustfmt, Go gofmt; other files fall back to server formatting where available. Check `:ConformInfo` for formatter details.

## Chat panes

The sidebar has **Files** and **Git** tabs. Git loads changes in the background, so you can switch back to Files while it loads. The Git view matches a typical source-control panel: a commit message at the top, **[Commit]**, then **Staged Changes** and **Changes**. Every action is on the keyboard (mouse still works). Red means deleted, yellow means modified, and green means added or untracked. Space g s opens the full Fugitive status view.

| Git sidebar | Action |
| --- | --- |
| `i` / Tab | Edit the commit message / jump to it |
| `C` / Ctrl+Enter | Commit staged changes |
| Enter | Open a file, toggle a section, or run **[Commit]** / **[Stage All]** / **[Unstage All]** / **[Revert All]** |
| `s` / `u` / `x` | Stage / unstage / revert the file (revert asks first) |
| `S` / `U` / `X` | Stage all / unstage all / revert all |
| `r` / `q` | Refresh / return to Files |

Click pane contents to focus the editor, tree, or chat; clicking a running chat enables terminal input. The editor and chat panes each have their own clickable tabs above their contents. Click a label to switch, **+** to add, or **×** to close the active tab. The active label is underlined in gold; **‹ / ›** navigate when tabs overflow. Ctrl+T adds a tab in the focused pane. File tabs show listed editor buffers and preserve unsaved edits when switching.

Chat **+** and Ctrl+] open a CLI selector for a new independent Codex or Cursor Agent session. Multiple sessions of either CLI can run at once. Switching chat tabs preserves running sessions; closing a chat tab stops that session. Space a c and Space a u toggle the corresponding assistant pane. The chat pane and file tree each use 25% of the editor width. Chats run the actual interactive CLIs in the directory where you opened them. They use existing CLI authentication and permissions; no prompts or approval bypasses are injected. Use `codex login` or `agent login` outside Neovim if login expires. They do not automatically receive editor selections: mention project-relative file paths in chat. Sessions are stored per working directory under Neovim state (`nvim-setup-sessions`); Codex resumes with `codex resume <uuid>` and Cursor Agent with `agent --resume=<uuid>`. Reopen Neovim in a different project for a separate context, or start `nvim --clean` for a blank window in the current project.

## Debugging

F5 offers Node launch/attach and Chrome attach for web files, Delve for Go, and CodeLLDB for Rust. Build Rust first with `cargo build`, then choose the executable under target/debug. Node attach requires a process started with `node --inspect`; Chrome attach requires Chrome launched separately with `--remote-debugging-port=9222` and a separate user data directory. TypeScript Node launch needs compiled JS/source maps or a project-specific runtime setup. Bun's inspector differs from Node's: the Node debug profile is for Node; use Bun's inspector separately. Browser source maps and dev-server URLs/paths are project-specific. Solidity debugging is not configured.

For custom debug commands use a project `.vscode/launch.json`, then `:DebugLoadLaunch`. Use supported nvim-dap adapter types (`pwa-node`, `pwa-chrome`, `go`, `codelldb`).

## Command+P on macOS

Both `<D-p>` (Command+P) and Ctrl+P are mapped in Neovim. The terminal must forward Command+P. [Warp's current custom keybindings](https://github.com/warpdotdev/warp/issues/14300) expose built-in actions, with no supported send-text mapping; use Ctrl+P or Space f f in Warp. In a terminal with send-text keybindings, map Command+P to byte `0x10` (Ctrl+P). No Warp settings were changed.

## Maintenance

1. Update Neovim/search tools: `brew update && brew upgrade neovim ripgrep fd fzf tree-sitter-cli bun`.
2. In Neovim run `:Lazy sync` to update plugins, then `:TSUpdate` to update syntax parsers. Restart Neovim.
3. Run `:Mason` and press `U` to update installed language servers/debuggers/formatters. `:MasonLog` explains failed installs.
4. Diagnose issues with `:checkhealth`, `:LspInfo`, `:ConformInfo`, `:messages`, and `:DapShowLog`.

Configuration: `~/.config/nvim/init.lua`, with language/agent/debug/key settings in `lua/config/`. `lazy-lock.json` records plugin revisions; back up this whole directory before updates. To restore plugin versions from a saved lockfile, restore it and run `:Lazy restore`. Mason tool versions are maintained separately.

To reinstall configured tools: `make tools` from the setup repository.

See [validation history](VALIDATION-HISTORY.md) for installation checks and their scope.

Tab in insert mode opens completion after text, cycles and inserts suggestions when the menu is open, jumps through snippet fields, and indents on blank space. Enter confirms the selected suggestion; Ctrl+E dismisses the menu. Vimscript and Zsh use their dedicated Tree-sitter parsers, with built-in syntax as a fallback.
