# Part plan: minkey v1 B1

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **Telex engine** — AC-001, AC-002
   - Files: `Sources/MinkeyEngine/Letter.swift`, `Sources/MinkeyEngine/Telex.swift`, `Tests/MinkeyEngineTests/TelexTests.swift`
   - Test first: `telexWords`, `telexWordsOldStyle`, `undoTypesKeyAndStaysLiteral`, `deleteBackwardRemovesLastLetter`
   - Then: `TelexEngine` keeps decomposed letters (base, shape, tone, case), applies Telex keys to the nucleus, re-places the tone, and turns literal after an undo.

## Public Surface

- `TelexEngine` (`type`, `deleteBackward`, `word`, `toneStyle`) and `ToneStyle` — AC-001
