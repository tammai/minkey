# Part plan: minkey v1 B7

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **Distribution** — AC-015 (manual: needs the author's certificates and keys)
   - Files: `Package.swift` (Sparkle 2.6.4), `Package.resolved`, `Sources/Minkey/Updater.swift`, `Sources/Minkey/InputMenu.swift`, `Sources/Minkey/main.swift`, `Resources/Info.plist`, `scripts/bundle.sh`, `scripts/test-bundle.sh`, `scripts/build-pkg.sh`, `scripts/pkg/postinstall`, `scripts/release.sh`, `README.md`, `LICENSE`
   - Then: Sparkle embedded and signed inside out; a non-relocatable pkg into `/Library/Input Methods` that registers minkey for the console user; `release.sh` follows the cloud-managed Developer ID recipe (hand-built xcarchive + `xcodebuild -exportArchive`), refuses an export without the hardened runtime, notarizes and staples the pkg, and writes a signed appcast.

## Public Surface

- dependency Sparkle 2.6.4 — AC-015
- `scripts/build-pkg.sh`, `scripts/release.sh` (env `TEAM_ID`, `INSTALLER_IDENTITY`, `NOTARY_PROFILE`, `SPARKLE_PUBLIC_KEY`) — AC-015
- `Minkey --version` — AC-013
