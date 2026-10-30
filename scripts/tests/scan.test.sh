#!/usr/bin/env bash
# Drive scripts/scan.sh the way CI does (sast + npm audit), with stubbed tools.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd -P)"
PASS=0
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; PASS=$((PASS + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-setup-scan.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

write_stub() {
  local path="$1"
  mkdir -p "$(dirname -- "$path")"
  cat >"$path"
  chmod +x "$path"
}

assert_file_has() {
  local file="$1" needle="$2"
  grep -F -- "$needle" "$file" >/dev/null 2>&1 || fail "$file missing '$needle'"
}

# 1. The committed scan keeps the OWASP / JS packs and fails on findings.
scan="$ROOT/scripts/semgrep-scan.sh"
[[ -f "$scan" ]] || fail 'scripts/semgrep-scan.sh is required'
assert_file_has "$scan" 'p/owasp-top-ten'
assert_file_has "$scan" 'p/javascript'
assert_file_has "$scan" 'p/typescript'
assert_file_has "$scan" 'p/react'
assert_file_has "$scan" 'p/security-audit'
assert_file_has "$scan" '--error'
assert_file_has "$scan" '--metrics=off'
grep -F 'semgrep ci' "$scan" >/dev/null && fail 'OSS scan must not call semgrep ci (that needs a cloud token)'
pass 'semgrep-scan.sh pins OWASP and JS rulesets and fails closed'

# 2. Ignore third-party and generated trees so the barrier is about our code.
ignore="$ROOT/.semgrepignore"
[[ -f "$ignore" ]] || fail '.semgrepignore is required'
assert_file_has "$ignore" 'node_modules/'
assert_file_has "$ignore" 'dist/'
assert_file_has "$ignore" 'nvim/'
pass '.semgrepignore skips node_modules, dist, and the Neovim config'

# 3. CI runs the same SAST command without a Semgrep Cloud token.
workflow="$ROOT/.github/workflows/semgrep.yml"
[[ -f "$workflow" ]] || fail '.github/workflows/semgrep.yml is required'
assert_file_has "$workflow" 'semgrep/semgrep'
assert_file_has "$workflow" 'scripts/semgrep-scan.sh'
grep -F 'SEMGREP_APP_TOKEN' "$workflow" >/dev/null && fail 'Semgrep CE must not require SEMGREP_APP_TOKEN'
pass 'GitHub Actions runs Semgrep CE from scripts/semgrep-scan.sh'

# 4. CI lints and builds the site; Playwright and visitor-path tests stay local.
ci="$ROOT/.github/workflows/ci.yml"
[[ -f "$ci" ]] || fail '.github/workflows/ci.yml is required'
[[ ! -f "$ROOT/.github/workflows/web.yml" ]] || fail 'website pipeline web.yml must be removed'
assert_file_has "$ci" 'pnpm install --frozen-lockfile'
assert_file_has "$ci" 'pnpm format:check'
assert_file_has "$ci" 'pnpm --filter web typecheck'
assert_file_has "$ci" 'pnpm build'
grep -E 'playwright|test:web:e2e|filter web test' "$ci" >/dev/null \
  && fail 'CI must not run Playwright or the website visitor-path suite'
pass 'CI runs format, typecheck, and the production build'

# 5. Local scan.sh audit invokes pnpm with a moderate severity floor.
calls="$TMP/calls.log"
: >"$calls"
bin="$TMP/bin"
write_stub "$bin/pnpm" <<EOF
#!/bin/sh
printf 'pnpm %s\n' "\$*" >>'$calls'
exit 0
EOF
write_stub "$bin/semgrep" <<EOF
#!/bin/sh
printf 'semgrep %s\n' "\$*" >>'$calls'
exit 0
EOF
if ! env -i \
  HOME="$TMP" \
  PATH="$bin:/usr/bin:/bin" \
  /bin/bash "$ROOT/scripts/scan.sh" audit; then
  fail 'scan.sh audit should succeed with a stubbed pnpm'
fi
grep -F 'pnpm --dir' "$calls" >/dev/null || grep -F 'audit --audit-level=moderate' "$calls" >/dev/null \
  || fail 'scan.sh audit must run pnpm audit --audit-level=moderate'
assert_file_has "$calls" 'audit --audit-level=moderate'
if grep -F 'semgrep ' "$calls" >/dev/null; then
  fail 'scan.sh audit must not start Semgrep'
fi
pass 'scan.sh audit runs pnpm audit --audit-level=moderate'

# 6. Local scan.sh sast execs the shared Semgrep argv (OWASP packs, --error).
: >"$calls"
if ! env -i \
  HOME="$TMP" \
  PATH="$bin:/usr/bin:/bin" \
  /bin/bash "$ROOT/scripts/scan.sh" sast; then
  fail 'scan.sh sast should succeed with a stubbed semgrep'
fi
assert_file_has "$calls" 'p/owasp-top-ten'
assert_file_has "$calls" '--error'
if grep -E '^pnpm | pnpm ' "$calls" >/dev/null; then
  fail 'scan.sh sast must not start pnpm audit'
fi
pass 'scan.sh sast runs Semgrep with the OWASP ruleset and --error'

# 7. Unknown modes fail closed so CI cannot silently skip the barrier.
if env -i HOME="$TMP" PATH="$bin:/usr/bin:/bin" \
  /bin/bash "$ROOT/scripts/scan.sh" --skip-security 2>"$TMP/err"; then
  fail 'unknown scan mode should exit non-zero'
fi
grep -F 'Usage:' "$TMP/err" >/dev/null || fail 'unknown mode should print usage'
pass 'scan.sh rejects unknown modes'

# 8. Missing Semgrep and Docker fails closed instead of skipping SAST.
write_stub "$bin/pnpm" <<EOF
#!/bin/sh
printf 'pnpm %s\n' "\$*" >>'$calls'
exit 0
EOF
rm -f "$bin/semgrep"
if env -i HOME="$TMP" PATH="$bin:/usr/bin:/bin" \
  /bin/bash "$ROOT/scripts/scan.sh" sast 2>"$TMP/missing"; then
  fail 'scan.sh sast without semgrep or docker should exit non-zero'
fi
grep -F 'Missing semgrep' "$TMP/missing" >/dev/null || fail 'missing-semgrep message not shown'
pass 'scan.sh sast fails closed when Semgrep is not installed'

# 9. GitHub Actions stay pinned to immutable SHAs (OWASP A06 / supply chain).
for wf in commitlint.yml semgrep.yml ci.yml; do
  path="$ROOT/.github/workflows/$wf"
  if grep -E 'uses:[[:space:]]+[^[:space:]]+@v[0-9]' "$path" >/dev/null; then
    fail "$wf uses a mutable GitHub Action tag"
  fi
done
pass 'GitHub Actions workflows pin actions to commit SHAs'

printf '\n%s\n' "All $PASS scan tests passed"
