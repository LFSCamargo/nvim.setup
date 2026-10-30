#!/usr/bin/env bash
# Format staged files with Prettier and re-stage the fixes.
source "$(dirname -- "$0")/common.sh"
need git
need node

cd -- "$SETUP_ROOT"
prettier="$SETUP_ROOT/node_modules/.bin/prettier"
[[ -x "$prettier" ]] || die 'Missing Prettier. Run pnpm install, then retry.'

if [[ -z "$(git diff --cached --name-only --diff-filter=ACMR)" ]]; then
  exit 0
fi

git diff --cached --name-only --diff-filter=ACMR -z |
  xargs -0 "$prettier" --write --ignore-unknown --
git diff --cached --name-only --diff-filter=ACMR -z | xargs -0 git add --
