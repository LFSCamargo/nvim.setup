#!/usr/bin/env bash
# Install Nerd Font files, bake them into Monocraft Nerd Font, then point Warp at it.
source "$(dirname -- "$0")/common.sh"
need curl
need python3

SYMBOLS_URL="${NVIM_SETUP_SYMBOLS_URL:-https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip}"
SYMBOLS_SHA="${NVIM_SETUP_SYMBOLS_SHA:-fdca3682534f6f65e1ccb2345b0362ccf67d9b8eca7c8025330946e93e2473bc}"
MONOCRAFT_URL="${NVIM_SETUP_MONOCRAFT_URL:-https://github.com/IdreesInc/Monocraft/releases/download/v4.2.1/Monocraft-nerd-fonts-patched.ttc}"
MONOCRAFT_SHA="${NVIM_SETUP_MONOCRAFT_SHA:-67f88ff9e7c6560f6cf60fb062fd353a72f62dc2654462950c65b63ed53d9754}"
MONOCRAFT_NERD_NAME="${NVIM_SETUP_MONOCRAFT_NERD_NAME:-Monocraft Nerd Font}"

font_dir() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' "$HOME/Library/Fonts" ;;
    Linux) printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/nvim-setup" ;;
    *) die 'Supported platforms: macOS and Linux' ;;
  esac
}

fetch_verified() {
  local url="$1" sha="$2" dest="$3" tmp
  if [[ -f "$dest" && "$(file_sha256 "$dest")" == "$sha" ]]; then
    return 0
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  tmp="$dest.partial"
  rm -f -- "$tmp"
  curl -fsSL -o "$tmp" -- "$url"
  verify_sha256 "$tmp" "$sha"
  mv -- "$tmp" "$dest"
}

install_symbols() {
  local dir="$1" cache="$2" zip="$cache/NerdFontsSymbolsOnly.zip"
  fetch_verified "$SYMBOLS_URL" "$SYMBOLS_SHA" "$zip"
  python3 - "$zip" "$dir" << 'PY'
import sys
from pathlib import Path
from zipfile import ZipFile
src, dest = Path(sys.argv[1]), Path(sys.argv[2])
want = {'SymbolsNerdFont-Regular.ttf', 'SymbolsNerdFontMono-Regular.ttf'}
found = set()
with ZipFile(src) as zf:
    for info in zf.infolist():
        name = Path(info.filename).name
        if name in want and not info.is_dir():
            dest.joinpath(name).write_bytes(zf.read(info.filename))
            found.add(name)
if found != want:
    sys.exit(1)
PY
  [[ -f "$dir/SymbolsNerdFont-Regular.ttf" && -f "$dir/SymbolsNerdFontMono-Regular.ttf" ]] \
    || die 'Nerd Fonts Symbols Only zip did not contain the expected TTF files'
}

is_sfnt() {
  python3 - "$1" << 'PY'
import sys
from pathlib import Path
magic = Path(sys.argv[1]).read_bytes()[:4]
sys.exit(0 if magic in (b'\x00\x01\x00\x00', b'ttcf', b'OTTO', b'true') else 1)
PY
}

ensure_fonttools() {
  local dest="$STATE_DIR/python"
  export PYTHONPATH="$dest${PYTHONPATH:+:$PYTHONPATH}"
  python3 -c 'import fontTools' 2> /dev/null && return 0
  mkdir -p -- "$dest"
  python3 -m pip install --quiet --disable-pip-version-check --target "$dest" 'fonttools==4.60.2' \
    || die 'python3 -m pip is required to bake icon glyphs into the terminal font'
  python3 -c 'import fontTools' 2> /dev/null || die 'fonttools installed but could not be imported'
}

install_monocraft_nerd() {
  local dir="$1" cache="$2"
  local ttc="$cache/Monocraft-nerd-fonts-patched.ttc"
  local out="$dir/MonocraftNerdFont-Regular.ttf"
  fetch_verified "$MONOCRAFT_URL" "$MONOCRAFT_SHA" "$ttc"
  if is_sfnt "$ttc" && is_sfnt "$dir/SymbolsNerdFontMono-Regular.ttf"; then
    ensure_fonttools
    if ! python3 "$SETUP_ROOT/scripts/python/overlay_fonts.py" \
      "$ttc" "$dir/SymbolsNerdFontMono-Regular.ttf" "$out" \
      2> "$cache/overlay.err"; then
      cat -- "$cache/overlay.err" >&2
      die 'Failed to bake Nerd Font glyphs into Monocraft Nerd Font'
    fi
    rm -f -- "$dir/Monocraft-nerd-fonts-patched.ttc"
  else
    cp -- "$ttc" "$dir/Monocraft-nerd-fonts-patched.ttc"
  fi
  rm -f -- "$dir/termicons.ttf"
}

replace_exact_line() {
  local file="$1" from="$2" to="$3" tmp
  grep -Fqx -- "$from" "$file" || return 0
  tmp="$(mktemp "${TMPDIR:-/tmp}/nvim-setup-font.XXXXXX")"
  awk -v from="$from" -v to="$to" '{ if ($0 == from) print to; else print }' "$file" > "$tmp"
  mv -- "$tmp" "$file"
}

configure_warp() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  replace_exact_line "$file" 'font_name = "Monocraft"' "font_name = \"$MONOCRAFT_NERD_NAME\""
}

append_once() {
  local file="$1" marker="$2"
  shift 2
  mkdir -p -- "$(dirname -- "$file")"
  if [[ -f "$file" ]] && grep -Fqx -- "$marker" "$file"; then
    return 0
  fi
  {
    [[ -f "$file" && -s "$file" ]] && printf '\n'
    printf '%s\n' "$marker" "$@"
  } >> "$file"
}

configure_kitty() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  append_once "$file" '# nvim.setup-fonts' \
    'symbol_map U+E000-U+F8FF,U+F0000-U+F1FFF Symbols Nerd Font Mono'
}

configure_ghostty() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  append_once "$file" '# nvim.setup-fonts' \
    'font-family = Symbols Nerd Font Mono'
}

configure_fontconfig() {
  local file="$1"
  [[ "$(uname -s)" == Linux ]] || return 0
  mkdir -p -- "$(dirname -- "$file")"
  cat > "$file" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Symbols Nerd Font Mono</family>
    </prefer>
  </alias>
</fontconfig>
EOF
}

dir="$(font_dir)"
cache="$STATE_DIR/fonts"
mkdir -p -- "$dir" "$cache"
say "Installing icon fonts to $dir"
install_symbols "$dir" "$cache"
install_monocraft_nerd "$dir" "$cache"
if command -v fc-cache > /dev/null 2>&1; then
  fc-cache -f "$dir" > /dev/null 2>&1 || true
fi

configure_warp "$HOME/.warp/settings.toml"
configure_warp "$HOME/.warp-preview/settings.toml"
configure_warp "${XDG_CONFIG_HOME:-$HOME/.config}/warp-terminal/settings.toml"
configure_warp "${XDG_CONFIG_HOME:-$HOME/.config}/warp-terminal-preview/settings.toml"
configure_kitty "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
configure_ghostty "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
configure_fontconfig "${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d/50-nvim-setup-icons.conf"

say "Icon fonts installed (Symbols Nerd Font, Monocraft Nerd Font). Restart the terminal to load them."
