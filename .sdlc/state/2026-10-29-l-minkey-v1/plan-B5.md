# Part plan: minkey v1 B5

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **Macros, per-app languages, settings, diagnostic log** — AC-009, AC-010, AC-011, AC-012
   - Files: `Sources/MinkeyKit/Macros.swift`, `Sources/MinkeyKit/Modes.swift`, `Sources/MinkeyKit/Settings.swift`, `Sources/MinkeyKit/Diagnostics.swift`, `Sources/MinkeyKit/Delivery.swift`, `Sources/MinkeyEngine/Telex.swift` (Codable `ToneStyle`), the four test files
   - Test first: `macroExpandsFollowingCase`, `perAppModeAndToggle`, `settingsPersistAndMacrosRoundTrip`, `corruptSettingsFallBackToDefaultsAndAreKept`, `diagnosticLogMasksLettersAndExpires`
   - Then: macros expand at the boundary following case (English mode only when enabled, after verifying the text); each app's language is remembered and terminals/editors start English; settings are JSON with a corrupt file kept aside; the diagnostic log gets edit positions and lengths only, never text, and expires after 24 hours.

## Public Surface

- `Macros`, `Language`, `AppLanguages`, `Settings`, `Shortcut`, `SettingsStore`, `DiagnosticLog`, `EditRecord`; `Delivery.macros`, `.languages`, `.language`, `.onEdit`, `.toggleLanguage(_:)` — AC-009..012
- Default toggle shortcut: Control+Option+Space — AC-011
