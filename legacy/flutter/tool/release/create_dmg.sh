#!/bin/bash

set -euo pipefail

readonly expected_argument_count=3

if [[ $# -ne $expected_argument_count ]]; then
  echo "Usage: $0 <app-path> <output-dmg-path> <volume-name>" >&2
  exit 64
fi

readonly app_path=$1
readonly output_path=$2
readonly volume_name=$3

if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "Expected an existing .app bundle: $app_path" >&2
  exit 66
fi

if [[ "$output_path" != *.dmg ]]; then
  echo "Output path must end in .dmg: $output_path" >&2
  exit 64
fi

if [[ -z "$volume_name" ]]; then
  echo "Volume name must not be empty." >&2
  exit 64
fi

output_directory=$(dirname "$output_path")
readonly output_directory
mkdir -p "$output_directory"

staging_directory=$(mktemp -d "${TMPDIR:-/tmp}/floatick-dmg.XXXXXX")
readonly staging_directory
cleanup() {
  rm -rf "$staging_directory"
}
trap cleanup EXIT

ditto "$app_path" "$staging_directory/$(basename "$app_path")"
ln -s /Applications "$staging_directory/Applications"

hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging_directory" \
  -ov \
  -format UDZO \
  "$output_path"
