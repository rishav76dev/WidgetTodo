#!/usr/bin/env bash
# Runs the TodoCore package tests on Linux inside the official Swift Docker image.
# Usage: [TODOCORE_DIR=/path/to/TodoCore] [SWIFT_SCRATCH=.build-linux-foo] scripts/test-core.sh [--filter Suite]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="${TODOCORE_DIR:-$ROOT/Packages/TodoCore}"
exec docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PKG":/pkg -w /pkg swift:6.1 \
  swift test --scratch-path "/pkg/${SWIFT_SCRATCH:-.build-linux}" "$@"
