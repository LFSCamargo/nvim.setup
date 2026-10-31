# Contribute: a first-change tutorial

This walkthrough takes you from a fork to a pull request. The rules live in
[CONTRIBUTING.md](../CONTRIBUTING.md). Read that if you already know the tree.

You will need Git, a GitHub account, and the [install
requirements](../README.md#requirements). The website steps also need Node.js
22.12+ and pnpm 10.34.9.

## 1. Get a checkout you can push

```sh
git clone https://github.com/YOUR_USER/nvim.setup.git
cd nvim.setup
git remote add upstream https://github.com/LFSCamargo/nvim.setup.git
git checkout -b your-change
```

## 2. Run the setup from this tree

```sh
./scripts/bootstrap.sh
nvim .
```

That installs Neovim if needed, copies `nvim/` into your config, and pins
plugins from `nvim/lazy-lock.json`. To keep your current `~/.config/nvim`:

```sh
./scripts/bootstrap.sh --preview
NVIM_APPNAME=nvim-preview nvim .
```

Then install workspace tools (Git hooks, changelog, marketing site):

```sh
pnpm install
```

`pnpm install` is what enables the Prettier pre-commit hook and commitlint.

## 3. Pick one kind of change

Stay in one area so the review stays small.

| You want to change                         | Start here                                              | Also update                                                  |
| ------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------ |
| A keymap, click, or user command           | `nvim/lua/modules/keys/init.lua` (or the owning module) | `docs/EDITOR.md`, often README                               |
| Chat CLIs, Git sidebar, tabs, session, LSP | The matching `nvim/lua/modules/<name>/init.lua` file    | `docs/PLUGINS.md` if the module list changed                 |
| Install / bootstrap / fonts                | `scripts/`                                              | `docs/PLUGINS.md` if a tool changed                          |
| Landing page or `/docs` reader             | `apps/web/`                                             | `docs/E2E-TESTPLAN.md` if you add a browser case             |
| Docs only                                  | `docs/`, `README.md`, `CONTRIBUTING.md`                 | Keep the other docs from going stale                         |
| Agent skills                               | `.cursor/skills/<name>/SKILL.md`                        | Copy the same file to `.claude/skills/` and `.codex/skills/` |

Do not add a new `nvim/lua/modules/<name>/` module without listing it in
`docs/PLUGINS.md`, `AGENTS.md`, `CLAUDE.md`, and
`.cursor/rules/changing-files.mdc`. Do not grow `nvim/init.lua`. Project
skills must stay identical under `.cursor/skills/`, `.claude/skills/`, and
`.codex/skills/`.

## 4. Write the test first (runtime changes)

For a Neovim UI change, extend `scripts/e2e/e2e.lua` so the new path **fails
on the unpatched code**. Drive the same key, click, or command a user would.
Assert the window, tab, buffer, or mode that was wrong. Add a row to
[E2E-TESTPLAN.md](E2E-TESTPLAN.md).

Shell and Node checks live next to the thing they cover:
`scripts/shell/__tests__/bootstrap.test.sh`, `scripts/shell/__tests__/fonts.test.sh`, `scripts/shell/__tests__/scan.test.sh`,
`format.test.sh`, `bump.test.sh`, `workspace.test.mjs`, and
`apps/web/src/**/*.test.ts(x)`.

Docs-only edits skip `make e2e` when nothing in the editor or site runtime
changed.

## 5. Make the change

Edit `nvim/` in the repo, then deploy it:

```sh
make install
```

If you already edited the installed files under `~/.config/nvim` instead:

```sh
make capture
git diff
```

Capture only brings back `init.lua`, `lua/`, `scripts/`, and `lazy-lock.json`.

For the marketing site:

```sh
pnpm dev
```

Guides on `/docs` are static files under `apps/web/public/guides/`. Repo copies
of `docs/EDITOR.md`, `docs/PLUGINS.md`, and `docs/E2E-TESTPLAN.md` are refreshed
when Vite starts or builds.

## 6. Run the checks that match the change

Neovim / shell / Lua:

```sh
make check
make e2e
# or: make test
```

`make e2e` uses a temp Git repo and fake chat CLIs. It does not use your
`~/.config/nvim` or real Codex / Claude logins. See
[E2E-TESTPLAN.md](E2E-TESTPLAN.md).

Website:

```sh
pnpm --filter web test
pnpm format:check
pnpm test:web:e2e # Playwright; optional in CI, run it for UI work
```

Security when you touched installers, `vim.cmd`, or npm:

```sh
make scan
```

Fix anything that fails before you open the pull request.

## 7. Commit the way CI expects

```sh
git add path/to/changed/files
git commit -m "$(
  cat << 'EOF'
feat(keys): add a clearer example subject

Why the change exists, wrapped at 100 characters.
EOF
)"
make changelog
```

If `CHANGELOG.md` changed:

```sh
git add CHANGELOG.md
git commit -m "$(
  cat << 'EOF'
chore(changelog): regenerate from commits
EOF
)"
```

Never edit `CHANGELOG.md` by hand. Types and the changelog loop are in
[CONTRIBUTING.md](../CONTRIBUTING.md#commits).

## 8. Open the pull request

```sh
git fetch upstream
git rebase upstream/main
git push -u origin HEAD
```

Open a pull request against `main`. Say what you changed and which commands
you ran. One concern per PR is easier to review than a mixed Neovim + website
dump.

## Two worked sketches

**A. New leader keymap.** Add the map in `nvim/lua/modules/keys/init.lua`. Extend
`e2e.lua` so the key does the side effect you care about. Add the row to
`docs/EDITOR.md` and `docs/E2E-TESTPLAN.md`. Run `make test`.

**B. Docs page copy on the site.** Edit the source markdown (`README.md` or
`docs/*.md`). If Vite copies that file into `apps/web/public/guides/`, the
next `pnpm dev` refreshes it. Run `pnpm format:check`. No `make e2e` unless
you also changed runtime behavior.

## If something looks off

- `:checkhealth`, `:LspInfo`, `:MasonLog`, `:ConformInfo`, `:messages`
- `make doctor` for missing system tools
- [docs/EDITOR.md](EDITOR.md) for keys, [docs/PLUGINS.md](PLUGINS.md) for
  modules and tools

Do not pipe the installer to sudo. Do not commit secrets.
