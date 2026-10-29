#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
need nvim
[[ -f "$CONFIG_DIR/init.lua" ]] || die 'Install the configuration first: make install'
export SETUP_PLUGIN_MODE="${1:-restore}"
case "$SETUP_PLUGIN_MODE" in restore|upgrade) ;; *) die 'Expected restore or upgrade';; esac
run_lua "$SETUP_ROOT/scripts/lua/plugins.lua"
