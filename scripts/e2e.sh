#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
need nvim
need stty
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-e2e.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/state" "$work_dir/runtime"
cat > "$work_dir/bin/codex" <<'SCRIPT'
#!/bin/sh
stty raw -echo
cat > "$E2E_DIR/$(basename "$0")-input"
SCRIPT
cp "$work_dir/bin/codex" "$work_dir/bin/agent"
chmod +x "$work_dir/bin/codex" "$work_dir/bin/agent"
export E2E_DIR="$work_dir"
export XDG_STATE_HOME="$work_dir/state"
export XDG_RUNTIME_DIR="$work_dir/runtime"
export PATH="$work_dir/bin:$PATH"
nvim --clean --headless -n -l "$SETUP_ROOT/scripts/tests/e2e.lua"
