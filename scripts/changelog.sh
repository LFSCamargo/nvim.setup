#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
need git
need node
[[ -d "$SETUP_ROOT/node_modules/@commitlint/lint" ]] || die 'Missing commitlint packages. Run pnpm install and retry.'
node "$SETUP_ROOT/scripts/changelog.mjs"
