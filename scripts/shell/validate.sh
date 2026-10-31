#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
export PATH="$HOME/.local/bin:$PATH"
bash "$SETUP_ROOT/scripts/doctor.sh"
[[ -f "$CONFIG_DIR/init.lua" ]] || die 'No installed config. Run make install.'
run_lua "$SETUP_ROOT/scripts/lua/validate.lua"
