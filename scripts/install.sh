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
bash "$SETUP_ROOT/scripts/plugins.sh" restore
run_lua "$CONFIG_DIR/scripts/install-parsers.lua"
run_lua "$CONFIG_DIR/scripts/install-tools.lua"
bash "$SETUP_ROOT/scripts/validate.sh"
say 'Setup installed. Restart Neovim. Backups are kept even if dependency installation fails.'
