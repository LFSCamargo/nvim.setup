#!/usr/bin/env bash
set -euo pipefail
SETUP_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_NAME="${NVIM_APPNAME:-nvim}"
case "$APP_NAME" in ''|.|..|*/*) printf 'Invalid NVIM_APPNAME\n' >&2; exit 1;; esac
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/$APP_NAME"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim.setup"
export SETUP_ROOT CONFIG_DIR STATE_DIR
say() { printf '\n%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing $1. Run make deps or install it and retry."; }
run_lua() {
  SETUP_LUA_FILE="$1" nvim --headless -n '+lua local ok, err = pcall(dofile, vim.env.SETUP_LUA_FILE); if not ok then print(err); vim.cmd("cquit 1") end'
}
