#!/usr/bin/env bash
# Usage: scripts/check.sh <slug>   (or "template")
# Runs format check, lint, and build. Skips tools that aren't installed (CI has them all).
set -uo pipefail
cd "$(dirname "$0")/.."

slug="${1:?slug required}"
dir=$([ "$slug" = "template" ] && echo template || echo "games/$slug")
fail=0

run() {
  local tool="$1"; shift
  if command -v "$tool" >/dev/null 2>&1; then
    echo "== $tool $*"
    "$tool" "$@" || fail=1
  else
    echo "== $tool not installed, skipping (CI will run it)"
  fi
}

run stylua --check "$dir/src"
run selene "$dir/src"
mkdir -p build
run rojo build "$dir" -o "build/$slug.rbxl"

[ $fail -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "CHECKS FAILED"; exit 1; }
