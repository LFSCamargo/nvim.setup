#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"

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

nvim_meets_min() {
  command -v nvim >/dev/null 2>&1 || return 1
  NVIM_WRAPPER=0 nvim --clean --headless -n '+lua if vim.fn.has("nvim-0.12") == 0 then vim.cmd("cquit 1") end' +qa >/dev/null 2>&1
}

node_meets_min() {
  command -v node >/dev/null 2>&1 || return 1
  node -e 'if (Number(process.versions.node.split(".")[0]) < 22) process.exit(1)' >/dev/null 2>&1
}

target_arch() {
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) printf '%s %s\n' nvim-linux-x86_64.tar.gz linux-x64 ;;
    Linux-aarch64 | Linux-arm64) printf '%s %s\n' nvim-linux-arm64.tar.gz linux-arm64 ;;
    Darwin-arm64) printf '%s %s\n' nvim-macos-arm64.tar.gz darwin-arm64 ;;
    Darwin-x86_64) printf '%s %s\n' nvim-macos-x86_64.tar.gz darwin-x64 ;;
    *) die "Unsupported architecture: $(uname -s) $(uname -m)" ;;
  esac
}

install_neovim_release() {
  local asset url sumfile expected dest work top
  asset="$(target_arch | awk '{print $1}')"
  dest="$HOME/.local/opt/nvim"
  url="https://github.com/neovim/neovim/releases/latest/download/$asset"
  say "Installing Neovim 0.12+ from $url"
  work="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-nvim.XXXXXX")"
  curl -fsSL -- "$url" -o "$work/$asset"
  sumfile="$(curl -fsSL -- "$url.sha256sum")"
  expected="$(printf '%s\n' "$sumfile" | awk '{print $1; exit}')"
  verify_sha256 "$work/$asset" "$expected"
  mkdir -p "$work/extract"
  tar -xf "$work/$asset" -C "$work/extract"
  top="$(find "$work/extract" -mindepth 1 -maxdepth 1 -type d | awk 'NR==1 { print; exit }')"
  [[ -n "$top" && -d "$top" ]] || die 'Unexpected Neovim archive layout'
  mkdir -p "$HOME/.local/opt"
  rm -rf -- "$dest"
  mv -- "$top" "$dest"
  rm -rf -- "$work"
  [[ -x "$dest/bin/nvim" ]] || die "Neovim installed but $dest/bin/nvim is missing"
}

install_node_release() {
  local node_arch sums line expected tarball url dest work top
  node_arch="$(target_arch | awk '{print $2}')"
  dest="$HOME/.local/opt/node"
  say "Installing Node.js 22+ for $node_arch"
  sums="$(curl -fsSL -- https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt)"
  line="$(printf '%s\n' "$sums" | awk -v arch="$node_arch" '$2 ~ ("^node-v[0-9.]+-" arch "[.]tar[.]gz$") { print; exit }')"
  expected="$(printf '%s\n' "$line" | awk '{print $1}')"
  tarball="$(printf '%s\n' "$line" | awk '{print $2}')"
  [[ -n "$expected" && -n "$tarball" ]] || die "Could not find a Node.js 22 archive for $node_arch"
  url="https://nodejs.org/dist/latest-v22.x/$tarball"
  work="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-node.XXXXXX")"
  curl -fsSL -- "$url" -o "$work/$tarball"
  verify_sha256 "$work/$tarball" "$expected"
  mkdir -p "$work/extract"
  tar -xf "$work/$tarball" -C "$work/extract"
  top="$(find "$work/extract" -mindepth 1 -maxdepth 1 -type d | awk 'NR==1 { print; exit }')"
  [[ -n "$top" && -d "$top" ]] || die 'Unexpected Node.js archive layout'
  mkdir -p "$HOME/.local/opt"
  rm -rf -- "$dest"
  mv -- "$top" "$dest"
  rm -rf -- "$work"
  [[ -x "$dest/bin/node" && -x "$dest/bin/npm" ]] || die "Node.js installed but $dest/bin/node is missing"
}

ensure_supported_nvim() {
  nvim_meets_min && return 0
  if command -v brew >/dev/null 2>&1; then
    brew install neovim
    nvim_meets_min && return 0
  fi
  install_neovim_release
  nvim_meets_min || die 'Neovim 0.12+ is required and could not be installed.'
}

ensure_supported_node() {
  node_meets_min && return 0
  if command -v brew >/dev/null 2>&1; then
    brew install node
    node_meets_min && return 0
  fi
  install_node_release
  node_meets_min || die 'Node.js 22+ is required and could not be installed.'
}

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

ensure_supported_nvim
ensure_supported_node
bash "$SETUP_ROOT/scripts/doctor.sh"
