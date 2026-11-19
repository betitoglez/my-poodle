#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
dart run tool/validate_localizations.dart
flutter build ipa --release --target lib/main.dart --dart-define=POODLE_LIVE_3D=true --export-options-plist="${POODLE_EXPORT_OPTIONS:-ios/ExportOptions-TestFlight.plist}" "$@"
python3 tool/verify_ios_release.py build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app
