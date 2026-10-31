#!/usr/bin/env bash
exec bash "$(dirname -- "$0")/shell/format-staged.sh" "$@"
