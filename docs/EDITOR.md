# Neovim setup

Appearance uses Gruvbox syntax colors with transparent backgrounds throughout the editor, file tree, menus, and chat panes. Visual selection, search matches, and the selected completion item keep a fill so they stay visible. The terminal palette stays unchanged. Colors live in `lua/config/appearance.lua`. File icons are in the Settings sidebar (`lua/config/settings.lua`). A single bottom bar (`lua/config/statusline.lua`) spans the tree, editor, and chat: a muted Gruvbox yellow NORMAL pill and faded red INSERT pill (VISUAL orange, REPLACE / TERMINAL red, COMMAND gold), git branch and hunk counts, the focused file (or Files / Git / chat session name) with a modified marker, LSP diagnostics (`E:` / `W:` / `I:` / `H:`), recording and debug flags, search match index, attached language servers, filetype, and cursor `line:col` plus TOP/BOT/percent. Encoding, line endings, and indent only appear when they are not the defaults (`utf-8`, Unix, two spaces). The Files tree and Git sidebar show a Devicon for each extension so you can tell `.ts` from `.rs` at a glance. Devicons keep their type colors; names stay the default foreground unless git marks them (yellow modified, green added or untracked, red deleted). Folders use nvim-tree folder glyphs, not file Devicons. Expand markers are `>` and `v`. The tree does not print the project path/`..` root label. `make install` installs Symbols Nerd Font and bakes those glyphs into a Regular face named **Monocraft Nerd Font** (Warp has no fallback list). Those icons occupy one terminal cell. If Warp’s font is Monocraft, that setting becomes Monocraft Nerd Font.

Run `nvim .` in a project. Interactive startup opens the file tree at 20% width. If this project has a saved session, editor tabs (including unsaved buffers) and AI chats resume by UUID; otherwise it starts one Codex and one Cursor Agent session. `nvim --clean` skips restore and save, so you get a blank editor plus two fresh chats without clobbering the last session. The chat pane also uses 25% width; keyboard focus stays in the editor. This works with `nvim`, `nvim .`, and `nvim file`. Headless maintenance does not launch chats.

Press `i` to edit, `Esc` for normal mode, and Ctrl+Q to quit (unsaved tabs are snapshotted and restored next time). Swap files are disabled; recovery is the project session, not `.swp`. The leader key is **Space**; press leader shortcuts as a sequence in normal mode (for example Space, then `g`, then `s`).

Also see [plugins and first-party modules](PLUGINS.md) and the [E2E test plan](E2E-TESTPLAN.md).

## Keybindings

Ctrl shortcuts in the first table work in **normal, insert, and terminal** modes unless noted. Ctrl+W replaces Vim’s window-command prefix; use Ctrl+h/j/k/l to move between windows and Space w s / Space w v to split.

### Global

| Keys | Action |
| --- | --- |
| Ctrl+S | Save (asks for a path if the buffer is unnamed) |
| Ctrl+Q / `:SessionQuit` | Quit and persist this project's editor tabs and chats |
| Ctrl+T | New editor tab, or CLI selector when focused on chat |
| Ctrl+W | Close the focused editor or chat tab (refuses unsaved files) |
| Ctrl+] / `:AgentSelect` | Choose a chat CLI (Codex, Cursor Agent, Gemini, Claude, OpenCode) |
| Ctrl+B / Space e | Toggle the file tree |
| Ctrl+G | Open the Git source-control sidebar |
| Ctrl+, / `:SetupSettings` | Open the Settings sidebar |
| Ctrl+P / Command+P / Space f f | Find project files (hidden files included; build dirs excluded); opens a new mid-editor tab, or focuses the existing tab for that file |
| Ctrl+F / Space f g | Search text in the project; results open as a mid-editor tab |
| Space f b | Switch open buffers |
| Space w | Save (`:write`) |
| Ctrl+h / j / k / l | Focus the window in that direction |
| Space w s / Space w v | Split below / split right |
| Esc Esc (terminal) | Leave terminal input (`Ctrl+\ Ctrl+N` also works) |
| Click a pane | Focus editor, tree, or chat; clicking a running chat starts typing |
| Right-click / Shift+F10 / `:ContextMenu` | Open actions for the clicked or focused tree item, Git item, or tab |

The context menu uses the item under the pointer, even when another item was selected. File and folder menus offer open/create, path, rename, delete, and refresh actions as applicable. Git file menus offer Check Diff, open, stage or unstage, copy path, and revert where applicable; section and commit-log menus offer their existing actions. Editor tabs offer focus, copy path, close, and close other tabs; chat tabs offer focus and close. Sidebar tab labels offer open and refresh. Enter or click runs a menu action; Esc or clicking elsewhere dismisses it. Delete and revert keep their confirmation prompts, and modified editor tabs still refuse to close without saving.

### Chat

| Keys | Action |
| --- | --- |
| Space a c / `:Codex` | Toggle the Codex pane |
| Space a u / `:CursorAgent` | Toggle the Cursor Agent pane |
| Space a g / `:Gemini` | Toggle the Gemini pane |
| Space a l / `:Claude` | Toggle the Claude pane |
| Space a o / `:OpenCode` | Toggle the OpenCode pane |
| Esc (in a chat) | Send Escape to that CLI (stop generation). Stays in terminal mode. |
| Ctrl+\ Ctrl+N | Leave terminal input without sending Esc to the CLI |

### Settings (Ctrl+,)

The Settings tab sits next to Files and Git. Your preferences persist in `stdpath('state')/nvim-setup/settings.json` (or `$E2E_DIR/settings.json` in tests). The shipped values remain the defaults. Appearance (icons, transparency, line numbers), editing (indent width, scroll margin, clipboard), search case, and session restore can be changed here. Enter or click a row to toggle or cycle its value; `x` restores its default. **[Reload config]** re-reads saved preferences without quitting. Session restore changes take effect on the next launch. `q` returns to Files.

| Keys | Action |
| --- | --- |
| Enter / click | Toggle the row under the cursor |
| `r` | Reload saved settings |
| `x` | Reset the selected setting to its shipped default |
| `q` | Return to Files |
| Click **Settings** | Open Settings, or focus it if it is already showing |

### Extensions and command palette

Click **Extensions** or run `:SetupExtensions` to browse Mason packages in a marketplace-style sidebar. The search field stays at the top: press `/` or Enter on it, type a name, category, or description, then press Enter. Each result shows its name, description, category, and install status; Enter or click a card to install or uninstall. Below the results are installed packages and the existing actions to search GitHub repositories, add a GitHub `owner/repository`, open Mason's full manager, refresh the Mason registry, install a Tree-sitter parser, and reload Neovim. User plugin choices are stored in `stdpath('state')/nvim-setup/extensions.json`, apart from the shipped Lazy plugin list and lockfile. A new plugin is installed and loaded when Neovim starts again; **[Reload Neovim]** saves the project session and uses `:restart` where available. `q` returns to Files.

`:CommandPalette` opens searchable quick actions for file search, save, format, diagnostics, Git, Settings, Extensions, and common appearance settings. Space p is its terminal-safe shortcut; Ctrl+Shift+P is also mapped where the terminal forwards it.

### Git source control (Ctrl+G)

The Git view matches a typical source-control panel: commit message, **[Commit]**, **[Check Diff]**, **Staged Changes**, **Changes**, and a **COMMITS** log pane at the bottom (30% of the window height) showing recent `git log --graph --oneline` history. Clicking **Git** (or focusing the Git sidebar from another pane) reloads status and history. Every action has a key. Red is deleted, yellow is modified, green is added or untracked. Each changed file shows a Devicon for its type or extension; the icon keeps its type color and the filename follows git status.

| Keys | Action |
| --- | --- |
| `i` / Tab | Edit the commit message / cycle message, file list, and commit log |
| `C` / Ctrl+Enter | Commit staged changes (empty message is rejected; nothing staged asks to stage all) |
| Enter | Open a file or commit in the mid editor, toggle a section, or run the button under the cursor |
| `s` / `u` / `x` | Stage / unstage / revert the file (`x` asks first) |
| `S` / `U` / `X` | Stage all / unstage all / revert all |
| `r` / `q` | Refresh / return to Files |
| `d` / **[Check Diff]** | Open the selected file's Git diff in the existing editor pane; the button uses the first changed file when none is selected |
| **[Close Diff]** | Close the diff tab and restore the previous editor tab |
| Click **Git** | Open Git, or refresh if it is already showing |
| Click `+` / `−` / `x` | Stage / unstage / revert that file |
| Click **[Commit]** / **[Stage All]** / **[Unstage All]** / **[Revert All]** | Same as the matching key |

While a diff is open, clicking a staged or unstaged file in the sidebar updates that editor tab. Staged diffs compare the index with HEAD; unstaged diffs compare saved working files with the index. Untracked and deleted files can be previewed. Unsaved editor changes are not part of Git's diff, so the preview asks you to save first. The diff never creates another split or replaces the chat pane. Space g s still opens Fugitive for the full Git status UI in the mid editor. Files and commits from the Git sidebar also reuse that pane; they do not create extra splits. `:q` on the last editor window keeps the pane and leaves a tab (a blank one if none remain).

| Keys | Action |
| --- | --- |
| Space g s | Git status in the mid editor |
| Space g b | Git blame in the mid editor |
| Space g l | Git history in the mid editor (oneline log) |
| Space g d | Git diff split of the mid editor |
| Space g p | Preview hunk (gitsigns) |
| Space h s | Stage hunk (gitsigns) |

### Language (when a server is attached)

| Keys | Action |
| --- | --- |
| gd / gr / K | Definition / references / documentation |
| Space r n / Space c a | Rename / code action |
| Space d s | Document symbols |
| Ctrl+k (insert) | Signature help |
| Space f | Format the current file (not on save) |
| Space x x / Space x d | Project diagnostics (Trouble) / line diagnostic float |
| Ctrl+Space | Trigger completion |
| Tab / Shift+Tab | Next / previous completion (or indent / snippet jump) |
| Enter | Confirm the selected completion (does not auto-select) |
| Ctrl+E | Dismiss completion |

### Debug

| Keys | Action |
| --- | --- |
| F5 | Continue / start |
| F10 / F11 / F12 | Step over / into / out (Mac may need Fn) |
| Space d b | Toggle breakpoint |
| Space d u | Toggle debugger UI |
| Space d q | Stop debugging |
| `:DebugLoadLaunch` | Load `.vscode/launch.json` |

### Commands

| Command | Action |
| --- | --- |
| `:GitChanges` | Open Git source control |
| `:SetupSettings` | Open the Settings sidebar |
| `:SetupExtensions` | Open the Extensions sidebar |
| `:CommandPalette` | Search quick actions |
| `:SidebarFilesToggle` | Toggle the file tree |
| `:PaneSave` / `:PaneNewTab` / `:ProjectCloseTab` | Save / new tab / close tab |
| `:FindProjectFiles` / `:FindProjectText` | Find files / search project text (same as Ctrl+P / Ctrl+F) |
| `:SessionQuit` | Save session and quit |
| `:Codex` / `:CursorAgent` / `:Gemini` / `:Claude` / `:OpenCode` / `:AgentSelect` | Chat pane |
| `:qa` | Neovim's usual quit prompt (does not snapshot like Ctrl+Q) |

Closing a chat tab stops that CLI. When the CLI process exits (for example Ctrl+C in Cursor Agent), that chat tab closes too: another session is shown if any remain, otherwise the pane closes. If an `(exited)` leftover remains, click it or press Ctrl+W / × to close it. Closing the last editor tab, or `:q` in the last editor window, leaves a blank editor tab so the mid pane stays. Ctrl+Q writes the project session and quits even with unsaved buffers.

## Language support

TypeScript/JavaScript/React/Node/Bun use vtsls; Vue uses vtsls plus vue_ls; Svelte uses its own server. Rust, Go, Solidity, TOML, JSON, YAML, HTML, CSS, Tailwind, ESLint and Lua servers are installed through Mason. Servers start for relevant files/projects. Completion, hover, definition, references, rename, diagnostics and code actions depend on what each server supports.

Install project dependencies normally. React needs `@types/react` (and usually `@types/react-dom`); Node needs `@types/node`; Bun needs `@types/bun`. Keep a project tsconfig.json. Framework projects should retain their generated TypeScript configs and local framework dependencies. Vue defaults target Vue 3. ESLint and Tailwind require their project configuration/dependencies. Rust uses rust-analyzer and Clippy, Go uses gopls, Solidity uses Nomic Foundation's server and project compiler configuration.

Formatting is explicit (Space f). Prettierd handles web files (JS/TS/Vue/Svelte/HTML/CSS/JSON/YAML/Markdown); Svelte projects need `prettier` and `prettier-plugin-svelte` configured locally. Lua uses StyLua (Prettier’s Lua plugin is unmaintained). Shell uses shfmt, TOML Taplo, Rust rustfmt, Go gofmt; other files fall back to server formatting where available. Check `:ConformInfo` for formatter details. The repo pre-commit hook runs Prettier (with `prettier-plugin-packagejson`, `prettier-plugin-sh`, and Tailwind class sorting) plus StyLua on staged Lua.

Tab in insert mode opens completion after text, cycles and inserts suggestions when the menu is open, jumps through snippet fields, and indents on blank space. Enter confirms the selected suggestion; Ctrl+E dismisses the menu. Vimscript and Zsh use their dedicated Tree-sitter parsers, with built-in syntax as a fallback.

## Chat panes

The sidebar has **Files**, **Git**, **Settings**, and **Extensions** tabs. Git loads changes in the background, so you can switch back to Files while it loads.

Click pane contents to focus the editor, tree, or chat; clicking a running chat enables terminal input. The editor and chat panes each have their own clickable tabs above their contents, laid out as `icon name × │ icon name × │ + │`. Click a label to switch, **×** on that tab to close it, or **+** to add. File tabs show the same colored Devicon as the Files tree; chat tabs stay text-only. Labels use the same `│` as the pane splits. The tab bar stays transparent like the rest of the UI; the active label is muted gold and bold. **‹ / ›** navigate when tabs overflow. Ctrl+T adds a tab in the focused pane; Ctrl+W closes the current file or chat. File tabs show listed editor buffers and preserve unsaved edits when switching. The Files / Git / Settings sidebar tabs use that divider too.

Chat **+** and Ctrl+] open a CLI selector for a new independent Codex, Cursor Agent, Gemini, Claude, or OpenCode session. Multiple sessions of any CLI can run at once. Switching chat tabs preserves running sessions; closing a chat tab stops that session. If the CLI itself exits, the tab closes the same way. Space a c / a u / a g / a l / a o toggle the Codex, Cursor Agent, Gemini, Claude, and OpenCode panes. The file tree uses 20% of the editor width and the chat pane uses 25%. Chats run the actual interactive CLIs in the directory where you opened them. They use existing CLI authentication and permissions; no prompts or approval bypasses are injected. Use `codex login`, `agent login`, `gemini`, `claude`, or `opencode` outside Neovim if login expires. They do not automatically receive editor selections: mention project-relative file paths in chat. Sessions are stored per working directory under Neovim state (`nvim-setup-sessions`). Resume is `codex resume <uuid>`, `agent --resume=<uuid>`, `gemini --resume <uuid>`, `claude --resume <uuid>`, and `opencode --session <id>`. Reopen Neovim in a different project for a separate context, or start `nvim --clean` for a blank window in the current project.

## Debugging

F5 offers Node launch/attach and Chrome attach for web files, Delve for Go, and CodeLLDB for Rust. Build Rust first with `cargo build`, then choose the executable under target/debug. Node attach requires a process started with `node --inspect`; Chrome attach requires Chrome launched separately with `--remote-debugging-port=9222` and a separate user data directory. TypeScript Node launch needs compiled JS/source maps or a project-specific runtime setup. Bun's inspector differs from Node's: the Node debug profile is for Node; use Bun's inspector separately. Browser source maps and dev-server URLs/paths are project-specific. Solidity debugging is not configured.

For custom debug commands use a project `.vscode/launch.json`, then `:DebugLoadLaunch`. Use supported nvim-dap adapter types (`pwa-node`, `pwa-chrome`, `go`, `codelldb`).

## Command+P on macOS

Both `<D-p>` (Command+P) and Ctrl+P are mapped in Neovim. The terminal must forward Command+P. [Warp's current custom keybindings](https://github.com/warpdotdev/warp/issues/14300) expose built-in actions, with no supported send-text mapping; use Ctrl+P or Space f f in Warp. In a terminal with send-text keybindings, map Command+P to byte `0x10` (Ctrl+P). Icon-font install may set Warp’s `font_name` from Monocraft to Monocraft Nerd Font and installs a face with that family name (Nerd Font glyphs baked in at one cell). Other Warp settings are left alone. Restart Warp after that so the new face loads.

## Maintenance

1. Update Neovim/search tools: `brew update && brew upgrade neovim ripgrep fd fzf tree-sitter-cli bun`.
2. In Neovim run `:Lazy sync` to update plugins, then `:TSUpdate` to update syntax parsers. Restart Neovim.
3. Run `:Mason` and press `U` to update installed language servers/debuggers/formatters. `:MasonLog` explains failed installs.
4. Diagnose issues with `:checkhealth`, `:LspInfo`, `:ConformInfo`, `:messages`, and `:DapShowLog`.

Configuration: `~/.config/nvim/init.lua`, with language/agent/debug/key settings in `lua/config/`. `lazy-lock.json` records plugin revisions; back up this whole directory before updates. To restore plugin versions from a saved lockfile, restore it and run `:Lazy restore`. Mason tool versions are maintained separately.

To reinstall configured tools: `make tools` from the setup repository.

See [validation history](VALIDATION-HISTORY.md) for installation checks and their scope.
