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
    local out
    if ! out=$("$tool" "$@" 2>&1); then
      fail=1
      echo "$out"
      if [ -n "${GITHUB_ACTIONS:-}" ]; then
        msg=$(printf '%s' "$out" | tail -c 3000 | sed ':a;N;$!ba;s/%/%25/g;s/\r/%0D/g;s/\n/%0A/g')
        echo "::error title=$tool failed ($slug)::$msg"
      fi
    else
      echo "$out"
    fi
  else
    echo "== $tool not installed, skipping (CI will run it)"
  fi
}

run stylua "$dir/src"   # auto-format (commit the result)
run selene "$dir/src"
mkdir -p build
run rojo build "$dir" -o "build/$slug.rbxl"

[ $fail -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "CHECKS FAILED"; exit 1; }
