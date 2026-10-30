#!/usr/bin/env bash
# Drive scripts/bump.sh, including prerelease versions used for GitHub tags.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd -P)"
PASS=0
fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
pass() {
  printf 'PASS: %s\n' "$*"
  PASS=$((PASS + 1))
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-bump.XXXXXX")"
trap 'cp -- "$TMP/VERSION.bak" "$ROOT/VERSION"; rm -rf -- "$TMP"' EXIT
cp -- "$ROOT/VERSION" "$TMP/VERSION.bak"

assert_file_has() {
  local file="$1" needle="$2"
  grep -F -- "$needle" "$file" > /dev/null 2>&1 || fail "$file missing '$needle'"
}

assert_file_has "$ROOT/scripts/bump.sh" '1.2.3-beta'
assert_file_has "$ROOT/scripts/changelog.mjs" '(-[0-9A-Za-z][0-9A-Za-z.-]*)?$'
pass 'bump and changelog accept prerelease versions'

if /bin/bash "$ROOT/scripts/bump.sh" 1.0.0/beta 2> "$TMP/err"; then
  fail 'bump.sh should reject a version with a slash'
fi
grep -F 'Usage:' "$TMP/err" > /dev/null || fail 'invalid version should print usage'
pass 'bump.sh rejects unsafe version strings'

if ! /bin/bash "$ROOT/scripts/bump.sh" 1.0.0-beta; then
  fail 'bump.sh should accept 1.0.0-beta'
fi
[[ "$(cat "$ROOT/VERSION")" == '1.0.0-beta' ]] || fail 'VERSION was not set to 1.0.0-beta'
pass 'bump.sh writes a prerelease VERSION'

printf '\n%s\n' "All $PASS bump tests passed"
