---
name: commit-separately
description: >-
  Split uncommitted work into one Conventional Commit per scope, then regenerate
  the changelog. Use when the user asks to commit separately, commit by scope,
  split commits, one commit per part, or attach each scope to different parts of
  the changes.
---

# Commit separately

Split the working tree into several Conventional Commits. Do not make one catch-all commit. Do not push unless the user asked.

## When this applies

The user asked to commit **and** to split by part/scope (for example “commit separately”, “each scope”, “one commit per part”). If they only said “commit”, make a single commit unless the diff clearly mixes unrelated concerns and they already use this workflow.

## Inspect first

Run in parallel:

```sh
git status
git diff
git diff --cached
git log -12 --oneline
```

Read mixed files (`package.json`, `content.ts`, workflows, docs) before grouping. Never use `git add -i` / `git add -p`.

## Group by scope

Map **files** to Conventional Commit scopes. One commit = one type + one scope + one reason.

Typical scopes in this repo: `workspace`, `bootstrap`, `web`, `theme`, `docs`, `test`, `ci`, `git`, `session`, `agents`.

| Put together                                               | Because                     |
| ---------------------------------------------------------- | --------------------------- |
| A feature module and its tests                             | The test names the behavior |
| `apps/web/public/guides/plugins.md` with `docs/PLUGINS.md` | The guide is a copy         |
| Lockfile with the `package.json` that changed it           | Install must match          |

| Split                                                          | Because                                              |
| -------------------------------------------------------------- | ---------------------------------------------------- |
| pnpm/Nx vs landing-page UI                                     | Different scopes (`build(workspace)` vs `feat(web)`) |
| Screenshots vs source vs Playwright vs Actions                 | Different parts                                      |
| Theme/marquee/lightbox files vs the page that later wires them | Different scopes                                     |

**Shared files** (one file, many features): put them in the earliest commit that cannot build or typecheck without them. Do not rewrite a file between commits to fake history.

**Order:** tooling → installer → assets → libraries → composing app → tests → CI → docs. Later commits may add files that earlier ones import; do not break git add of a file that does not exist yet.

Skip empty groups. Do not commit `node_modules/`, `dist/`, `.nx/`, secrets.

## Commit each group

Stage only that group’s paths, then:

```sh
git commit -m "$(
  cat << 'EOF'
type(scope): imperative subject

Why this part exists, wrapped at 100 characters.
EOF
)"
```

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Subject: lowercase, no trailing period, focus on **why**.
- Body: required when the subject is not enough; every line ≤ 100 characters (`@commitlint/config-conventional`). Cursor may append `Co-authored-by`; keep **your** lines short.
- Do not skip hooks (`--no-verify`).
- If `commit-msg` fails, fix the message and create a **new** commit. Do not `--amend` unless the user asked, HEAD is yours, and it has not been pushed.
- After each commit, `git status --short` so leftover files go into the next group.

## After the last work commit

```sh
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

Never edit `CHANGELOG.md` by hand. `chore(changelog)` commits are omitted from the file.

Do not push unless the user asked.

## Example

Uncommitted marketing site + pnpm workspace →

1. `build(workspace): switch the repo to pnpm and Nx`
2. `feat(web): add cropped workspace screenshots`
3. `feat(theme): persist light and dark color schemes`
4. `test(web): cover visitor paths in Playwright`
5. `ci(web): run website checks in GitHub Actions`
6. `docs(web): document the website and browser tests`
7. `chore(changelog): regenerate from commits`
