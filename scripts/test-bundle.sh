#!/bin/bash
# Builds Minkey.app and checks it is an input method macOS will load.
set -euo pipefail
cd "$(dirname "$0")/.."

app=$(scripts/bundle.sh)
plist="$app/Contents/Info.plist"
get() { /usr/libexec/PlistBuddy -c "Print :$1" "$plist"; }
expect() {
    local actual
    actual=$(get "$1")
    [[ "$actual" == "$2" ]] || { echo "$1 is '$actual', expected '$2'" >&2; exit 1; }
}

plutil -lint "$plist" >/dev/null
expect CFBundleIdentifier top.bigin.inputmethod.Minkey
expect InputMethodConnectionName Minkey_Connection
expect InputMethodServerControllerClass MinkeyInputController
expect TISIntendedLanguage vi
expect LSUIElement true
expect LSMinimumSystemVersion 13.0
expect ComponentInputModeDict:tsInputModeListKey:top.bigin.inputmethod.Minkey.telex:TISIntendedLanguage vi
[[ -x "$app/Contents/MacOS/Minkey" ]] || { echo "missing executable" >&2; exit 1; }
[[ -f "$app/Contents/Resources/$(get tsInputMethodIconFileKey)" ]] || { echo "missing icon" >&2; exit 1; }
codesign --verify --strict "$app"
echo "ok: $app"
