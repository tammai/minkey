# Backlog: 2026-10-29-l-minkey-v1

Record: `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · Branch: `2026-10-29-l-minkey-v1` · Each slice gets a short `plan-B<n>.md` when it starts and ends as one commit on the branch.

| ID | Slice | FRs | ACs | Deps | Size | Status |
|---|---|---|---|---|---|---|
| B1 | Telex engine: shapes, tones, free tone, placement styles, case, undo | — | 1, 2 | — | M | in progress |
| B2 | Spelling: syllable validation, literal key on invalid change, restore at boundary | — | 3, 4 | B1 | M | todo |
| B3 | Delivery logic against a text-client protocol: direct mode, safety, marked mode, resume | — | 5, 6, 7, 8 | B2 | M | todo |
| B4 | The input method app: IMK controller on B3, bundle script, local install, manual check in real apps | — | 13, 14 | B3 | M | todo |
| B5 | Macros, per-app modes and toggle, settings store, diagnostic log | — | 9, 10, 11, 12 | B4 | M | todo |
| B6 | Settings window (SwiftUI, Vietnamese and English) and input menu | — | 11 | B5 | M | todo |
| B7 | Distribution: pkg, release script with notarization, Sparkle, compatibility list | — | 15 | B6 | M | todo |
