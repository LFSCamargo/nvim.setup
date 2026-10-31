# Claude Code

Follow @AGENTS.md.

## Changing files

Before you finish a code change: write tests in `scripts/tests/` (bug fixes need a regression that fails without the patch and is listed in `docs/E2E-TESTPLAN.md`), reject spaghetti (keep `nvim/lua/modules/` modules single-purpose: `agents`, `session`, `sidebar`, `diff`, `context_menu`, `settings`, `extensions`, `palette`, `keys`, `tabs`, `lsp`, `dap`, `appearance`, `statusline`, `startup`, `icons`, `format`, `tooling`, `images`; do not grow `nvim/init.lua`), run `make check` and `make e2e`, review the diff for command injection, unsanitized `vim.cmd`, and secrets, and keep docs in sync (`docs/EDITOR.md` for keys, `docs/PLUGINS.md` for modules/plugins/tools, `docs/E2E-TESTPLAN.md` for e2e coverage).

## Committing

Only commit when asked. Use Conventional Commits. If asked to commit separately / by scope, follow the `commit-separately` skill. If asked to release, bump the version, or fold Unreleased into a version, follow the `release` skill. After the commit, run `make changelog`. If `CHANGELOG.md` changed, commit `chore(changelog): regenerate from commits` before pushing. Never edit `CHANGELOG.md` by hand. Skills are identical under `.claude/skills/`, `.cursor/skills/`, and `.codex/skills/`.
