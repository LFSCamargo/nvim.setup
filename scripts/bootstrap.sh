#!/usr/bin/env bash
# Bootstrap nvim.setup without a manual clone.
# curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash
set -euo pipefail

REPO_DEFAULT='https://github.com/LFSCamargo/nvim.setup.git'
REPO="${NVIM_SETUP_REPO:-$REPO_DEFAULT}"
BRANCH="${NVIM_SETUP_BRANCH:-main}"
DEST="${NVIM_SETUP_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim.setup}"

say() { printf '\n%s\n' "$*"; }
die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat << 'EOF'
Install nvim.setup: fetch the repo, install Neovim and other dependencies,
install icon fonts, then deploy the config.

Usage:
  curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash
  curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash -s -- --preview

  ./scripts/bootstrap.sh            # from a clone: skip fetch, install here
  ./scripts/bootstrap.sh --preview  # NVIM_APPNAME=nvim-preview
  curl ... | bash -s -- --version v1.1.0

Options:
  --preview         Install alongside your current Neovim config
  --version <tag>   Install that Git tag (v1.1.0). Accepts 1.1.0 as well.
  -h, --help        Show this help

Environment:
  NVIM_APPNAME        Neovim app name (default: nvim)
  NVIM_SETUP_HOME     Clone destination (default: ~/.local/share/nvim.setup)
  NVIM_SETUP_REPO     Git URL (default: official GitHub repo)
  NVIM_SETUP_BRANCH   Branch or tag (default: main, overridden by --version)
EOF
}

have() { command -v "$1" > /dev/null 2>&1; }

export PATH="$HOME/.local/bin:$HOME/.local/opt/nvim/bin:$HOME/.local/opt/node/bin:$HOME/.cargo/bin:${PATH-}"

load_brew() {
  have brew && return 0
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done
  return 1
}

ensure_homebrew() {
  load_brew && return 0
  have curl || die 'curl is required to install Homebrew.'
  say 'Installing Homebrew (may ask for a password)...'
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || die 'Homebrew installed but brew is not on PATH. Open a new terminal and retry.'
}

linux_pkg() {
  local elevated=()
  if [[ "$(id -u)" != 0 ]]; then
    have sudo || die 'sudo is required to install packages on Linux.'
    elevated=(sudo)
  fi
  if have apt-get; then
    "${elevated[@]}" apt-get update
    "${elevated[@]}" apt-get install -y git curl tar unzip make ca-certificates
  elif have dnf; then
    "${elevated[@]}" dnf install -y git curl tar unzip make ca-certificates
  elif have pacman; then
    "${elevated[@]}" pacman -Syu --needed git curl tar unzip make ca-certificates
  else
    die 'Supported package managers: Homebrew, apt, dnf, pacman.'
  fi
}

ensure_fetch_tools() {
  case "$(uname -s)" in
    Darwin)
      have curl || die 'curl is required on macOS.'
      if ! have git; then
        ensure_homebrew
        brew install git
      fi
      ;;
    Linux)
      if ! have git || ! have curl || ! have make || ! have tar || ! have unzip; then
        linux_pkg
      fi
      ;;
    *) die 'Supported platforms: macOS and Linux' ;;
  esac
  have git || die 'git is required.'
  have curl || die 'curl is required.'
}

validate_repo() {
  case "$REPO" in
    *$'\n'* | *[[:space:]]*) die 'NVIM_SETUP_REPO must be a single GitHub URL.' ;;
    https://github.com/*/* | git@github.com:*) ;;
    *) die 'NVIM_SETUP_REPO must be a GitHub https or ssh URL.' ;;
  esac
}

normalize_ref() {
  local raw="$1"
  if [[ "$raw" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.]+)?$ ]]; then
    raw="v$raw"
  fi
  BRANCH="$raw"
}

validate_branch() {
  case "$BRANCH" in
    '' | *..* | *[[:space:]]* | -*) die 'Invalid NVIM_SETUP_BRANCH.' ;;
  esac
  [[ "$BRANCH" =~ ^[A-Za-z0-9._/-]+$ ]] || die 'Invalid NVIM_SETUP_BRANCH.'
}

fetch_ref() {
  local dest="$1"
  if [[ "$BRANCH" == main || "$BRANCH" == master ]]; then
    git -C "$dest" fetch --depth 1 origin "$BRANCH"
    git -C "$dest" checkout --force "$BRANCH"
    git -C "$dest" pull --ff-only origin "$BRANCH"
    return 0
  fi
  if git -C "$dest" fetch --depth 1 origin "refs/tags/$BRANCH:refs/tags/$BRANCH"; then
    git -C "$dest" checkout --force "$BRANCH"
    return 0
  fi
  git -C "$dest" fetch --depth 1 origin "$BRANCH"
  git -C "$dest" checkout --force "$BRANCH"
}

validate_dest() {
  [[ -n "$DEST" && "$DEST" != / ]] || die 'Invalid NVIM_SETUP_HOME.'
  case "$DEST" in
    *$'\n'* | *[[:space:]]*) die 'NVIM_SETUP_HOME must be a single path.' ;;
  esac
}

checkout_root() {
  local src root
  src="${BASH_SOURCE[0]-}"
  [[ -n "$src" ]] || return 1
  case "$src" in
    /dev/* | /proc/*) return 1 ;;
  esac
  [[ -f "$src" ]] || return 1
  root="$(cd -- "$(dirname -- "$src")/.." && pwd -P)" || return 1
  [[ -f "$root/scripts/install.sh" && -f "$root/scripts/deps.sh" && -f "$root/nvim/init.lua" ]] || return 1
  printf '%s\n' "$root"
}

ensure_repo() {
  local root
  if root="$(checkout_root)"; then
    say "Using existing checkout at $root"
    SETUP_ROOT="$root"
    return 0
  fi
  validate_repo
  validate_branch
  validate_dest
  if [[ -e "$DEST" ]]; then
    [[ -d "$DEST/.git" ]] || die "Refusing to overwrite $DEST (not a git checkout)."
    say "Updating $DEST"
    fetch_ref "$DEST"
  else
    say "Cloning nvim.setup into $DEST"
    mkdir -p -- "$(dirname -- "$DEST")"
    git clone --branch "$BRANCH" --depth 1 -- "$REPO" "$DEST"
  fi
  SETUP_ROOT="$DEST"
}

ensure_login_path() {
  local line marker rc
  line='export PATH="$HOME/.local/bin:$HOME/.local/opt/nvim/bin:$HOME/.local/opt/node/bin:$HOME/.cargo/bin:$PATH"'
  marker='# nvim.setup PATH'
  for rc in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
    if [[ -f "$rc" ]] && grep -F "$marker" "$rc" > /dev/null 2>&1; then
      return 0
    fi
  done
  rc="$HOME/.profile"
  if [[ -f "$HOME/.zprofile" || ! -f "$HOME/.profile" && ! -f "$HOME/.bashrc" ]]; then
    rc="$HOME/.zprofile"
  elif [[ -f "$HOME/.bashrc" ]]; then
    rc="$HOME/.bashrc"
  fi
  printf '\n%s\n%s\n' "$marker" "$line" >> "$rc"
  say "Added PATH to $rc. Open a new terminal if nvim is not found."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --preview)
      export NVIM_APPNAME="${NVIM_APPNAME:-nvim-preview}"
      shift
      ;;
    --version)
      [[ $# -ge 2 ]] || die '--version needs a tag like v1.1.0'
      normalize_ref "$2"
      shift 2
      ;;
    --version=*)
      normalize_ref "${1#--version=}"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unknown option: $1"
      ;;
  esac
done

if [[ "$(id -u)" -eq 0 ]]; then
  die 'Do not run this installer as root. It will sudo only for Linux packages.'
fi

ensure_login_path
ensure_fetch_tools
ensure_repo
say "Installing dependencies (Neovim, Node, language tools)..."
bash "$SETUP_ROOT/scripts/deps.sh"
say 'Installing icon fonts (Symbols Nerd Font, Monocraft Nerd Font)...'
bash "$SETUP_ROOT/scripts/fonts.sh"
say 'Installing the Neovim configuration...'
bash "$SETUP_ROOT/scripts/install.sh"
say "nvim.setup is ready. Open a project with: ${NVIM_APPNAME:+NVIM_APPNAME=$NVIM_APPNAME }nvim ."
