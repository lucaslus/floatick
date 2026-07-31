#!/usr/bin/env bash

set -euo pipefail

readonly expected_argument_count=2

if [[ $# -ne $expected_argument_count ]]; then
  echo "Usage: $0 <app-path> <expected-feed-url>" >&2
  exit 64
fi

readonly app_path=$1
readonly expected_feed_url=$2
readonly info_plist="$app_path/Contents/Info.plist"

if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "Expected an existing .app bundle: $app_path" >&2
  exit 66
fi
if [[ ! -f "$info_plist" ]]; then
  echo "App Info.plist is missing: $info_plist" >&2
  exit 66
fi

configured_feed_url=$(
  /usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$info_plist"
)
readonly configured_feed_url
if [[ "$configured_feed_url" != "$expected_feed_url" ]]; then
  echo "Expected SUFeedURL $expected_feed_url, found $configured_feed_url." >&2
  exit 1
fi

temporary_directory=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
appcast_path=$(mktemp "$temporary_directory/floatick-appcast.XXXXXX")
readonly temporary_directory
readonly appcast_path
trap 'rm -f "$appcast_path"' EXIT

curl \
  --fail \
  --location \
  --retry 3 \
  --retry-delay 2 \
  --silent \
  --show-error \
  --max-time 15 \
  "$configured_feed_url" \
  --output "$appcast_path"
/usr/bin/xmllint --noout "$appcast_path"

echo "Verified Sparkle feed: $configured_feed_url"
