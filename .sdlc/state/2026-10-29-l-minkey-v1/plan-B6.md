# Part plan: minkey v1 B6

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **Settings window, input menu, settings wired into the app** — AC-011 (persistence tested in B5; the window is checked by hand and in UI review)
   - Files: `Sources/Minkey/SettingsView.swift`, `Sources/Minkey/InputMenu.swift`, `Sources/Minkey/AppState.swift`, `Sources/Minkey/InputController.swift`, `Sources/Minkey/main.swift`, `Resources/vi.lproj/Localizable.strings`, `Resources/en.lproj/Localizable.strings`, `Resources/Info.plist`, `scripts/bundle.sh`, `docs/compatibility.md`
   - Then: a SwiftUI window (General, Macros, Apps, About) per `docs/sdlc/design-system.md`; the input menu toggles language and opens Settings; the toggle shortcut works in any app; every change is saved and applied at once.

## Public Surface

- Settings file `~/Library/Application Support/minkey/settings.json`; diagnostic log `~/Library/Logs/minkey-diagnostics.log` — AC-011, AC-012
