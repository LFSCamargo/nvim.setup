#!/usr/bin/env bash
# Build and run the macOS terminal trackpad helper that RPC-scrolls Neovim.
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

BIN="${HOME}/.local/bin/nvim-setup-hscroll"
SRC="$SETUP_ROOT/scripts/darwin/hscroll.swift"
PLIST="${HOME}/Library/LaunchAgents/com.nvimsetup.hscroll.plist"
LABEL='com.nvimsetup.hscroll'

is_darwin() { [[ "$(uname -s)" == Darwin ]]; }

build() {
  is_darwin || {
    say 'Terminal trackpad helper is macOS only.'
    return 0
  }
  command -v swiftc > /dev/null 2>&1 || {
    say 'swiftc not found; install Xcode Command Line Tools to build the terminal trackpad helper.'
    return 0
  }
  [[ -f "$SRC" ]] || die "Missing $SRC"
  mkdir -p -- "$(dirname -- "$BIN")"
  swiftc -O -o "$BIN" "$SRC"
  chmod 755 "$BIN"
  say "Built $BIN"
}

running() {
  pgrep -x nvim-setup-hscroll > /dev/null 2>&1
}

ensure() {
  is_darwin || return 0
  [[ -x "$BIN" ]] || build
  [[ -x "$BIN" ]] || return 0
  if running; then
    return 0
  fi
  "$BIN" &
}

install_agent() {
  is_darwin || return 0
  [[ -x "$BIN" ]] || build
  [[ -x "$BIN" ]] || return 0
  mkdir -p -- "$(dirname -- "$PLIST")"
  local path_xml
  path_xml="$(printf '%s' "${HOME}/.local/bin:${HOME}/.local/opt/nvim/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin" | sed 's/&/\&amp;/g; s/</\&lt;/g')"
  cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${BIN}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>${path_xml}</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/${LABEL}" > /dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  say "Loaded ${LABEL}. Allow Accessibility for nvim-setup-hscroll if prompted."
}

uninstall_agent() {
  is_darwin || return 0
  launchctl bootout "gui/$(id -u)/${LABEL}" > /dev/null 2>&1 || true
  rm -f -- "$PLIST"
  say "Stopped ${LABEL}. The trackpad helper will not run at login."
}

cmd="${1:-ensure}"
case "$cmd" in
  build) build ;;
  ensure) ensure ;;
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  *) die "Expected build, ensure, install, or uninstall" ;;
esac
