#!/usr/bin/env bash
# Drive scripts/bootstrap.sh the way a visitor would (pipe, --preview, checkout).
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-bootstrap.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

write_stub() {
  local path="$1"
  mkdir -p "$(dirname -- "$path")"
  cat > "$path"
  chmod +x "$path"
}

make_bin() {
  local home="$1" calls="$2"
  local bin="$home/bin" stub
  mkdir -p "$bin" "$home"

  write_stub "$bin/brew" << EOF
#!/bin/sh
printf 'brew %s\n' "\$*" >>'$calls'
exit 0
EOF

  stub="$(
    cat << 'GIT'
#!/bin/sh
printf 'git %s\n' "$*" >>__CALLS__
if [ "$1" = clone ]; then
  clone_dest=""
  for clone_dest in "$@"; do
    :
  done
  mkdir -p "$clone_dest/scripts" "$clone_dest/nvim"
  printf '%s\n' '#!/bin/sh' "printf 'deps NVIM_APPNAME=%s\n' \"\${NVIM_APPNAME:-nvim}\" >>'__CALLS__'" >"$clone_dest/scripts/deps.sh"
  printf '%s\n' '#!/bin/sh' "printf 'fonts NVIM_APPNAME=%s\n' \"\${NVIM_APPNAME:-nvim}\" >>'__CALLS__'" >"$clone_dest/scripts/fonts.sh"
  printf '%s\n' '#!/bin/sh' "printf 'install NVIM_APPNAME=%s\n' \"\${NVIM_APPNAME:-nvim}\" >>'__CALLS__'" >"$clone_dest/scripts/install.sh"
  printf '%s\n' '-- fake --' >"$clone_dest/nvim/init.lua"
  printf '%s\n' 'install:' >"$clone_dest/Makefile"
fi
exit 0
GIT
  )"
  printf '%s\n' "${stub//__CALLS__/$calls}" > "$bin/git"
  chmod +x "$bin/git"

  write_stub "$bin/id" << EOF
#!/bin/sh
if [ "\${1-}" = -u ]; then
  printf '%s\n' "\${FAKE_UID:-501}"
  exit 0
fi
exec /usr/bin/id "\$@"
EOF

  printf '%s\n' "$bin"
}

assert_file_has() {
  local file="$1" needle="$2"
  grep -F "$needle" "$file" > /dev/null 2>&1 || fail "$file missing '$needle'"
}

run_piped() {
  local home="$1"
  shift
  local calls="$home/calls.log"
  local dest="$home/share/nvim.setup"
  mkdir -p "$home"
  : > "$calls"
  local bin
  bin="$(make_bin "$home" "$calls")"
  env -i \
    HOME="$home" \
    PATH="$bin:/usr/bin:/bin" \
    NVIM_SETUP_HOME="$dest" \
    NVIM_SETUP_REPO='https://github.com/LFSCamargo/nvim.setup.git' \
    NVIM_SETUP_BRANCH=main \
    FAKE_UID="${FAKE_UID:-501}" \
    /bin/bash -s -- "$@" < "$ROOT/scripts/bootstrap.sh"
}

# 1. Piped install clones, then runs deps + install (the no-clone visitor path).
home="$TMP/pipe"
run_piped "$home"
assert_file_has "$home/calls.log" 'git clone --branch main --depth 1 -- https://github.com/LFSCamargo/nvim.setup.git'
assert_file_has "$home/calls.log" 'deps NVIM_APPNAME=nvim'
assert_file_has "$home/calls.log" 'fonts NVIM_APPNAME=nvim'
assert_file_has "$home/calls.log" 'install NVIM_APPNAME=nvim'
assert_file_has "$home/.zprofile" 'nvim.setup PATH'
[[ -f "$home/share/nvim.setup/nvim/init.lua" ]] || fail 'clone stub did not create the checkout'
pass 'piped bootstrap clones and installs without a pre-existing repo'

# 2. --preview keeps the current config by setting NVIM_APPNAME.
home="$TMP/preview"
run_piped "$home" --preview
assert_file_has "$home/calls.log" 'deps NVIM_APPNAME=nvim-preview'
assert_file_has "$home/calls.log" 'fonts NVIM_APPNAME=nvim-preview'
assert_file_has "$home/calls.log" 'install NVIM_APPNAME=nvim-preview'
pass 'piped bootstrap --preview sets NVIM_APPNAME=nvim-preview'

# 3. Root is refused before any clone or package install.
home="$TMP/root"
if FAKE_UID=0 run_piped "$home" 2> "$home.err"; then
  fail 'bootstrap as root should exit non-zero'
fi
grep -F 'Do not run this installer as root' "$home.err" > /dev/null || fail 'root refusal message missing'
[[ ! -e "$home/calls.log" || ! -s "$home/calls.log" ]] || {
  if grep -E 'git |brew |deps |fonts |install ' "$home/calls.log" > /dev/null; then
    fail 'root run started clone or install'
  fi
}
pass 'bootstrap refuses to run as root'

# 4. Unknown flags fail closed.
home="$TMP/badflag"
if run_piped "$home" --evil 2> "$home.err"; then
  fail 'unknown flag should exit non-zero'
fi
grep -F 'Unknown option: --evil' "$home.err" > /dev/null || fail 'unknown option message missing'
pass 'bootstrap rejects unknown flags'

# 5. --version pins the clone to that tag and accepts a bare semver.
home="$TMP/version"
run_piped "$home" --version 1.1.0
assert_file_has "$home/calls.log" 'git clone --branch v1.1.0 --depth 1 -- https://github.com/LFSCamargo/nvim.setup.git'
assert_file_has "$home/calls.log" 'install NVIM_APPNAME=nvim'
pass 'piped bootstrap --version clones the requested tag'

# 6. --preview and --version can be combined, and a missing tag is rejected.
home="$TMP/preview-version"
run_piped "$home" --preview --version v1.0.0
assert_file_has "$home/calls.log" 'git clone --branch v1.0.0 --depth 1 --'
assert_file_has "$home/calls.log" 'install NVIM_APPNAME=nvim-preview'
home="$TMP/badversion"
if run_piped "$home" --version '../evil' 2> "$home.err"; then
  fail '--version with a path must exit non-zero'
fi
grep -F 'Invalid NVIM_SETUP_BRANCH' "$home.err" > /dev/null || fail 'invalid version message missing'
if grep -F 'git clone' "$home/calls.log" > /dev/null 2>&1; then
  fail 'invalid --version must not clone'
fi
home="$TMP/missingversion"
if run_piped "$home" --version 2> "$home.err"; then
  fail 'missing --version value should exit non-zero'
fi
grep -F -- '--version needs a tag' "$home.err" > /dev/null || fail 'missing version message missing'
pass 'bootstrap combines --preview --version and rejects bad tags'

# 7. Running from a checkout skips git clone and uses that tree.
home="$TMP/checkout"
mkdir -p "$home/repo/scripts" "$home/repo/nvim" "$home/bin"
calls="$home/calls.log"
: > "$calls"
cp "$ROOT/scripts/bootstrap.sh" "$home/repo/scripts/bootstrap.sh"
printf '%s\n' '#!/bin/sh' "printf 'deps NVIM_APPNAME=%s\n' \"\${NVIM_APPNAME:-nvim}\" >>'$calls'" > "$home/repo/scripts/deps.sh"
printf '%s\n' '#!/bin/sh' "printf 'fonts NVIM_APPNAME=%s\n' \"\${NVIM_APPNAME:-nvim}\" >>'$calls'" > "$home/repo/scripts/fonts.sh"
printf '%s\n' '#!/bin/sh' "printf 'install NVIM_APPNAME=%s\n' \"\${NVIM_APPNAME:-nvim}\" >>'$calls'" > "$home/repo/scripts/install.sh"
printf '%s\n' '-- fake --' > "$home/repo/nvim/init.lua"
write_stub "$home/bin/brew" << EOF
#!/bin/sh
printf 'brew %s\n' "\$*" >>'$calls'
exit 0
EOF
write_stub "$home/bin/git" << EOF
#!/bin/sh
printf 'git %s\n' "\$*" >>'$calls'
exit 0
EOF
write_stub "$home/bin/id" << EOF
#!/bin/sh
[ "\${1-}" = -u ] && { printf '501\n'; exit 0; }
exec /usr/bin/id "\$@"
EOF
env -i \
  HOME="$home" \
  PATH="$home/bin:/usr/bin:/bin" \
  /bin/bash "$home/repo/scripts/bootstrap.sh"
assert_file_has "$calls" 'deps NVIM_APPNAME=nvim'
assert_file_has "$calls" 'fonts NVIM_APPNAME=nvim'
assert_file_has "$calls" 'install NVIM_APPNAME=nvim'
if grep -F 'git clone' "$calls" > /dev/null; then
  fail 'checkout run should not git clone'
fi
pass 'bootstrap from a clone skips fetch and installs in place'

# 8. Reject a non-GitHub repo URL (no arbitrary remote execution).
home="$TMP/badrepo"
mkdir -p "$home"
calls="$home/calls.log"
: > "$calls"
bin="$(make_bin "$home" "$calls")"
if env -i \
  HOME="$home" \
  PATH="$bin:/usr/bin:/bin" \
  NVIM_SETUP_HOME="$home/dest" \
  NVIM_SETUP_REPO='https://example.com/evil.git' \
  /bin/bash -s < "$ROOT/scripts/bootstrap.sh" 2> "$home.err"; then
  fail 'non-GitHub repo should be rejected'
fi
grep -F 'GitHub' "$home.err" > /dev/null || fail 'repo validation message missing'
if grep -F 'git clone' "$calls" > /dev/null; then
  fail 'invalid repo must not be cloned'
fi
pass 'bootstrap rejects a non-GitHub NVIM_SETUP_REPO'

# 9. Script source keeps the public one-liner and never pipes curl into sh -c without quoting.
grep -F 'raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh' "$ROOT/scripts/bootstrap.sh" > /dev/null \
  || fail 'bootstrap help should show the public curl URL'
grep -F 'git clone --branch' "$ROOT/scripts/bootstrap.sh" > /dev/null \
  || fail 'clone should pass --branch'
grep -F 'https://github.com/neovim/neovim/releases/latest/download/' "$ROOT/scripts/shell/deps.sh" > /dev/null \
  || fail 'deps should install Neovim from GitHub releases when packages are too old'
grep -F 'https://nodejs.org/dist/latest-v22.x/' "$ROOT/scripts/shell/deps.sh" > /dev/null \
  || fail 'deps should install Node.js 22 when packages are too old'
grep -F 'python3-pip' "$ROOT/scripts/shell/deps.sh" > /dev/null \
  || fail 'deps should install pip so fonts.sh can overlay icon glyphs'
grep -F 'scripts/fonts.sh' "$ROOT/scripts/bootstrap.sh" > /dev/null \
  || fail 'bootstrap should install icon fonts'
pass 'bootstrap and deps keep the public install URLs'

printf '\n%s\n' "All $PASS bootstrap tests passed"
