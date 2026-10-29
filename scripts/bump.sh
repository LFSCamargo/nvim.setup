#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
[[ "${1:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'Usage: make bump VERSION=1.2.3'
printf '%s\n' "$1" > "$SETUP_ROOT/VERSION"
say "Setup version set to $1. Run make changelog, then commit VERSION and CHANGELOG.md and tag v$1 when ready."
