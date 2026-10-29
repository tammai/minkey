#!/bin/bash
# Cuts a release on the author's Mac: scripts/release.sh <version>, e.g. scripts/release.sh 0.2.0.
#
# Signing goes through Xcode's cloud-managed Developer ID certificate, which codesign can't use directly, so the app
# is put in a hand-built .xcarchive and exported with xcodebuild. Needs:
#   TEAM_ID             Apple Developer team that owns the Developer ID certificate
#   INSTALLER_IDENTITY  "Developer ID Installer: …" certificate in the Keychain, to sign the .pkg
#   NOTARY_PROFILE      a profile saved with `xcrun notarytool store-credentials`
#   SPARKLE_PUBLIC_KEY  printed by Sparkle's generate_keys; its private key stays in the login Keychain
set -euo pipefail
cd "$(dirname "$0")/.."

version=${1:?usage: scripts/release.sh <version>}
: "${TEAM_ID:?}" "${INSTALLER_IDENTITY:?}" "${NOTARY_PROFILE:?}" "${SPARKLE_PUBLIC_KEY:?}"
[[ -z "$(git status --porcelain)" ]] || { echo "commit or stash your changes first" >&2; exit 1; }

out=build/release/$version
rm -rf "$out"
mkdir -p "$out"
app=$(MINKEY_VERSION=$version SPARKLE_PUBLIC_KEY=$SPARKLE_PUBLIC_KEY scripts/bundle.sh)

archive=$out/Minkey.xcarchive
mkdir -p "$archive/Products/Applications"
cp -R "$app" "$archive/Products/Applications/"
cat >"$archive/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>ApplicationProperties</key><dict>
    <key>ApplicationPath</key><string>Applications/Minkey.app</string>
    <key>CFBundleIdentifier</key><string>top.bigin.inputmethod.Minkey</string>
    <key>CFBundleShortVersionString</key><string>$version</string>
    <key>CFBundleVersion</key><string>$version</string>
    <key>Team</key><string>$TEAM_ID</string>
  </dict>
  <key>ArchiveVersion</key><integer>2</integer>
  <key>Name</key><string>Minkey</string>
</dict></plist>
PLIST
cat >"$out/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$out/export" \
    -exportOptionsPlist "$out/ExportOptions.plist" -allowProvisioningUpdates >&2
signed=$out/export/Minkey.app

details=$(codesign -dv --verbose=2 "$signed" 2>&1)
grep -q "Authority=Developer ID Application" <<<"$details" || { echo "not Developer ID signed" >&2; exit 1; }
# Xcode's export has been seen to drop the hardened runtime, which notarization requires.
grep -q "runtime" <<<"$details" || { echo "exported app lacks the hardened runtime; notarization would fail" >&2; exit 1; }

pkg=$(INSTALLER_IDENTITY=$INSTALLER_IDENTITY scripts/build-pkg.sh "$signed" "$version" "$out/minkey-$version.pkg")
xcrun notarytool submit "$pkg" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$pkg"

.build/artifacts/sparkle/Sparkle/bin/generate_appcast \
    --download-url-prefix "https://github.com/tammai/minkey/releases/download/v$version/" "$out"
echo "Release files in $out: $(basename "$pkg") and appcast.xml."
echo "Publish with: gh release create v$version \"$pkg\" \"$out/appcast.xml\" --title \"minkey $version\""
