#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
for script in "$SETUP_ROOT"/scripts/*.sh "$SETUP_ROOT"/scripts/tests/*.sh; do
  [[ -f "$script" ]] || continue
  bash -n "$script"
done
need nvim
SETUP_ROOT="$SETUP_ROOT" NVIM_WRAPPER=0 nvim --clean --headless -n '+lua for _, p in ipairs(vim.fn.glob(vim.env.SETUP_ROOT .. "/**/*.lua", false, true)) do if not p:find("/node_modules/", 1, true) then local chunk, err = loadfile(p); if not chunk then print(err); vim.cmd("cquit 1") end end end; print("All shell and Lua files passed syntax checks")' +qa
