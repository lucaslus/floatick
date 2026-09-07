#!/bin/bash

set -euo pipefail

readonly script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repository_root="$(cd "$script_directory/../.." && pwd)"

cd "$repository_root"

echo "Running Floatick user journeys on the real macOS Flutter engine..."
flutter test integration_test/floatick_ui_test.dart -d macos

echo "Running native macOS accessibility boundary tests..."
xcodebuild test \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'platform=macOS' \
  -only-testing:RunnerTests \
  CODE_SIGNING_ALLOWED=NO \
  FLUTTER_TARGET=lib/main.dart \
  -quiet
