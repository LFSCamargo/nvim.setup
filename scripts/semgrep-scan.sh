#!/bin/sh
set -eu
# Community OWASP / JavaScript rules. No Semgrep Cloud token.
# --error fails the process on any finding so CI cannot merge them.
SEMGREP_SEND_METRICS=off
export SEMGREP_SEND_METRICS
exec semgrep scan \
  --error \
  --metrics=off \
  --config p/owasp-top-ten \
  --config p/javascript \
  --config p/typescript \
  --config p/react \
  --config p/security-audit
