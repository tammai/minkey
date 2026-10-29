<!-- Sync report
     Version: none → 1.0.0 (first ratification).
     Principles added: I Engine Is Pure, II Never Write Blind, III Test-First, IV Typed Text Stays Private,
     V Simplicity (sdlc default), VI Clean-Room Licence.
     Written under /sdlc:setup in autopilot on 2026-10-29, inferred from docs/sdlc/prd.md and
     .sdlc/minkey-v1/change.md. NOT YET REVIEWED by the user.
     Follow-ups: none (no CLAUDE.md yet; the orchestrator's gates don't contradict these). -->

# minkey Constitution

## Core Principles

### I. Engine Is Pure
The Telex engine (`Sources/MinkeyEngine`) MUST NOT import AppKit, InputMethodKit or any UI framework, and MUST NOT
know which app it is typing into. It takes keystrokes and returns the current word; app-specific behaviour MUST live
in the delivery layer or the per-app list.
*Why:* the engine is where correctness lives, so it must be testable with plain unit tests and no running input method.

### II. Never Write Blind
In direct mode, minkey MUST NOT replace text it hasn't verified is the current word. When unsure what's before the
cursor, it MUST type the key literally (or fall back to marked text), never guess. App quirks MUST be handled by a
per-app entry or a delivery mode, not by injecting keystrokes or invisible characters.
*Why:* corrupting what someone is writing is the failure this project exists to remove.

### III. Test-First
Every behaviour change MUST have a test that fails before the change and passes after. Every Telex edge case found in a
bug report MUST become an engine test before it's fixed. Behaviour that only a real app can show (Teams, a terminal)
MUST be recorded as a manual check with the app and steps.
*Why:* Telex has hundreds of edge cases, and regressions in one word are easy to miss by eye.

### IV. Typed Text Stays Private
minkey MUST NOT store, log or send anything a person types, the diagnostic mode included (it records positions and app
ids with letters masked). The only network access MUST be the update check.
*Why:* a keyboard sees everything; trust is the product.

### V. Simplicity
Changes MUST be the smallest that meet the acceptance criteria. New abstractions, options, configuration, public exports
and dependencies MUST be justified by a current requirement, not a possible future one; an abstraction with a single
implementation needs a written reason. Comments MUST explain *why*, never restate the code or its change history; doc
comments are for exported API and are one line unless the contract needs more.

### VI. Clean-Room Licence
minkey is MIT. Code from GPL projects (OpenKey, UniKey, and others) MUST NOT be copied or translated line by line;
their documented rules and test words MAY be used as references. A new dependency MUST have a licence compatible with
MIT.
*Why:* keeps minkey free for anyone to reuse.

## Platform Constraints

- Swift 6 language mode, Swift Package Manager, macOS 13 or later.
- InputMethodKit only: no event taps, no Accessibility permission.
- Releases are signed with Developer ID and notarized; unsigned builds are for development only.

## Quality Gates

- `swift format lint --strict`, `swift build -c release` and `swift test` MUST pass locally and in CI before merge.
- A change to delivery behaviour MUST list the apps it was checked in (at least Teams, a Chromium browser and a
  terminal).

## Governance

This constitution overrides other practice. Amendments are proposed in a feature's change file, approved by the
maintainer, and versioned here (MAJOR: a principle removed or redefined; MINOR: one added or expanded; PATCH: wording).

**Version**: 1.0.0 | **Ratified**: 2026-10-29 | **Last Amended**: 2026-10-29
