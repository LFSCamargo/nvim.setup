#!/usr/bin/env bash
set -euo pipefail
SETUP_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_NAME="${NVIM_APPNAME:-nvim}"
case "$APP_NAME" in ''|.|..|*/*) printf 'Invalid NVIM_APPNAME\n' >&2; exit 1;; esac
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/$APP_NAME"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim.setup"
export SETUP_ROOT CONFIG_DIR STATE_DIR
export PATH="$HOME/.local/bin:$HOME/.local/opt/nvim/bin:$HOME/.local/opt/node/bin:$HOME/.cargo/bin:$PATH"
say() { printf '\n%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing $1. Run scripts/bootstrap.sh or make deps, then retry."; }
file_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  else
    shasum -a 256 -- "$1" | awk '{print $1}'
  fi
}
verify_sha256() {
  local file="$1" expected="$2" actual
  actual="$(file_sha256 "$file")"
  [[ -n "$expected" && "$actual" == "$expected" ]] || die "Checksum mismatch for $file"
}
run_lua() {
  SETUP_LUA_FILE="$1" nvim --headless -n '+lua local ok, err = pcall(dofile, vim.env.SETUP_LUA_FILE); if not ok then print(err); vim.cmd("cquit 1") end'
}
