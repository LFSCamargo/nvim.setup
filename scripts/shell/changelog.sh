#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"

section_from_changelog() {
  awk -v version="$1" '
    BEGIN { start = "## [" version "]" }
    !grab {
      if ($0 == start || index($0, start " ") == 1) grab = 1
      next
    }
    /^## \[/ { exit }
    /^\[/ { exit }
    { print }
  '
}

trim_notes() {
  local notes="$1"
  notes="${notes#"${notes%%[![:space:]]*}"}"
  notes="${notes%"${notes##*[![:space:]]}"}"
  printf '%s' "$notes"
}

print_release_notes() {
  local version="${1:-}" file notes tagged
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9][A-Za-z0-9.-]*)?$ ]] \
    || die 'Usage: make changelog NOTES=1.2.3 or bash scripts/changelog.sh --notes 1.2.3'
  file="$SETUP_ROOT/CHANGELOG.md"
  [[ -f "$file" ]] || die "Missing $file"
  notes="$(trim_notes "$(section_from_changelog "$version" < "$file")")"
  if [[ -z "$notes" ]]; then
    tagged="$(git -C "$SETUP_ROOT" show "v${version}:CHANGELOG.md" 2> /dev/null)" || tagged=""
    [[ -n "$tagged" ]] && notes="$(trim_notes "$(printf '%s\n' "$tagged" | section_from_changelog "$version")")"
  fi
  [[ -n "$notes" ]] || die "No changelog section for ${version}"
  printf '%s\n' "$notes"
}

if [[ "${1:-}" == '--notes' ]]; then
  print_release_notes "${2:-}"
  exit 0
fi

need git
need node
[[ -d "$SETUP_ROOT/node_modules/@commitlint/lint" ]] || die 'Missing commitlint packages. Run pnpm install and retry.'
node "$SETUP_ROOT/scripts/changelog.mjs"
