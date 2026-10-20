#!/usr/bin/env bash
# Syntax-checks every Apple-only Swift file (they cannot be type-checked on Linux).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mapfile -t FILES < <(find App Widget Shared Packages/TodoCore/Sources/TodoData Packages/TodoCore/Sources/TodoUI \
  -name '*.swift' 2>/dev/null | sort)
if [ ${#FILES[@]} -eq 0 ]; then echo "parse-check: no files"; exit 0; fi
exec docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$ROOT":/src -w /src swift:6.1 bash -c '
  fail=0
  for f in "$@"; do
    if ! out=$(swiftc -parse "$f" 2>&1); then echo "FAIL $f"; echo "$out"; fail=1; fi
  done
  [ $fail -eq 0 ] && echo "parse-check: ${#@} files OK"
  exit $fail' _ "${FILES[@]}"
