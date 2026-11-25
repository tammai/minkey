#!/bin/bash
# Builds build/Minkey.app and prints its path. SIGN_IDENTITY picks the certificate (ad-hoc by default);
# MINKEY_VERSION and SPARKLE_PUBLIC_KEY are set by scripts/release.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

# Universal, so one package installs on both Intel and Apple silicon Macs.
archs=(--arch arm64 --arch x86_64)
swift build -c release --product Minkey "${archs[@]}" >&2
app=build/Minkey.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release "${archs[@]}" --show-bin-path)/Minkey" "$app/Contents/MacOS/Minkey"
bin=$(swift build -c release "${archs[@]}" --show-bin-path)
mkdir -p "$app/Contents/Frameworks"
cp -R "$bin/Sparkle.framework" "$app/Contents/Frameworks/"
cp Resources/Info.plist "$app/Contents/Info.plist"
plist="$app/Contents/Info.plist"
if [[ -n "${MINKEY_VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MINKEY_VERSION" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $MINKEY_VERSION" "$plist"
fi
if [[ -n "${SPARKLE_PUBLIC_KEY:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $SPARKLE_PUBLIC_KEY" "$plist"
fi
cp Resources/icon.tiff "$app/Contents/Resources/icon.tiff"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp -R Resources/vi.lproj Resources/en.lproj "$app/Contents/Resources/"
# Inside out, as Sparkle documents: --deep leaves Sparkle's own team ID on its parts, and the hardened runtime then
# refuses to load them into minkey.
# The hardened runtime's library check needs a team ID, which an ad-hoc signature lacks, so local builds go without.
runtime=()
[[ -n "${SIGN_IDENTITY:-}" ]] && runtime=(--options runtime)
sign() { codesign --force ${runtime[@]+"${runtime[@]}"} --sign "${SIGN_IDENTITY:--}" "$@" >&2; }
sparkle="$app/Contents/Frameworks/Sparkle.framework/Versions/B"
# minkey isn't sandboxed, so Sparkle's XPC services are unused; shipping them would only add attack surface.
rm -rf "$sparkle/XPCServices"
sign "$sparkle/Autoupdate" "$sparkle/Updater.app"
sign "$app/Contents/Frameworks/Sparkle.framework"
sign "$app"
echo "$app"
