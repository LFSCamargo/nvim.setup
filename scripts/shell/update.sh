#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
need git
[[ -z "$(git -C "$SETUP_ROOT" status --porcelain)" ]] || die 'Commit or stash repository edits before updating.'
if git -C "$SETUP_ROOT" rev-parse --abbrev-ref '@{upstream}' > /dev/null 2>&1; then
  git -C "$SETUP_ROOT" pull --ff-only
else
  say 'No upstream configured; applying the current local checkout.'
fi
bash "$SETUP_ROOT/scripts/install.sh"
