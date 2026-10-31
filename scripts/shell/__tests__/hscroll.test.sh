#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/../../.." && pwd -P)"
PASS=0
fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
pass() {
  printf 'PASS: %s\n' "$*"
  PASS=$((PASS + 1))
}

bash -n "$ROOT/scripts/hscroll.sh"
bash -n "$ROOT/scripts/shell/hscroll.sh"
pass 'hscroll scripts parse'

grep -F 'pgrep -x nvim-setup-hscroll' "$ROOT/scripts/shell/hscroll.sh" > /dev/null \
  || fail 'ensure must find the helper by exact name'
grep -F -- '--remote-expr' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must RPC Neovim over --remote-expr'
grep -F 'isSafeSocket' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must reject unexpected socket names'
grep -F 'com.apple.Terminal' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must inject when Terminal.app is focused'
grep -F 'com.googlecode.iterm2' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must inject when iTerm is focused'
grep -F 'dev.warp.Warp' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must inject when Warp is focused'
grep -F 'proc.terminate()' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must time out stuck nvim RPC children'
grep -F 'scrollWheelEventPointDeltaAxis2' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null \
  || fail 'worker must read pixel trackpad deltas, not only line ticks'
grep -F 'EnvironmentVariables' "$ROOT/scripts/shell/hscroll.sh" > /dev/null \
  || fail 'LaunchAgent must set PATH so nvim is found'
grep -F 'chmod 755 "$BIN"' "$ROOT/scripts/shell/hscroll.sh" > /dev/null \
  || fail 'chmod must not use GNU -- on macOS'
if grep -F 'sh -c' "$ROOT/scripts/darwin/hscroll.swift" > /dev/null; then
  fail 'worker must not spawn nvim through a shell string'
fi
pass 'worker talks to Neovim over a guarded socket'

if command -v swiftc > /dev/null 2>&1; then
  swiftc -parse "$ROOT/scripts/darwin/hscroll.swift" || fail 'hscroll.swift must parse'
  pass 'hscroll.swift parses'
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-hscroll.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin"
for cmd in uname id env dirname basename; do
  if [[ -x "/usr/bin/$cmd" ]]; then
    ln -s "/usr/bin/$cmd" "$TMP/bin/$cmd"
  elif [[ -x "/bin/$cmd" ]]; then
    ln -s "/bin/$cmd" "$TMP/bin/$cmd"
  fi
done
env -i HOME="$TMP" PATH="$TMP/bin:/bin" \
  XDG_STATE_HOME="$TMP/state" \
  /bin/bash "$ROOT/scripts/hscroll.sh" install > "$TMP/out" || true
if [[ -e "$TMP/.local/bin/nvim-setup-hscroll" ]]; then
  fail 'install must not write a binary when swiftc is missing'
fi
pass 'install is safe without a Darwin toolchain'

printf 'hscroll tests: %s passed\n' "$PASS"
