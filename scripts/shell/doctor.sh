#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
for tool in nvim git curl tar unzip make node npm cc tree-sitter fzf rg python3 go cargo; do need "$tool"; done
if ! command -v fd > /dev/null 2>&1; then
  if command -v fdfind > /dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    export PATH="$HOME/.local/bin:$PATH"
  else die 'Missing fd (fd-find on Debian/Ubuntu). Run make deps.'; fi
fi
NVIM_WRAPPER=0 nvim --clean --headless -n '+lua if vim.fn.has("nvim-0.12") == 0 then print("Neovim 0.12+ required"); vim.cmd("cquit 1") end' +qa
node -e 'if (Number(process.versions.node.split(".")[0]) < 22) { console.error("Node.js 22+ required; update your Node installation."); process.exit(1) }'
python3 - << 'PY'
import re, subprocess, sys
v = subprocess.check_output(['tree-sitter', '--version'], text=True)
m = re.search(r'(\d+)\.(\d+)\.(\d+)', v)
if not m or tuple(map(int, m.groups())) < (0, 26, 1):
    sys.exit('Tree-sitter CLI 0.26.1+ required. Use brew upgrade tree-sitter-cli or cargo install --locked tree-sitter-cli.')
PY
for cli in codex agent gemini claude opencode agy; do
  if ! command -v "$cli" > /dev/null 2>&1; then printf 'Optional CLI missing: %s (that startup chat will be unavailable)\n' "$cli"; fi
done
say 'Prerequisites OK. Ensure ~/.local/bin is on your PATH if using fdfind.'
