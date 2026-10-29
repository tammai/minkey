#!/bin/bash
# Builds build/Minkey.app and prints its path. SIGN_IDENTITY picks the certificate; ad-hoc (-) by default.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product Minkey >&2
app=build/Minkey.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/Minkey" "$app/Contents/MacOS/Minkey"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/icon.tiff "$app/Contents/Resources/icon.tiff"
cp -R Resources/vi.lproj Resources/en.lproj "$app/Contents/Resources/"
codesign --force --options runtime --sign "${SIGN_IDENTITY:--}" "$app" >&2
echo "$app"
