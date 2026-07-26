#!/bin/bash

set -euo pipefail

readonly expected_argument_count=1
readonly startup_seconds=5

if [[ $# -ne $expected_argument_count ]]; then
  echo "Usage: $0 <app-path>" >&2
  exit 64
fi

readonly app_path=$1

if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "Expected an existing .app bundle: $app_path" >&2
  exit 66
fi

readonly info_plist="$app_path/Contents/Info.plist"
if [[ ! -f "$info_plist" ]]; then
  echo "App Info.plist is missing: $info_plist" >&2
  exit 66
fi

executable_name=$(/usr/libexec/PlistBuddy \
  -c 'Print :CFBundleExecutable' \
  "$info_plist")
readonly executable_path="$app_path/Contents/MacOS/$executable_name"

if [[ ! -x "$executable_path" ]]; then
  echo "App executable is missing or not executable: $executable_path" >&2
  exit 66
fi

log_path=$(mktemp "${TMPDIR:-/tmp}/floatick-smoke.XXXXXX")
readonly log_path
app_pid=

cleanup() {
  if [[ -n "$app_pid" ]] && kill -0 "$app_pid" >/dev/null 2>&1; then
    kill -TERM "$app_pid" >/dev/null 2>&1 || true
    wait "$app_pid" >/dev/null 2>&1 || true
  fi
  rm -f "$log_path"
}
trap cleanup EXIT

"$executable_path" >"$log_path" 2>&1 &
app_pid=$!

sleep "$startup_seconds"

if ! kill -0 "$app_pid" >/dev/null 2>&1; then
  exit_status=0
  wait "$app_pid" || exit_status=$?
  echo "App exited during the ${startup_seconds}s startup smoke test (status $exit_status)." >&2
  if [[ -s "$log_path" ]]; then
    echo "Application output:" >&2
    sed 's/^/  /' "$log_path" >&2
  fi
  exit 1
fi

echo "App remained running for the ${startup_seconds}s startup smoke test."
