#!/usr/bin/env bash
# Drive scripts/bump.sh, including prerelease versions used for GitHub tags.
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-bump.XXXXXX")"
trap 'cp -- "$TMP/VERSION.bak" "$ROOT/VERSION"; rm -rf -- "$TMP"' EXIT
cp -- "$ROOT/VERSION" "$TMP/VERSION.bak"

assert_file_has() {
  local file="$1" needle="$2"
  grep -F -- "$needle" "$file" > /dev/null 2>&1 || fail "$file missing '$needle'"
}

assert_file_has "$ROOT/scripts/shell/bump.sh" '1.2.3-beta'
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

SUM_BEFORE="$(shasum -a 256 -- "$ROOT/CHANGELOG.md" | awk '{print $1}')"
NOTES_2="$(/bin/bash "$ROOT/scripts/changelog.sh" --notes 2.0.0)" || fail 'changelog --notes 2.0.0 should print the 2.0.0 section'
[[ "$NOTES_2" == *'### Features'* ]] || fail '2.0.0 notes should include Features'
[[ "$NOTES_2" == *'add theme selection'* ]] || fail '2.0.0 notes should include that version body'
[[ "$NOTES_2" != *'## [2.0.0]'* ]] || fail '2.0.0 notes should omit the section heading'
[[ "$NOTES_2" != *'## [1.1.0]'* ]] || fail '2.0.0 notes should not include 1.1.0'
[[ "$NOTES_2" != *'Unreleased'* ]] || fail '2.0.0 notes should not include Unreleased'
SUM_AFTER="$(shasum -a 256 -- "$ROOT/CHANGELOG.md" | awk '{print $1}')"
[[ "$SUM_BEFORE" == "$SUM_AFTER" ]] || fail 'changelog --notes must not rewrite CHANGELOG.md'
pass 'changelog --notes prints one version without rewriting CHANGELOG.md'

if /bin/bash "$ROOT/scripts/changelog.sh" --notes 1.0.0/beta 2> "$TMP/notes-err"; then
  fail 'changelog --notes should reject a version with a slash'
fi
grep -F 'Usage:' "$TMP/notes-err" > /dev/null || fail 'invalid notes version should print usage'
pass 'changelog --notes rejects unsafe version strings'

if /bin/bash "$ROOT/scripts/changelog.sh" --notes 9.9.9 2> "$TMP/notes-missing"; then
  fail 'changelog --notes should fail when the section is missing'
fi
grep -F 'No changelog section for 9.9.9' "$TMP/notes-missing" > /dev/null \
  || fail 'missing notes version should say the section is absent'
pass 'changelog --notes fails when the version is not in CHANGELOG.md'

NOTES_BETA="$(/bin/bash "$ROOT/scripts/changelog.sh" --notes 1.0.0-beta)" \
  || fail 'changelog --notes 1.0.0-beta should read the section from that tag'
[[ "$NOTES_BETA" == *'install Neovim and local tools'* ]] \
  || fail '1.0.0-beta notes should come from the tagged CHANGELOG.md'
[[ "$NOTES_BETA" != *'organize modules and update the landing page'* ]] \
  || fail '1.0.0-beta notes should not use the later 1.0.0 section'
pass 'changelog --notes reads a dropped prerelease section from its tag'

for skill in .cursor/skills/release/SKILL.md .claude/skills/release/SKILL.md .codex/skills/release/SKILL.md; do
  assert_file_has "$ROOT/$skill" 'scripts/changelog.sh --notes'
  assert_file_has "$ROOT/$skill" '--notes-file'
done
diff -q -- "$ROOT/.cursor/skills/release/SKILL.md" "$ROOT/.claude/skills/release/SKILL.md" > /dev/null \
  || fail 'release skill copies must stay identical'
diff -q -- "$ROOT/.cursor/skills/release/SKILL.md" "$ROOT/.codex/skills/release/SKILL.md" > /dev/null \
  || fail 'release skill copies must stay identical'
pass 'release skill attaches changelog notes to the tag and GitHub release'

printf '\n%s\n' "All $PASS bump tests passed"
