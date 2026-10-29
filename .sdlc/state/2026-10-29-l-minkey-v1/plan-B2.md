# Part plan: minkey v1 B2

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **Syllable rules and spell check** — AC-003, AC-004
   - Files: `Sources/MinkeyEngine/Syllable.swift`, `Sources/MinkeyEngine/Telex.swift`, `Tests/MinkeyEngineTests/SpellingTests.swift`
   - Test first: `invalidChangeTypesKeyLiterally`, `invalidWordRestoresAtBoundary`, `spellCheckOffAppliesEveryKey`, `commonWordsStayVietnamese`
   - Then: `Syllable` checks onset + vowel cluster + coda + stop-coda tones; a Telex change whose result can't become valid is undone and the key typed literally; `endWord()` restores the typed keys when the word isn't valid.

## Public Surface

- `TelexEngine.spellCheck`, `TelexEngine.endWord()` — AC-004
