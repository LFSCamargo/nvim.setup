# Agent instructions

Cursor, Claude Code, and Codex follow this file. Cursor also loads `.cursor/rules/`. Claude Code also loads `CLAUDE.md`.

Do not finish work that skipped a required check. Do not commit or push unless the user asked.

## Changing files

After any code, script, or test change, complete all five before you stop:

1. **Write tests.** Add or update coverage in `scripts/tests/`. Extend `scripts/tests/e2e.lua` (and `e2e-init.lua` when startup setup changes) so the new behavior fails without the patch. Do not ship untested behavior. Every bug fix needs a regression test that reproduces the bug (same keys/clicks/commands, assert the broken window/tab/buffer/mode) and is listed in `docs/E2E-TESTPLAN.md`.
2. **Check for spaghetti.** Keep `nvim/lua/config/*.lua` single-purpose (`agents`, `session`, `sidebar`, `keys`, `tabs`, `lsp`, `dap`, `appearance`, `startup`). Do not grow `nvim/init.lua`. Extract helpers instead of copy-paste. Shell belongs in `scripts/` and shares `scripts/common.sh`.
3. **Run E2E tests.** Run `make check` and `make e2e` (or `make test`). Fix failures before finishing.
4. **Check for vulnerabilities.** Review the diff for unsanitized shell, `vim.cmd` without `fnameescape`, `jobstart` via a shell string, path traversal, and secret leakage. Quote bash variables. Prefer argv arrays over `sh -c`. Do not log credentials, tokens, or `.env` files.
5. **Keep docs in sync.** Keys and commands → `docs/EDITOR.md` (and `README.md` for user-facing global shortcuts). New/removed modules, Lazy plugins, Mason tools, or parsers → `docs/PLUGINS.md` and the spaghetti list above. E2E cases → `docs/E2E-TESTPLAN.md`. Do not invent keys, plugins, or tests that are not in the code.

Docs-only or generated-file edits skip tests and E2E when no runtime behavior changed. Still scan for secrets. Still update the other docs if the change is documentation of existing behavior.

## Committing and pushing

`CHANGELOG.md` is generated. Never edit it by hand.

When the user asks to commit:

1. Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. A scope is optional.
2. Commit the work.
3. Run `make changelog`.
4. If `CHANGELOG.md` changed, commit it as `chore(changelog): regenerate from commits`.
5. Push only if the user asked. The pre-push hook and CI fail when the changelog is stale.

`chore(changelog)` commits are omitted from the changelog so regeneration does not loop.
