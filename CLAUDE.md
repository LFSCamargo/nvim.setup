# Claude Code

Follow @AGENTS.md.

## Changing files

Before you finish a code change: write tests in `scripts/tests/`, reject spaghetti (keep `nvim/lua/config/` modules single-purpose; do not grow `nvim/init.lua`), run `make check` and `make e2e`, and review the diff for command injection, unsanitized `vim.cmd`, and secrets.

## Committing

Only commit when asked. Use Conventional Commits. After the commit, run `make changelog`. If `CHANGELOG.md` changed, commit `chore(changelog): regenerate from commits` before pushing. Never edit `CHANGELOG.md` by hand.
