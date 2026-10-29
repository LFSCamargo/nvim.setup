#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
case "$(uname -s)" in
  Darwin)
    need brew
    brew install neovim git curl unzip ripgrep fd fzf tree-sitter-cli node go rust python
    ;;
  Linux)
    elevated=()
    if [[ $(id -u) != 0 ]]; then need sudo; elevated=(sudo); fi
    if command -v apt-get >/dev/null 2>&1; then
      "${elevated[@]}" apt-get update
      "${elevated[@]}" apt-get install -y neovim git curl tar unzip build-essential ripgrep fd-find fzf nodejs npm golang-go cargo python3
    elif command -v dnf >/dev/null 2>&1; then
      "${elevated[@]}" dnf install -y neovim git curl tar unzip gcc gcc-c++ make ripgrep fd-find fzf nodejs npm golang cargo python3
    elif command -v pacman >/dev/null 2>&1; then
      "${elevated[@]}" pacman -Syu --needed neovim git curl tar unzip base-devel ripgrep fd fzf tree-sitter-cli nodejs npm go rust python
    else die 'Supported package managers: Homebrew, apt, dnf, pacman. See README for manual prerequisites.'; fi
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
    need cargo
    if ! command -v tree-sitter >/dev/null 2>&1; then
      cargo install --locked tree-sitter-cli
    fi
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
    ;;
  *) die 'Supported platforms: macOS and Linux';;
esac
bash "$SETUP_ROOT/scripts/doctor.sh"
