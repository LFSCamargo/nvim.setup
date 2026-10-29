#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
[[ -f "$CONFIG_DIR/init.lua" ]] || die 'No installed config to capture.'
# Only configuration is exported; caches, CLI credentials and machine state stay outside Git.
python3 - "$CONFIG_DIR" "$SETUP_ROOT/nvim" <<'PY'
import shutil, sys
from pathlib import Path
source, dest = map(Path, sys.argv[1:])
for name in ('init.lua', 'lazy-lock.json', 'lua', 'scripts'):
    src, dst = source/name, dest/name
    if not src.exists():
        raise SystemExit(f'Missing expected configuration: {src}')
    if src.resolve() == dst.resolve():
        continue
    if dst.is_dir():
        shutil.rmtree(dst)
    shutil.copytree(src, dst) if src.is_dir() else shutil.copy2(src, dst)
PY
say 'Captured installed config. Review git diff, then commit and push.'
