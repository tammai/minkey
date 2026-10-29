---
type: gotcha
title: A dev-installed input method may not appear in System Settings
description: What to do when minkey is registered and enabled but missing from the input menu and Settings.
tags: [install, macos]
updated: 2026-10-29
---

# A dev-installed input method may not appear in System Settings

## Symptom
After `scripts/install-dev.sh`, Text Input Sources reports `top.bigin.inputmethod.Minkey.telex` as enabled and
selectable, but it is missing from the input menu and from System Settings → Keyboard → Text Input (including
"+" → Vietnamese). `TISSelectInputSource` returns -50 from a command-line tool, for any third-party input method.

## Cause
`TISEnableInputSource` from a helper process changes the session's state but isn't written to
`com.apple.HIToolbox` `AppleEnabledInputSources`, which the menu and System Settings read; their lists are cached.

## Fix
Quit System Settings (Cmd+Q) and reopen it; restart `TextInputMenuAgent`; if it still isn't listed, log out and in,
then add it under Vietnamese. The release pkg installs to `/Library/Input Methods`.

## How to detect early
`defaults read com.apple.HIToolbox AppleEnabledInputSources | grep -i minkey` is empty.

## Related
- [ad-hoc-hardened-runtime.md](ad-hoc-hardened-runtime.md)
