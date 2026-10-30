#!/usr/bin/env bash
# Drive scripts/fonts.sh the way install/bootstrap does, with stubbed downloads.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd -P)"
PASS=0
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; PASS=$((PASS + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-fonts.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

write_stub() {
  local path="$1"
  mkdir -p -- "$(dirname -- "$path")"
  cat >"$path"
  chmod +x "$path"
}

assert_file_has() {
  local file="$1" needle="$2"
  grep -F -- "$needle" "$file" >/dev/null 2>&1 || fail "$file missing '$needle'"
}

# 1. Install (and therefore bootstrap) must install icon fonts.
assert_file_has "$ROOT/scripts/install.sh" 'scripts/fonts.sh'
if grep -F 'termicons.mskelton.dev' "$ROOT/scripts/fonts.sh" >/dev/null; then
  fail 'fonts.sh should not download Termicons'
fi
assert_file_has "$ROOT/scripts/fonts.sh" 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip'
assert_file_has "$ROOT/scripts/fonts.sh" 'https://github.com/IdreesInc/Monocraft/releases/download/v4.2.1/Monocraft-nerd-fonts-patched.ttc'
assert_file_has "$ROOT/scripts/fonts.sh" 'verify_sha256'
assert_file_has "$ROOT/scripts/fonts.sh" 'configure_warp'
assert_file_has "$ROOT/scripts/fonts.sh" 'curl -fsSL -o'
assert_file_has "$ROOT/scripts/fonts.sh" 'overlay_fonts.py'
assert_file_has "$ROOT/scripts/overlay_fonts.py" 'Monocraft Nerd Font'
assert_file_has "$ROOT/scripts/bootstrap.sh" 'scripts/install.sh'
assert_file_has "$ROOT/scripts/bootstrap.sh" 'scripts/fonts.sh'
pass 'install.sh and bootstrap.sh run fonts.sh with pinned Nerd Font and Monocraft URLs'

fixtures="$TMP/fixtures"
mkdir -p "$fixtures"
printf 'symbols-regular-dummy\n' >"$fixtures/SymbolsNerdFont-Regular.ttf"
printf 'symbols-mono-dummy\n' >"$fixtures/SymbolsNerdFontMono-Regular.ttf"
printf 'monocraft-nerd-dummy\n' >"$fixtures/Monocraft-nerd-fonts-patched.ttc"
python3 - "$fixtures" <<'PY'
import sys, zipfile
from pathlib import Path
root = Path(sys.argv[1])
with zipfile.ZipFile(root / 'NerdFontsSymbolsOnly.zip', 'w') as zf:
    zf.write(root / 'SymbolsNerdFont-Regular.ttf', 'SymbolsNerdFont-Regular.ttf')
    zf.write(root / 'SymbolsNerdFontMono-Regular.ttf', 'SymbolsNerdFontMono-Regular.ttf')
PY
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  else
    shasum -a 256 -- "$1" | awk '{print $1}'
  fi
}
symbols_sha="$(sha256_of "$fixtures/NerdFontsSymbolsOnly.zip")"
monocraft_sha="$(sha256_of "$fixtures/Monocraft-nerd-fonts-patched.ttc")"

make_bin() {
  local home="$1" os="$2" calls="$3"
  local bin="$home/bin"
  mkdir -p "$bin"
  write_stub "$bin/uname" <<EOF
#!/bin/sh
[ "\${1-}" = -s ] && { printf '%s\n' '$os'; exit 0; }
exec /usr/bin/uname "\$@"
EOF
  write_stub "$bin/curl" <<EOF
#!/bin/sh
out=""
url=""
endopts=0
while [ \$# -gt 0 ]; do
  if [ "\$endopts" -eq 1 ]; then
    case "\$1" in
      -*) printf 'curl does not parse options after --\n' >&2; exit 1 ;;
    esac
    url="\$1"
    shift
    continue
  fi
  case "\$1" in
    --) endopts=1; shift ;;
    -o) out="\$2"; shift 2 ;;
    -*) shift ;;
    *) url="\$1"; shift ;;
  esac
done
printf 'curl %s\n' "\$url" >>'$calls'
case "\$url" in
  *NerdFontsSymbolsOnly.zip) src='$fixtures/NerdFontsSymbolsOnly.zip' ;;
  *Monocraft-nerd-fonts-patched.ttc) src='$fixtures/Monocraft-nerd-fonts-patched.ttc' ;;
  *) printf 'unexpected url %s\n' "\$url" >&2; exit 1 ;;
esac
[ -n "\$out" ] || { printf 'curl missing -o\n' >&2; exit 1; }
cp -- "\$src" "\$out"
EOF
  printf '%s\n' "$bin"
}

run_fonts() {
  local home="$1" os="$2"
  shift 2
  local calls="$home/calls.log"
  mkdir -p "$home"
  : >"$calls"
  local bin
  bin="$(make_bin "$home" "$os" "$calls")"
  env -i \
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin" \
    NVIM_SETUP_SYMBOLS_SHA="$symbols_sha" \
    NVIM_SETUP_MONOCRAFT_SHA="$monocraft_sha" \
    XDG_STATE_HOME="$home/state" \
    XDG_CONFIG_HOME="$home/config" \
    XDG_DATA_HOME="$home/share" \
    /bin/bash "$ROOT/scripts/fonts.sh" "$@"
}

# 2. macOS copies fonts into ~/Library/Fonts and switches Warp Monocraft to the nerd-patched family.
home="$TMP/darwin"
mkdir -p "$home/.warp" "$home/Library/Fonts"
printf 'stale\n' >"$home/Library/Fonts/termicons.ttf"
cat >"$home/.warp/settings.toml" <<'EOF'
[appearance.text]
font_name = "Monocraft"
font_size = 13.0

[agents.warp_agent]
is_any_ai_enabled = false
EOF
mkdir -p "$home/config/kitty"
printf 'font_family Monocraft\n' >"$home/config/kitty/kitty.conf"
run_fonts "$home" Darwin
[[ ! -e "$home/Library/Fonts/termicons.ttf" ]] || fail 'stale Termicons should be removed'
[[ -f "$home/Library/Fonts/SymbolsNerdFont-Regular.ttf" ]] || fail 'Symbols Nerd Font missing from ~/Library/Fonts'
[[ -f "$home/Library/Fonts/SymbolsNerdFontMono-Regular.ttf" ]] || fail 'Symbols Nerd Font Mono missing from ~/Library/Fonts'
[[ -f "$home/Library/Fonts/Monocraft-nerd-fonts-patched.ttc" ]] || fail 'Monocraft Nerd Font missing from ~/Library/Fonts'
assert_file_has "$home/.warp/settings.toml" 'font_name = "Monocraft Nerd Font"'
assert_file_has "$home/.warp/settings.toml" 'is_any_ai_enabled = false'
if grep -Fqx 'font_name = "Monocraft"' "$home/.warp/settings.toml"; then
  fail 'Warp should not keep unpatched Monocraft as the terminal font'
fi
if grep -F 'termicons' "$home/config/kitty/kitty.conf"; then
  fail 'Kitty should not map Termicons'
fi
assert_file_has "$home/config/kitty/kitty.conf" 'Symbols Nerd Font Mono'
pass 'macOS install writes icon fonts and Warp/Kitty fallbacks'

# 3. Linux uses the user fontconfig dir and does not invent a Warp file.
home="$TMP/linux"
run_fonts "$home" Linux
[[ ! -e "$home/share/fonts/nvim-setup/termicons.ttf" ]] || fail 'Linux should not install Termicons'
[[ -f "$home/share/fonts/nvim-setup/SymbolsNerdFontMono-Regular.ttf" ]] || fail 'Linux Symbols Nerd Font missing'
[[ -f "$home/config/fontconfig/conf.d/50-nvim-setup-icons.conf" ]] || fail 'Linux fontconfig fallback missing'
if grep -F 'termicons' "$home/config/fontconfig/conf.d/50-nvim-setup-icons.conf"; then
  fail 'Linux fontconfig should not prefer Termicons'
fi
[[ ! -e "$home/.warp/settings.toml" ]] || fail 'fonts.sh must not create Warp settings'
pass 'Linux install writes fonts and fontconfig fallbacks without creating Warp settings'

# 4. Non-Monocraft Warp fonts stay put; checksum mismatches fail closed.
home="$TMP/keepfont"
mkdir -p "$home/.warp"
printf 'font_name = "JetBrains Mono"\n' >"$home/.warp/settings.toml"
run_fonts "$home" Darwin
assert_file_has "$home/.warp/settings.toml" 'font_name = "JetBrains Mono"'
if grep -F 'Monocraft Nerd Font' "$home/.warp/settings.toml"; then
  fail 'Warp font should stay JetBrains Mono'
fi
pass 'Warp non-Monocraft fonts are left alone'

home="$TMP/badsum"
if env -i \
  HOME="$home" \
  PATH="$(make_bin "$home" Darwin "$home/calls.log"):/usr/bin:/bin" \
  NVIM_SETUP_SYMBOLS_SHA='deadbeef' \
  NVIM_SETUP_MONOCRAFT_SHA="$monocraft_sha" \
  XDG_STATE_HOME="$home/state" \
  /bin/bash "$ROOT/scripts/fonts.sh" 2>"$home.err"; then
  fail 'bad checksum should exit non-zero'
fi
grep -F 'Checksum mismatch' "$home.err" >/dev/null || fail 'checksum failure message missing'
pass 'fonts.sh verifies sha256 before installing'

# 5. Overlay bakes Nerd Font icons at one cell into a font named Monocraft Nerd Font.
if python3 -c 'import fontTools' 2>/dev/null \
  || python3 -m pip install --quiet --disable-pip-version-check --target "$TMP/py" 'fonttools==4.60.2'; then
  export PYTHONPATH="${TMP}/py${PYTHONPATH:+:$PYTHONPATH}"
  overlay_dir="$TMP/overlay"
  mkdir -p "$overlay_dir"
  python3 - "$overlay_dir" <<'PY'
from pathlib import Path
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
import sys

def box(size=180, origin=40):
    pen = TTGlyphPen(None)
    pen.moveTo((origin, origin))
    pen.lineTo((origin + size, origin))
    pen.lineTo((origin + size, origin + size))
    pen.lineTo((origin, origin + size))
    pen.closePath()
    return pen.glyph()

def write_ttf(path, mapping, upem, family):
    glyphs = {'.notdef': box()}
    cmap = {}
    metrics = {'.notdef': (600, 0)}
    order = ['.notdef']
    for cp, name in mapping.items():
        glyphs[name] = box()
        cmap[cp] = name
        metrics[name] = (600, 0)
        order.append(name)
    fb = FontBuilder(upem, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({'familyName': family, 'styleName': 'Regular'})
    fb.setupOS2()
    fb.setupPost()
    fb.save(path)

root = Path(sys.argv[1])
write_ttf(root / 'base.ttf', {0x41: 'A', 0xE000: 'old'}, 1000, 'Monocraft')
write_ttf(root / 'symbols.ttf', {0xF07B: 'nfolder', 0xE000: 'nfile', 0xF0001: 'nextra'}, 2048, 'Symbols')
PY
  python3 "$ROOT/scripts/overlay_fonts.py" \
    "$overlay_dir/base.ttf" "$overlay_dir/symbols.ttf" \
    "$overlay_dir/out.ttf" || fail 'overlay_fonts.py failed on fixture fonts'
  python3 - "$overlay_dir/out.ttf" <<'PY' || fail 'overlay output missing Nerd Font cmap, family name, or one-cell metrics'
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen
font = TTFont(sys.argv[1])
cmap = {}
for table in font['cmap'].tables:
    if table.isUnicode():
        cmap.update(table.cmap)
names = {rec.toUnicode() for rec in font['name'].names if rec.nameID in (1, 4, 16)}
assert 0xD000 not in cmap, 'Termicons Hangul must not be baked in'
assert 0xF07B in cmap, 'Nerd Font folder glyph missing'
assert 0xE000 in cmap, 'Nerd Font file glyph missing'
assert 0xF0001 in cmap, 'Nerd Font supplementary-plane glyph missing'
assert 0x41 in cmap, 'base ASCII missing'
assert 'Monocraft Nerd Font' in names, names
gs = font.getGlyphSet()
pen = BoundsPen(gs)
gs[cmap[0xF07B]].draw(pen)
xmin, ymin, xmax, ymax = pen.bounds
# One ASCII cell is 600. UPM-only scale of the 180-unit fixture box would be ~88.
assert xmax - xmin >= 500, (pen.bounds, 'Nerd Font glyph was not scaled to the cell')
assert font['hmtx'][cmap[0xF07B]][0] == font['hmtx'][cmap[0x41]][0], font['hmtx'][cmap[0xF07B]]
assert font['hmtx'][cmap[0xE000]][0] == font['hmtx'][cmap[0x41]][0], font['hmtx'][cmap[0xE000]]
PY
  pass 'overlay bakes one-cell Nerd Font glyphs into Monocraft Nerd Font'
else
  fail 'fonttools is required to test baking Nerd Font glyphs into Monocraft Nerd Font'
fi

printf '\n%s\n' "All $PASS font tests passed"
