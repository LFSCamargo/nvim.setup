# The workspace

The window is three panes. The file tree takes **20%**. The editor takes the middle. Chat takes **25%**. Focus stays in the editor unless you click another pane.

```text
┌──────────────┬────────────────────────────────┬─────────────────┐
│ Files│Git│Set│  main.ts │ utils.ts │ + │ ×    │ Codex 1 │ Agent 2│
│              ├────────────────────────────────┼─────────────────┤
│ src/         │                                │                 │
│   main.ts    │           Editor               │    CLI chat     │
│   utils.ts   │                                │                 │
│              │     LSP · format · debug       │  independent    │
│     20%      │              55%               │      25%        │
└──────────────┴────────────────────────────────┴─────────────────┘
```

Click a pane to focus it. Click a running chat to type into it. Click tabs to switch files or sessions without stopping them.

## Files

The left sidebar is an nvim-tree file browser with a **Files** tab. Files show a Devicon for the type or extension. Names stay the default foreground unless git marks them (yellow modified, green added, red deleted). Folders use folder glyphs with `>` / `v` expand markers. The project path/`..` root label is hidden. Click a file to open it in the mid editor. Ctrl+B or Space e toggles the tree. Ctrl+P finds files (hidden files included; build directories excluded) and opens a new mid-editor tab, or focuses the tab if that file is already open. Ctrl+F searches project text the same way.

The same sidebar has **Git** and **Settings** tabs. Switching to Git does not freeze the editor: status loads in the background, and you can go back to Files while it finishes. Settings turns file icons on or off immediately, and **Reload config** applies the saved file without quitting.

## Editor tabs

The middle pane is the editor. Tabs above it are clickable: a label switches buffers, **+** adds a tab, **×** closes the active one, and **‹ / ›** scroll when tabs overflow. File tabs show the same colored Devicon as the Files tree. Labels use the same `│` as the pane splits. Ctrl+T adds a tab. Ctrl+W closes one, and refuses if the file is unsaved. Ctrl+S saves (it asks for a name if the buffer is unnamed).

`:q` on the last editor window keeps the pane and leaves a tab, so the layout does not collapse.

## Settings

Ctrl+, or the **Settings** tab opens a sidebar next to Files and Git. Turn file icons on or off; the change applies immediately and persists for this machine. **[Reload config]** re-reads the saved file so you can pick up that choice without quitting Neovim. Enter or click a row to change it; `q` returns to Files. Lua and keymap edits still need a restart.

## Git source control

Ctrl+G opens a source-control view in the left sidebar: commit message, **[Commit]**, Staged Changes, Changes, and a **COMMITS** log at the bottom (about 30% of the window height). Red is deleted, yellow is modified, green is added or untracked. Changed files use the same Devicons as the Files tree so the extension is visible in Git too; icons keep their type colors and filenames follow git status.

Stage, unstage, revert, and commit with the keyboard or the mouse. Files and commits open in the mid editor, not in a new split. Space g s still opens Fugitive if you want the full `:Git` UI.

## AI chats

The right pane runs the real **Codex**, **Cursor Agent**, **Gemini**, **Claude**, and **OpenCode** CLIs. They use your login and your permissions. This setup does not inject prompts or bypass approvals.

Interactive startup opens one Codex session and one Cursor Agent session unless a saved session restores previous chats. Ctrl+] (or chat **+**) starts another independent Codex, Cursor Agent, Gemini, Claude, or OpenCode session. You can run several of any CLI at once. Switching tabs leaves a session running. Closing a tab stops that CLI. If the CLI process exits, that tab closes.

Esc in a chat is sent to that CLI (for example to stop generation) and stays in terminal mode. Ctrl+\ Ctrl+N leaves terminal input without sending Esc. Space a c / a u / a g / a l / a o toggle Codex, Cursor Agent, Gemini, Claude, and OpenCode.

Chats resume by ID on the next launch in that directory (`codex resume <uuid>`, `agent --resume=<uuid>`, `gemini --resume <uuid>`, `claude --resume <uuid>`, `opencode --session <id>`). They do not automatically receive the current selection: mention project-relative paths in the chat.

## Language servers, format, and debug

Mason installs language servers, formatters, and debug adapters. Completion, diagnostics, go-to-definition, references, rename, and hover work when a server is attached.

| Area                                  | Tools                                              |
| ------------------------------------- | -------------------------------------------------- |
| TypeScript / JavaScript / React / Vue | vtsls, vue_ls, prettierd                           |
| Svelte                                | svelte-language-server, prettierd                  |
| Lua                                   | lua-language-server, StyLua                        |
| Shell                                 | shfmt                                              |
| Rust                                  | rust-analyzer (Clippy), rustfmt, CodeLLDB          |
| Go                                    | gopls, gofmt, Delve                                |
| Solidity                              | Nomic Foundation language server                   |
| Web / config                          | HTML, CSS, Tailwind, ESLint, JSON, YAML, TOML, Lua |
| Debug                                 | Node launch/attach, Chrome attach, Delve, CodeLLDB |

Format with **Space f**, not on save. F5 starts or continues debugging. Space d b toggles a breakpoint. Custom debug configs can live in `.vscode/launch.json`; load them with `:DebugLoadLaunch`.

## Sessions

Ctrl+Q quits and writes this project's editor tabs, unsaved buffers, and chat UUIDs. Open the same directory later and they come back. `nvim --clean` skips restore and save, so you get a blank editor plus two fresh chats without overwriting the last session. `make install` puts a wrapper at `~/.local/bin/nvim` so `nvim --clean` still loads this config.
