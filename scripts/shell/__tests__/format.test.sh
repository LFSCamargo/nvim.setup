#!/usr/bin/env bash
# Drive scripts/format-staged.sh the way the pre-commit hook does.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../../.." && pwd -P)"
PASS=0
fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
pass() {
  printf 'PASS: %s\n' "$*"
  PASS=$((PASS + 1))
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-format.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

write_stub() {
  local path="$1"
  mkdir -p -- "$(dirname -- "$path")"
  cat > "$path"
  chmod +x "$path"
}

assert_file_has() {
  local file="$1" needle="$2"
  grep -F -- "$needle" "$file" > /dev/null 2>&1 || fail "$file missing '$needle'"
}

assert_file_has "$ROOT/.husky/pre-commit" 'scripts/format-staged.sh'
assert_file_has "$ROOT/scripts/shell/format-staged.sh" 'node_modules/.bin/prettier'
assert_file_has "$ROOT/scripts/shell/format-staged.sh" 'node_modules/.bin/stylua'
assert_file_has "$ROOT/scripts/shell/format-staged.sh" '--write --ignore-unknown'
assert_file_has "$ROOT/scripts/shell/format-staged.sh" 'git add --'
assert_file_has "$ROOT/prettier.config.mjs" 'prettier-plugin-packagejson'
assert_file_has "$ROOT/prettier.config.mjs" 'prettier-plugin-sh'
assert_file_has "$ROOT/prettier.config.mjs" 'prettier-plugin-tailwindcss'
assert_file_has "$ROOT/stylua.toml" 'indent_width = 2'
pass 'pre-commit formats staged files with Prettier, StyLua, and extra plugins'

messy_js="$TMP/messy.mjs"
messy_lua="$TMP/messy.lua"
printf 'const x=1\n' > "$messy_js"
printf 'local  x=1\n' > "$messy_lua"
calls="$TMP/calls.log"
: > "$calls"
bin="$TMP/bin"
write_stub "$bin/git" << EOF
#!/bin/sh
printf 'git %s\n' "\$*" >>'$calls'
case "\$1" in
  diff)
    printf '%s\0' '$messy_js' '$messy_lua'
    ;;
  add)
    ;;
  *)
    exit 1
    ;;
esac
EOF

if ! env -i \
  HOME="$TMP" \
  PATH="$bin:/usr/bin:/bin:$PATH" \
  /bin/bash "$ROOT/scripts/format-staged.sh"; then
  fail 'format-staged.sh should succeed with a stubbed git index'
fi
grep -F 'const x = 1;' "$messy_js" > /dev/null || fail 'staged JS was not formatted'
grep -F 'local x = 1' "$messy_lua" > /dev/null || fail 'staged Lua was not formatted'
grep -F 'git add --' "$calls" > /dev/null || fail 'formatted files must be re-staged'
grep -F "$messy_js" "$calls" > /dev/null || fail 'formatted JS must be re-staged'
grep -F "$messy_lua" "$calls" > /dev/null || fail 'formatted Lua must be re-staged'
pass 'format-staged.sh rewrites messy JS and Lua and git-adds the fixes'

printf '\n%s\n' "All $PASS format tests passed"
