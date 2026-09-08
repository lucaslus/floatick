#!/bin/bash
set -euo pipefail

# Match the pinned release tooling; never execute an unverified remote script.
SPARKLE_VERSION=2.9.2
SPARKLE_SHA256=1cb340cbbef04c6c0d162078610c25e2221031d794a3449d89f2f56f4df77c95
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
framework_dir="$project_dir/src-tauri"
if [[ "$(uname -s)" != Darwin ]]; then
  exit 0
fi
if [[ -s "$framework_dir/Sparkle.framework/Sparkle" && -f "$framework_dir/.sparkle-archive-sha256" ]] &&
   [[ "$(cat "$framework_dir/.sparkle-archive-sha256")" == "$SPARKLE_SHA256" ]]; then
  exit 0
fi
scratch_dir="$(mktemp -d)"
trap 'rm -rf "$scratch_dir"' EXIT
curl --fail --location --silent --show-error --retry 3 \
  "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
  --output "$scratch_dir/Sparkle.tar.xz"
printf '%s  %s\n' "$SPARKLE_SHA256" "$scratch_dir/Sparkle.tar.xz" | shasum -a 256 --check
tar -xJf "$scratch_dir/Sparkle.tar.xz" -C "$scratch_dir"
# Preserve framework symlinks and its embedded installer/XPC services.
ditto "$scratch_dir/Sparkle.framework" "$framework_dir/Sparkle.framework"
printf '%s\n' "$SPARKLE_SHA256" > "$framework_dir/.sparkle-archive-sha256"
printf 'Sparkle %s is ready.\n' "$SPARKLE_VERSION"
