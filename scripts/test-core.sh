#!/usr/bin/env bash
# Runs the TodoCore package tests on Linux inside the official Swift Docker image.
# Usage: SWIFT_SCRATCH=.build-linux-foo scripts/test-core.sh [--filter Suite]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$ROOT/Packages/TodoCore":/pkg -w /pkg swift:6.1 \
  swift test --scratch-path "/pkg/${SWIFT_SCRATCH:-.build-linux}" "$@"
