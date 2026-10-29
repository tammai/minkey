# Part plan: minkey v1 B4

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **The input method app** — AC-013, AC-014
   - Files: `Sources/Minkey/main.swift`, `Sources/Minkey/InputController.swift`, `Sources/Minkey/IMKTextClient.swift`, `Resources/Info.plist`, `Resources/icon.tiff`, `scripts/bundle.sh`, `scripts/test-bundle.sh`, `scripts/install-dev.sh`, `docs/compatibility.md`
   - Test first: `scripts/test-bundle.sh` (Info.plist keys, executable, icon, `codesign --verify`)
   - Then: an IMK controller maps key events to `Key` and hands them to one shared `Delivery`; `Minkey --install` registers and enables the input source; AC-014 is the manual check in `docs/compatibility.md`.

## Public Surface

- `scripts/bundle.sh`, `scripts/install-dev.sh`, `Minkey --install` — AC-013
- bundle id `top.bigin.inputmethod.Minkey`, input source `top.bigin.inputmethod.Minkey.telex` — AC-013
