# Part plan: minkey v1 B3

**Record:** `docs/sdlc/changes/2026-10-29-l-minkey-v1.md` · **Backlog:** [backlog.md](backlog.md)

## Tasks

1. **Delivery against a text-client protocol** — AC-005, AC-006, AC-007, AC-008
   - Files: `Package.swift` (MinkeyKit target), `Sources/MinkeyKit/TextClient.swift`, `Sources/MinkeyKit/Delivery.swift`, `Sources/MinkeyEngine/Letter.swift` and `Telex.swift` (`resume`), `Tests/MinkeyKitTests/*.swift`
   - Test first: `directModeReplacesOnlyChangedCharacters`, `trackingDropsOnUnexpectedCursor`, `clientWithoutTextGetsMarkedMode`, `resumesWordAfterDeletingIntoIt`, against `FakeClient` (lagging reads like Teams; a terminal mode like the spike's)
   - Then: `Delivery` tracks the word and its cursor itself, replaces only changed characters, accepts the cursor one edit behind, detects marked mode per app, and resumes a word only on two agreeing reads.

## Public Surface

- `TextClient`, `Delivery`, `DeliveryMode`, `Key` (library product `MinkeyKit`) — AC-005
- `TelexEngine.resume(_:)` — AC-008
