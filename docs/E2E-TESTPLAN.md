# E2E test plan

This is the contract for `make e2e`. When runtime behavior changes, extend the matching case so the new path fails without the patch. The implementation is `scripts/e2e.sh` (fixture + fake CLIs) driving `scripts/tests/e2e.lua` (child Neovim over RPC). Startup for that child is `scripts/tests/e2e-init.lua`.

Run from the repository root: `make e2e` or `make test` (`check` then `e2e`).

## How it works

1. `scripts/e2e.sh` creates a temp dir with a Git repo, fake `codex` / `agent` binaries, and a wrapper probe.
2. It launches headless Neovim with `-l scripts/tests/e2e.lua`.
3. The test file embeds a child Neovim (`--embed`), attaches a 120×40 UI, and drives mouse, keys, and Lua.
4. Fake CLIs record argv and stdin under `E2E_DIR`. The Git fixture has a modified file, a deleted file, and an untracked file.

Do not talk to real Codex/Agent logins. Do not use the user's `~/.config/nvim`.

## Current coverage

| Area | What must keep working | Where |
| --- | --- | --- |
| Lua globals | `.luarc.json` and `nvim/.luarc.json` declare `vim` | `e2e.lua` |
| Appearance | Visual has a fill; Normal stays transparent | `e2e.lua` |
| Startup chats | Two sessions (Codex + Cursor Agent); focus stays in the editor | `e2e.lua`, `e2e-init.lua` |
| Mouse → chat | Click chat enters terminal input | `e2e.lua` |
| Escape | Esc reaches the fake CLI as `0x1b` and does not leave terminal mode | `e2e.lua` |
| Mouse → editor / chat | Click moves focus; clicking the current chat restores input | `e2e.lua` |
| Leave terminal | `Ctrl+\ Ctrl+N` leaves insert-terminal | `e2e.lua` |
| Session paths | Session dir is under `nvim-setup-sessions` and hashes cwd (does not embed the path) | `e2e.lua` |
| Unsaved buffers | Named and unnamed modified buffers snapshot and restore still modified | `e2e.lua` |
| `NVIM_CLEAN` | Skips restore, does not overwrite `session.json`, does not spawn extra chats | `e2e.lua` |
| Git loading | Sidebar shows Loading; switching to Files ignores a late Git result | `e2e.lua` |
| Git sections | Staged Changes, Changes, deleted/new/modified files, red/yellow/green highlights | `e2e.lua` |
| Git log pane | Bottom `git-log` window at 30% height with graph of recent commits; Enter opens `git show` | `e2e.lua` |
| Git UI copy | No “Click” mouse hint; `[Commit]`, `Ctrl+Enter`, `x revert`, `i message`, Stage/Revert All | `e2e.lua` |
| Git composer | `git-composer` window exists | `e2e.lua` |
| Git width | Files/Git sidebar is 20% of the UI width | `e2e.lua` |
| Chat width | Chat pane is 25% of the UI width | `e2e.lua` |
| Git mouse | Collapse/expand Changes; click `+`/`−` to stage/unstage | `e2e.lua` |
| Git keyboard | `s` stages, `U` unstages all, `C` commits with composer message, `i` focuses message, Enter opens a file or a commit from the log pane, `x` reverts (confirm stubbed) | `e2e.lua` |
| Git mid editor | Files and commits open in the mid editor without a new split; a file still opens there after a commit view | `e2e.lua` |
| Editor `:q` / empty tabs | `:q` keeps the mid editor pane and a tab; opening from Git after wiping tabs adds a new tab | `e2e.lua` |
| UUID resume | `codex resume <uuid>` and `agent --resume=<uuid>`; restored session keeps uuid | `e2e.lua` |
| Ctrl+Q | Quits the child from terminal input with exit 0 | `e2e.lua` |
| Wrapper | `nvim --clean` sets `NVIM_CLEAN=1` and does not pass `--clean` through; `NVIM_WRAPPER=0` is a passthrough | `e2e.sh` |

## When you change X, add or extend Y

New behavior must fail in e2e without the patch. Prefer driving the UI (keys, mouse, commands) over calling internals. Every bug fix needs a regression in this file’s coverage matrix that reproduces the failure.

| Change | Update |
| --- | --- |
| Chat focus, Esc, or terminal input | The first PASS block in `e2e.lua` |
| Session save/restore, unsaved buffers, `NVIM_CLEAN` | The session `eval` block in `e2e.lua` |
| `nvim --clean` wrapper | The wrapper probes at the top of `e2e.sh` |
| Git sidebar UI, keys, composer, commit, revert, bulk actions, log pane, width, mid-editor opens | The Git block in `e2e.lua`; Git fixture in `e2e.sh` if you need extra files |
| Editor pane lifetime (`:q`, no tabs) | The Git block in `e2e.lua` after opening a file or commit |
| Startup layout or default chats | `e2e-init.lua` and the startup wait in `e2e.lua` |
| Codex / Cursor resume argv | The resume PASS block; fake CLI argv capture in `e2e.sh` |
| Ctrl shortcuts that should work in terminal mode | Send the key with `nvim_input` and assert the side effect |
| A new config module | Require it from `e2e-init.lua` if startup needs it; list it in `docs/PLUGINS.md` |
| A bug fix | A case that fails without the patch (same user path); add a coverage-matrix row |

## Not covered here (do not pretend e2e proves them)

These need `make validate`, packaging docs, or a real editor session:

- Mason package install and Tree-sitter parser builds (`make validate`, `make tools`, `make parsers`)
- Real `codex` / `agent` login and streaming
- LSP, completion, format, and debug adapters against a real project
- Fugitive (`Space g s`) and gitsigns hunk maps
- nvim-tree default file-tree keys other than our Files/Git toggle
- Warp / terminal forwarding of Command+P
- Linux package-manager `make deps` branches

## Related checks

| Command | What it is |
| --- | --- |
| `make check` | Shell `bash -n` and Lua `loadfile` on every repo Lua file |
| `make validate` | Installed config: Neovim version, Gruvbox, mouse, key maps, plugins, Mason, parsers, transparency, no headless chats |
| `docs/VALIDATION.md` | What the last packaging run covered |

Keep this file aligned with the tests. If you delete a case from `e2e.lua`, delete it here. If you add a PASS line, add a row to the coverage table.
