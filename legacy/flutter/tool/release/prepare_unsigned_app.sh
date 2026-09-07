#!/bin/bash

set -euo pipefail

readonly expected_argument_count=1

if [[ $# -ne $expected_argument_count ]]; then
  echo "Usage: $0 <app-path>" >&2
  exit 64
fi

readonly app_path=$1

if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "Expected an existing .app bundle: $app_path" >&2
  exit 66
fi

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly script_directory
readonly entitlements_path="$script_directory/unsigned_release.entitlements"
readonly frameworks_path="$app_path/Contents/Frameworks"
readonly sparkle_framework="$frameworks_path/Sparkle.framework"
readonly sparkle_version="$sparkle_framework/Versions/Current"
readonly -a signing_options=(
  --force
  --sign -
  --options runtime
  --timestamp=none
)

if [[ ! -f "$entitlements_path" ]]; then
  echo "Unsigned release entitlements are missing: $entitlements_path" >&2
  exit 66
fi

if [[ ! -d "$sparkle_version" ]]; then
  echo "Sparkle framework is missing from the app bundle." >&2
  exit 66
fi

# Sparkle's helpers must be signed before the framework that seals them.
# Downloader.xpc can carry version-specific entitlements, so preserve them.
codesign "${signing_options[@]}" \
  "$sparkle_version/XPCServices/Installer.xpc"
codesign "${signing_options[@]}" \
  --preserve-metadata=entitlements \
  "$sparkle_version/XPCServices/Downloader.xpc"
codesign "${signing_options[@]}" \
  "$sparkle_version/Autoupdate"
codesign "${signing_options[@]}" \
  "$sparkle_version/Updater.app"
codesign "${signing_options[@]}" \
  "$sparkle_framework"

for framework in "$frameworks_path"/*.framework; do
  if [[ "$framework" == "$sparkle_framework" ]]; then
    continue
  fi
  codesign "${signing_options[@]}" "$framework"
done

# An ad-hoc identity has no Team ID. Disable library validation only for these
# unsigned candidate builds so macOS can load their consistently ad-hoc-signed
# embedded frameworks. Developer ID distributions must use the signed pipeline.
codesign "${signing_options[@]}" \
  --entitlements "$entitlements_path" \
  "$app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"
