# Contributing

Thanks for helping with nvim.setup. This file is the contract for a change.
For a first-time walkthrough (clone → edit → test → pull request), see
[docs/TUTORIAL.md](docs/TUTORIAL.md).

Issues and pull requests go to
[github.com/LFSCamargo/nvim.setup](https://github.com/LFSCamargo/nvim.setup).
The project is licensed under the [MIT License](LICENSE).

## Before you start

1. Fork the repo and clone your fork.
2. Install from that checkout so you are editing the same tree you run:

   ```sh
   ./scripts/bootstrap.sh
   nvim .
   ```

   Use `./scripts/bootstrap.sh --preview` and `NVIM_APPNAME=nvim-preview nvim .`
   if you do not want to replace `~/.config/nvim`.

3. Install Node tools for hooks, the changelog, and the marketing site:

   ```sh
   pnpm install
   ```

   Node.js 22.12+ and pnpm 10.34.9 are required. Do not add a `package-lock.json`.

## What a change must do

After any code, script, or test edit, finish all five:

1. **Tests.** Cover new behavior in `scripts/tests/`. Neovim UI changes need a
   case in `scripts/tests/e2e.lua` (and `e2e-init.lua` if startup changed) that
   **fails without the patch**. A bug fix must drive the same keys, clicks, or
   commands and assert the broken window, tab, buffer, or mode. List the case
   in [docs/E2E-TESTPLAN.md](docs/E2E-TESTPLAN.md).
2. **No spaghetti.** Keep `nvim/lua/modules/<name>/init.lua` focused on its
   feature. Put feature helpers beside it and shared helpers in `modules/shared/`.
   Website features live in `apps/web/src/modules/`; reusable UI and layout
   live in `apps/web/src/shared/`. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
   Do not grow `nvim/init.lua`. Put shell in `scripts/` and share `scripts/common.sh`.
3. **Checks.** `make check` and `make e2e` (or `make test`) must pass. Website
   work also needs `pnpm --filter web test` and `pnpm format:check`.
4. **Safety.** Quote shell variables. Prefer argv arrays over `sh -c`. Escape
   paths in `vim.cmd` with `fnameescape`. Do not log tokens or `.env` files.
5. **Docs.** Keys and commands → [docs/EDITOR.md](docs/EDITOR.md) (and
   [README.md](README.md) for primary shortcuts). Modules, Lazy plugins, Mason
   tools, parsers → [docs/PLUGINS.md](docs/PLUGINS.md). E2E cases →
   [docs/E2E-TESTPLAN.md](docs/E2E-TESTPLAN.md). Do not invent keys, plugins,
   or tests that are not in the code.

Docs-only edits skip `make e2e` when runtime behavior did not change. Still
scan for secrets.

Prefer editing `nvim/` here and running `make install`. If you already edited
the installed config, `make capture` copies `init.lua`, `lua/`, `scripts/`, and
`lazy-lock.json` back. It does not copy caches or credentials.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): subject`. Types: `feat`, `fix`, `docs`, `style`, `refactor`,
`perf`, `test`, `build`, `ci`, `chore`, `revert`. Subject is lowercase, no
trailing period.

```text
feat: click a chat pane to start typing
fix(agents): send Escape to the focused session
docs: document the e2e check
```

After `pnpm install`, `pre-commit` runs Prettier on staged files and
`commit-msg` rejects a message that does not match. After the work commit, run
`make changelog`. If `CHANGELOG.md` changed, commit it as
`chore(changelog): regenerate from commits`. Never edit `CHANGELOG.md` by hand.
The pre-push hook and CI fail when that file is stale.

## Pull requests

- Branch from `main`.
- Keep the pull request to one concern when you can.
- Describe what changed and how you tested it (`make test`, website commands,
  or “docs only”).
- Do not commit `node_modules/`, `dist/`, `.nx/`, or secrets.

CI on GitHub runs Prettier, TypeScript, `pnpm build`, Semgrep, and commitlint.
Visitor-path and Playwright suites stay local (`pnpm --filter web test`,
`pnpm test:web:e2e`). Semgrep and `pnpm audit` also run locally via
`make scan`.

## Releases

Maintainers bump `VERSION` and fold **Unreleased** into a dated section with
`make bump` plus `make changelog`. Agents follow the `release` skill
([`.cursor/skills/release/SKILL.md`](.cursor/skills/release/SKILL.md), with
identical copies under `.claude/skills/` and `.codex/skills/`).

## Help

Cursor, Claude Code, and Codex follow [AGENTS.md](AGENTS.md). Questions that
are not a patch belong in
[GitHub Issues](https://github.com/LFSCamargo/nvim.setup/issues).
