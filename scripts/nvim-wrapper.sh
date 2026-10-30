#!/usr/bin/env bash
# nvim.setup-wrapper — intercepts --clean so this config can skip session restore.
set -euo pipefail

self_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"

path_without_self() {
  local out="" dir resolved
  local IFS=':'
  for dir in $PATH; do
    [[ -z "$dir" ]] && continue
    resolved="$(cd -- "$dir" 2> /dev/null && pwd -P || true)"
    [[ "$resolved" == "$self_dir" ]] && continue
    out="${out:+$out:}$dir"
  done
  printf '%s' "$out"
}

real_nvim="$(PATH="$(path_without_self)" command -v nvim)" || {
  printf 'ERROR: nvim.setup wrapper could not find Neovim on PATH\n' >&2
  exit 127
}

exec_real() {
  exec "$real_nvim" "$@"
}

if [[ "${NVIM_WRAPPER:-1}" == "0" ]]; then
  exec_real "$@"
fi

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}"
has_clean=0
filtered=()
for arg in "$@"; do
  if [[ "$arg" == "--clean" ]]; then
    has_clean=1
  else
    filtered+=("$arg")
  fi
done

if ((has_clean)); then
  if [[ -f "$config_dir/init.lua" ]]; then
    export NVIM_CLEAN=1
    # Empty "${array[@]}" is unbound under `set -u`.
    if ((${#filtered[@]})); then
      exec_real "${filtered[@]}"
    else
      exec_real
    fi
  fi
  exec_real "$@"
fi

exec_real "$@"
