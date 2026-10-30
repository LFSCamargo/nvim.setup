#!/usr/bin/env bash
# Fail closed on OWASP SAST findings and moderate-or-higher npm advisories.
source "$(dirname -- "$0")/common.sh"

usage() {
  die 'Usage: scripts/scan.sh [sast|audit|all]'
}

audit_packages() {
  need pnpm
  say 'Auditing npm packages for known vulnerabilities'
  pnpm --dir "$SETUP_ROOT" audit --audit-level=moderate
}

scan_sast() {
  local scan="$SETUP_ROOT/scripts/semgrep-scan.sh"
  if command -v semgrep > /dev/null 2>&1; then
    say 'Scanning JavaScript and TypeScript for OWASP issues'
    (cd "$SETUP_ROOT" && sh "$scan")
    return
  fi
  if command -v docker > /dev/null 2>&1; then
    say 'Scanning JavaScript and TypeScript for OWASP issues (Semgrep container)'
    docker run --rm --entrypoint sh \
      -v "$SETUP_ROOT:/src:ro" \
      -w /src \
      -e SEMGREP_SEND_METRICS=off \
      semgrep/semgrep \
      /src/scripts/semgrep-scan.sh
    return
  fi
  die 'Missing semgrep. Install it, or install Docker, then retry.'
}

mode="${1-all}"
case "$mode" in
  sast | --sast) scan_sast ;;
  audit | --audit) audit_packages ;;
  all | --all) audit_packages && scan_sast ;;
  -h | --help)
    printf '%s\n' 'Usage: scripts/scan.sh [sast|audit|all]'
    exit 0
    ;;
  *) usage ;;
esac
