#!/bin/bash
# Builds minkey and installs it for the current user, replacing a running copy.
set -euo pipefail
cd "$(dirname "$0")/.."

app=$(scripts/bundle.sh)
dest="$HOME/Library/Input Methods/Minkey.app"
mkdir -p "$HOME/Library/Input Methods"
pkill -x Minkey || true
rm -rf "$dest"
cp -R "$app" "$dest"
# Enabling the source makes macOS ask for consent, so only a first install does it.
if ! defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -q top.bigin.inputmethod.Minkey; then
    "$dest/Contents/MacOS/Minkey" --install
fi
echo "Installed $dest. Pick minkey from the input menu in the menu bar."
