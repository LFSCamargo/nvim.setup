# E2E test plan

This is the contract for `make e2e`. When runtime behavior changes, extend the matching case so the new path fails without the patch. The implementation is `scripts/e2e.sh` (fixture + fake CLIs) driving `scripts/tests/e2e.lua` (child Neovim over RPC). Startup for that child is `scripts/tests/e2e-init.lua`.

Run from the repository root: `make e2e` or `make test` (`check` then `e2e`).

## How it works

1. `scripts/e2e.sh` creates a temp dir with a Git repo, fake `codex` / `agent` / `gemini` / `claude` / `opencode` binaries, and a wrapper probe.
2. It launches headless Neovim with `-l scripts/tests/e2e.lua`.
3. The test file embeds a child Neovim (`--embed`), attaches a 120×40 UI, and drives mouse, keys, and Lua.
4. Fake CLIs record argv and stdin under `E2E_DIR`. The Git fixture has a modified file, a deleted file, untracked `.txt` / `.ts` / `.rs` files, and Devicons stubs for extension icons.

Do not talk to real Codex/Agent logins. Do not use the user's `~/.config/nvim`.

## Current coverage

| Area                     | What must keep working                                                                                                                                                    | Where                     |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| Lua globals              | `.luarc.json` and `nvim/.luarc.json` declare `vim`                                                                                                                        | `e2e.lua`                 |
| Appearance               | Visual has a fill; Normal stays transparent                                                                                                                               | `e2e.lua`                 |
| Startup chats            | Two sessions (Codex + Cursor Agent); focus stays in the editor                                                                                                            | `e2e.lua`, `e2e-init.lua` |
| Mouse → chat             | Click chat enters terminal input                                                                                                                                          | `e2e.lua`                 |
| Escape                   | Esc reaches the fake CLI as `0x1b` and does not leave terminal mode                                                                                                       | `e2e.lua`                 |
| Mouse → editor / chat    | Click moves focus; clicking the current chat restores input                                                                                                               | `e2e.lua`                 |
| Leave terminal           | `Ctrl+\ Ctrl+N` leaves insert-terminal                                                                                                                                    | `e2e.lua`                 |
| Session paths            | Session dir is under `nvim-setup-sessions` and hashes cwd (does not embed the path)                                                                                       | `e2e.lua`                 |
| Unsaved buffers          | Named and unnamed modified buffers snapshot and restore still modified                                                                                                    | `e2e.lua`                 |
| No swap files            | `swapfile` stays off on save, restore, and `NVIM_CLEAN`; session snapshots still restore modified buffers                                                                 | `e2e.lua`                 |
| `NVIM_CLEAN`             | Skips restore, does not overwrite `session.json`, does not spawn extra chats                                                                                              | `e2e.lua`                 |
| Git loading              | Sidebar shows Loading; switching to Files ignores a late Git result                                                                                                       | `e2e.lua`                 |
| Git sections             | Staged Changes, Changes, deleted/new/modified files, red/yellow/green highlights                                                                                          | `e2e.lua`                 |
| File type icons          | Files tree enables file Devicons; folders use nvim-tree glyphs (`web_devicons.folder.enable = false`) so directories are not drawn as files; expand markers are `>` / `v` | `e2e.lua`                 |
| Devicons only            | No `:IconTheme` or Ctrl+Shift+I pack switcher; Files and Git stay on nvim-web-devicons                                                                                    | `e2e.lua`                 |
| Git log pane             | Bottom `git-log` window at 30% height with graph of recent commits; Enter opens `git show`                                                                                | `e2e.lua`                 |
| Git UI copy              | No “Click” mouse hint; `[Commit]`, `Ctrl+Enter`, `x revert`, `i message`, Stage/Revert All                                                                                | `e2e.lua`                 |
| Git composer             | `git-composer` window exists                                                                                                                                              | `e2e.lua`                 |
| Git width                | Files/Git sidebar is 20% of the UI width                                                                                                                                  | `e2e.lua`                 |
| Chat width               | Chat pane is 25% of the UI width                                                                                                                                          | `e2e.lua`                 |
| Git mouse                | Collapse/expand Changes; click `+`/`−` to stage/unstage                                                                                                                   | `e2e.lua`                 |
| Git keyboard             | `s` stages, `U` unstages all, `C` commits with composer message, `i` focuses message, Enter opens a file or a commit from the log pane, `x` reverts (confirm stubbed)     | `e2e.lua`                 |
| Git focus refresh        | Clicking Git again, or focusing the Git list from the editor, reloads status                                                                                              | `e2e.lua`                 |
| Git mid editor           | Files and commits open in the mid editor without a new split; a file still opens there after a commit view                                                                | `e2e.lua`                 |
| Editor `:q` / empty tabs | `:q` keeps the mid editor pane and a tab; opening from Git after wiping tabs adds a new tab                                                                               | `e2e.lua`                 |
| Ctrl+P file tab          | Selecting a file from Ctrl+P opens it in the mid editor as a new tab (does not `:edit`-replace a blank tab) and reuses an existing tab for the same file                  | `e2e.lua`                 |
| UUID resume              | `codex resume <uuid>`, `agent --resume=<uuid>`, `gemini --resume <uuid>`, `claude --resume <uuid>`, `opencode --session <id>`; restored sessions keep ids                 | `e2e.lua`                 |
| Agent process exit       | When the chat CLI job ends, that tab closes and another session is shown; the last remaining job exit closes the pane                                                     | `e2e.lua`                 |
| Stuck `(exited)` chat    | Clicking an `(exited)` leftover tab closes it; Ctrl+W still wipes an orphan terminal after a failed auto-close                                                            | `e2e.lua`                 |
| Ctrl+Q                   | Quits the child from terminal input with exit 0                                                                                                                           | `e2e.lua`                 |
| Wrapper                  | `nvim --clean` sets `NVIM_CLEAN=1` and does not pass `--clean` through; `NVIM_WRAPPER=0` is a passthrough                                                                 | `e2e.sh`                  |

## When you change X, add or extend Y

New behavior must fail in e2e without the patch. Prefer driving the UI (keys, mouse, commands) over calling internals. Every bug fix needs a regression in this file’s coverage matrix that reproduces the failure.

| Change                                                                                                         | Update                                                                                            |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Chat focus, Esc, or terminal input                                                                             | The first PASS block in `e2e.lua`                                                                 |
| Chat tab lifetime when the CLI process exits                                                                   | The agent process-exit PASS blocks in `e2e.lua`                                                   |
| Session save/restore, unsaved buffers, `NVIM_CLEAN`, no swap files                                             | The session `eval` block in `e2e.lua`                                                             |
| `nvim --clean` wrapper                                                                                         | The wrapper probes at the top of `e2e.sh`                                                         |
| Git sidebar UI, keys, composer, commit, revert, bulk actions, log pane, width, mid-editor opens, focus refresh | The Git block in `e2e.lua`; Git fixture in `e2e.sh` if you need extra files                       |
| File type icons in the Files tree or Git sidebar                                                               | The Git block in `e2e.lua` (tree_icons + extension glyphs); extra files in `e2e.sh`               |
| Devicons only (no Ctrl+Shift+I / `:IconTheme`)                                                                 | The Devicons PASS in `e2e.lua` after Git; stubs in `e2e-init.lua`                                 |
| nvim-tree Files draw / `web_devicons.folder`                                                                   | The Git and icon-theme blocks in `e2e.lua` (`tree_icons_safe`)                                    |
| Editor pane lifetime (`:q`, no tabs)                                                                           | The Git block in `e2e.lua` after opening a file or commit                                         |
| Ctrl+P / Ctrl+F / fzf-lua file open                                                                            | The Ctrl+P tab block in `e2e.lua` after the Git PASS                                              |
| Startup layout or default chats                                                                                | `e2e-init.lua` and the startup wait in `e2e.lua`                                                  |
| Codex / Cursor / Gemini / Claude / OpenCode resume argv                                                        | The resume PASS block; fake CLI argv capture in `e2e.sh`                                          |
| Ctrl shortcuts that should work in terminal mode                                                               | Send the key with `nvim_input` and assert the side effect                                         |
| A new config module                                                                                            | Require it from `e2e-init.lua` if startup needs it; list it in `docs/PLUGINS.md`                  |
| A bug fix                                                                                                      | A case that fails without the patch (same user path); add a coverage-matrix row                   |
| `scripts/bootstrap.sh` or the public curl install one-liner                                                    | `scripts/tests/bootstrap.test.sh` and the landing-page command copy                               |
| Icon fonts (`scripts/fonts.sh`) or Warp/Kitty font fallbacks                                                   | `scripts/tests/fonts.test.sh`                                                                     |
| Baking one-cell Nerd Font glyphs into the Warp primary font (`scripts/overlay_fonts.py`)                       | `scripts/tests/fonts.test.sh` overlay case (family name, cmap, one-cell metrics)                  |
| Landing-page header icons/type switch black/white from backdrop grayscale (>50% → black)                       | `apps/web/src/lib/contrast.test.tsx` gutter-vs-screenshot case and Playwright overlap cases       |
| Landing-page light-mode chrome (caret, screenshot rims, inverted install, docs logo)                           | `apps/web/src/App.test.tsx`, `contrast.test.tsx` nested-band case, and Playwright light-mode case |
| Landing-page or docs code samples                                                                              | `apps/web/src/components/code-block.tsx` and visitor-path / Playwright copy cases                 |
| Landing-page titles, Open Graph tags, canonicals, robots.txt, or sitemap.xml                                   | `apps/web/src/lib/seo.test.ts`, visitor-path title cases, and Playwright SEO case                 |
| Landing-page docs refresh 404 (SPA fallback / 404.html / `_redirects`)                                         | `apps/web/src/lib/spa.test.ts` and the Playwright documentation reload case                       |
| OWASP Semgrep rulesets, `.semgrepignore`, `scripts/scan.sh`, or the security CI jobs                           | `scripts/tests/scan.test.sh` and the workspace security-barrier test                              |
| Pre-commit Prettier rewrite of staged files                                                                    | `scripts/tests/format.test.sh` and the workspace hook test                                        |
| `make bump VERSION=1.2.3-beta` or changelog release tags                                                       | `scripts/tests/bump.test.sh`                                                                      |

## Not covered here (do not pretend e2e proves them)

These need `make validate`, packaging docs, or a real editor session:

- Mason package install and Tree-sitter parser builds (`make validate`, `make tools`, `make parsers`)
- Real `codex` / `agent` / `gemini` / `claude` / `opencode` login and streaming
- LSP, completion, format, and debug adapters against a real project
- Fugitive (`Space g s`) and gitsigns hunk maps
- nvim-tree default file-tree keys other than our Files/Git toggle
- Warp / terminal forwarding of Command+P
- Linux package-manager `make deps` branches

## Related checks

| Command              | What it is                                                                                                           |
| -------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `make check`         | Shell `bash -n` and Lua `loadfile` on every repo Lua file                                                            |
| `make scan`          | Semgrep CE OWASP/JS SAST (`--error`) and `pnpm audit --audit-level=moderate`                                         |
| `make validate`      | Installed config: Neovim version, Gruvbox, mouse, key maps, plugins, Mason, parsers, transparency, no headless chats |
| `docs/VALIDATION.md` | What the last packaging run covered                                                                                  |

Keep this file aligned with the tests. If you delete a case from `e2e.lua`, delete it here. If you add a PASS line, add a row to the coverage table.

## Workspace and website checks

`node --test scripts/tests/workspace.test.mjs` verifies the pnpm 10 package-manager pin and single-document lockfile required by Nx (regression for pnpm 12 multi-document lockfile parsing), app discovery, removal of the npm lockfile, uncached Nx delegation to the real Neovim checks, matching pnpm commands in CI and commit hooks, that `apps/web` is TypeScript with Tailwind and Prettier, that `/docs` loads static `public/guides/*.md` files instead of Vite markdown imports, that the marketing site ships `robots.txt`, `sitemap.xml`, Open Graph tags, and an SPA refresh fallback (`404.html` / `_redirects`), and that CI runs Semgrep CE (OWASP / JS rules, no cloud token) plus Prettier, TypeScript, and the production build (not Playwright or the visitor-path suite). `bash scripts/tests/bootstrap.test.sh` drives `scripts/bootstrap.sh` the way a visitor would (piped one-liner, `--preview`, in-checkout, root refusal, GitHub-only clone URL) with stubbed `git`/`brew` so it does not install packages, and asserts the one-liner runs `scripts/fonts.sh`. `bash scripts/tests/fonts.test.sh` drives `scripts/fonts.sh` with stubbed `curl` so Symbols Nerd Font and Monocraft Nerd Font land in the user font dir and Warp/Kitty fallbacks stay fail-closed, and checks that `overlay_fonts.py` bakes one-cell Nerd Font glyphs into a face named Monocraft Nerd Font. `bash scripts/tests/scan.test.sh` drives `scripts/scan.sh` with stubbed `pnpm` / `semgrep` so SAST and the lockfile audit stay fail-closed without downloading rules. `bash scripts/tests/format.test.sh` drives `scripts/format-staged.sh` so the pre-commit hook rewrites messy staged JS and `git add`s the fix. `bash scripts/tests/bump.test.sh` drives `scripts/bump.sh` so `1.0.0-beta` is a valid release version and slashes are rejected. `pnpm test:setup` runs these checks after `make test`; no Neovim startup behavior is changed by the workspace migration.

`pnpm --filter web test` typechecks the landing page and runs its Vitest visitor-path suite, including the on-site `/docs` reader, documentation and install code samples, the workspace / Git / layout / AI agents screenshot tabs, header type contrast over the real backdrop (screenshot fills, install band), light/dark theme switchers, light-mode hero chrome (thin caret, dark screenshot rims), local-tool install docs on the install band, the screenshot lightbox chrome, unique home/docs titles with Open Graph and JSON-LD, and the infinite principles marquee (two equal halves, copies sized to the viewport). `pnpm test:web:e2e` runs the landing page's browser checks, screenshot lightbox, documentation sidebar, theme switching, nav type following the backdrop behind the glass (not a painted white/black shell), light-mode readability of the hero, feature cards, and docs, unique titles plus robots/sitemap for search engines, a documentation URL that still loads after refresh, and that the marquee track stays wider than the viewport with `animation-iteration-count: infinite`. `pnpm format:check` fails when Prettier or Tailwind class order is stale. GitHub Actions runs those format, typecheck, and build steps plus Semgrep; the visitor-path and Playwright suites stay on the machine. These are separate from the simulated Neovim UI suite.
