#!/usr/bin/env bash
# Format staged files with Prettier and re-stage the fixes.
source "$(dirname -- "$0")/common.sh"
need git
need node

cd -- "$SETUP_ROOT"
prettier="$SETUP_ROOT/node_modules/.bin/prettier"
stylua="$SETUP_ROOT/node_modules/.bin/stylua"
[[ -x "$prettier" ]] || die 'Missing Prettier. Run pnpm install, then retry.'
[[ -x "$stylua" ]] || die 'Missing StyLua. Run pnpm install, then retry.'

if [[ -z "$(git diff --cached --name-only --diff-filter=ACMR)" ]]; then
  exit 0
fi

git diff --cached --name-only --diff-filter=ACMR -z \
  | xargs -0 "$prettier" --write --ignore-unknown --

lua_files=()
while IFS= read -r -d '' file; do
  case "$file" in
    *.lua) lua_files+=("$file") ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR -z)

if ((${#lua_files[@]} > 0)); then
  "$stylua" -- "${lua_files[@]}"
fi

git diff --cached --name-only --diff-filter=ACMR -z | xargs -0 git add --
