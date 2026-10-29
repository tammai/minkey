#!/bin/bash
# Wraps an app bundle into an installer: scripts/build-pkg.sh <Minkey.app> <version> <out.pkg>.
# INSTALLER_IDENTITY ("Developer ID Installer: …") signs it; unsigned otherwise, for local checks only.
set -euo pipefail
cd "$(dirname "$0")/.."
app=$1 version=$2 out=$3

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R "$app" "$stage/Minkey.app"
pkgbuild --analyze --root "$stage" "$stage.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :0:BundleIsRelocatable false" "$stage.plist"
pkgbuild --root "$stage" --component-plist "$stage.plist" --install-location "/Library/Input Methods" \
    --scripts scripts/pkg --identifier top.bigin.inputmethod.Minkey --version "$version" \
    ${INSTALLER_IDENTITY:+--sign "$INSTALLER_IDENTITY"} "$out" >&2
rm -f "$stage.plist"
echo "$out"
