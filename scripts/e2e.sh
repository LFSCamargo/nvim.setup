#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
need nvim
need stty
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-e2e.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/state" "$work_dir/runtime"
export E2E_DIR="$work_dir"
mkdir -p "$work_dir/repo"
git -C "$work_dir/repo" init -q
git -C "$work_dir/repo" config user.name Test
git -C "$work_dir/repo" config user.email test@example.invalid
git -C "$work_dir/repo" config commit.gpgsign false
printf 'before\n' > "$work_dir/repo/changed file.txt"
printf 'before\n' > "$work_dir/repo/deleted.txt"
git -C "$work_dir/repo" add -- 'changed file.txt' deleted.txt
git -C "$work_dir/repo" commit -qm initial
printf 'after\n' > "$work_dir/repo/changed file.txt"
rm -- "$work_dir/repo/deleted.txt"
printf 'new\n' > "$work_dir/repo/new.txt"
printf 'export\n' > "$work_dir/repo/app.ts"
printf 'fn\n' > "$work_dir/repo/lib.rs"
cat > "$work_dir/bin/codex" << 'SCRIPT'
#!/bin/sh
if [ "$1" = "create-chat" ]; then
  echo "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
  exit 0
fi
printf '%s\n' "$*" > "$E2E_DIR/$(basename "$0")-args"
stty raw -echo
cat > "$E2E_DIR/$(basename "$0")-input"
SCRIPT
for bin in agent gemini claude opencode agy; do
  cp "$work_dir/bin/codex" "$work_dir/bin/$bin"
done
chmod +x "$work_dir/bin/codex" "$work_dir/bin/agent" "$work_dir/bin/gemini" "$work_dir/bin/claude" "$work_dir/bin/opencode" "$work_dir/bin/agy"

wrap_root="$work_dir/wrapper"
mkdir -p "$wrap_root/local" "$wrap_root/real" "$wrap_root/config/nvim"
printf '%s\n' '-- dummy' > "$wrap_root/config/nvim/init.lua"
cp -- "$SETUP_ROOT/scripts/nvim-wrapper.sh" "$wrap_root/local/nvim"
chmod +x "$wrap_root/local/nvim"
cat > "$wrap_root/real/nvim" << 'SCRIPT'
#!/bin/sh
printf 'NVIM_CLEAN=%s\n' "${NVIM_CLEAN-}" > "$E2E_DIR/wrapper-env"
printf '%s\n' "$@" > "$E2E_DIR/wrapper-args"
SCRIPT
chmod +x "$wrap_root/real/nvim"
(
  export XDG_CONFIG_HOME="$wrap_root/config"
  unset NVIM_APPNAME
  export PATH="$wrap_root/local:$wrap_root/real:$PATH"
  nvim --clean file.ts
)
[[ "$(cat "$work_dir/wrapper-env")" == "NVIM_CLEAN=1" ]] || die 'wrapper --clean should set NVIM_CLEAN=1'
[[ "$(cat "$work_dir/wrapper-args")" == "file.ts" ]] || die 'wrapper --clean should not pass --clean through'
rm -f -- "$work_dir/wrapper-env" "$work_dir/wrapper-args"
(
  export XDG_CONFIG_HOME="$wrap_root/config"
  unset NVIM_APPNAME
  export PATH="$wrap_root/local:$wrap_root/real:$PATH"
  nvim --clean
)
[[ "$(cat "$work_dir/wrapper-env")" == "NVIM_CLEAN=1" ]] || die 'wrapper --clean with no files should set NVIM_CLEAN=1'
[[ "$(cat "$work_dir/wrapper-args")" == "" ]] || die 'wrapper --clean with no files should pass no args'
(
  export XDG_CONFIG_HOME="$wrap_root/config"
  unset NVIM_APPNAME
  export PATH="$wrap_root/local:$wrap_root/real:$PATH"
  NVIM_WRAPPER=0 nvim --clean file.ts
)
[[ "$(cat "$work_dir/wrapper-env")" == "NVIM_CLEAN=" ]] || die 'NVIM_WRAPPER=0 should not set NVIM_CLEAN'
[[ "$(cat "$work_dir/wrapper-args")" == $'--clean\nfile.ts' ]] || die 'NVIM_WRAPPER=0 should pass --clean through'

export XDG_STATE_HOME="$work_dir/state"
export XDG_RUNTIME_DIR="$work_dir/runtime"
export PATH="$work_dir/bin:$PATH"
NVIM_WRAPPER=0 nvim --clean --headless -n -l "$SETUP_ROOT/scripts/tests/e2e.lua"
