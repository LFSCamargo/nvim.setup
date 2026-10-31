#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
export PATH="$HOME/.local/bin:$PATH"
bash "$SETUP_ROOT/scripts/doctor.sh"
mkdir -p "$(dirname -- "$CONFIG_DIR")" "$STATE_DIR/backups"
staging=$(mktemp -d "$(dirname -- "$CONFIG_DIR")/.nvim-setup.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
cp -R "$SETUP_ROOT/nvim/." "$staging/"
if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
  backup=$(mktemp -d "$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S).XXXXXX")
  mv -- "$CONFIG_DIR" "$backup/config"
  say "Previous config saved to $backup/config"
fi
mv -- "$staging" "$CONFIG_DIR"
printf '%s\n' "$(cat "$SETUP_ROOT/VERSION")" > "$CONFIG_DIR/.setup-version"
say "Installed configuration to $CONFIG_DIR"
wrapper_src="$SETUP_ROOT/scripts/shell/nvim-wrapper.sh"
wrapper_dst="$HOME/.local/bin/nvim"
mkdir -p "$HOME/.local/bin"
if [[ -e "$wrapper_dst" || -L "$wrapper_dst" ]]; then
  if grep -q 'nvim.setup-wrapper' "$wrapper_dst" 2> /dev/null; then
    cp -- "$wrapper_src" "$wrapper_dst"
    chmod +x "$wrapper_dst"
  else
    say "Kept existing $wrapper_dst (not the nvim.setup wrapper). nvim --clean will use Neovim's factory reset until this path is our wrapper."
  fi
else
  cp -- "$wrapper_src" "$wrapper_dst"
  chmod +x "$wrapper_dst"
  say "Installed nvim wrapper to $wrapper_dst so nvim --clean skips restored tabs."
fi
bash "$SETUP_ROOT/scripts/fonts.sh"
bash "$SETUP_ROOT/scripts/plugins.sh" restore
run_lua "$CONFIG_DIR/scripts/install-parsers.lua"
run_lua "$CONFIG_DIR/scripts/install-tools.lua"
bash "$SETUP_ROOT/scripts/validate.sh"
say 'Setup installed. Restart Neovim. Backups are kept even if dependency installation fails.'
