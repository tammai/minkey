---
type: gotcha
title: Teams reports text one edit late
description: Why delivery tracks the word itself and never trusts a read right after its own edit.
tags: [delivery, apps]
updated: 2026-10-29
---

# Teams reports text one edit late

## Symptom
In Microsoft Teams (`com.microsoft.teams2`), `attributedSubstring` taken right after minkey's own `insertText` returns
the text from before that edit; right after a fast Delete or a passed-through key it can return nil past the end.
`selectedRange` and `replacementRange` are honoured.

## Cause
Teams' message box is a web editor; its text reports to the input method run behind its own edits.

## Fix
`Delivery` tracks the word and expected cursor itself, accepts the cursor one edit behind, starts the word after its
own boundary without a read, and starts a fresh word (never a resume) when the character before the cursor can't be
read. Review findings F1 and F7 were both this.

## How to detect early
Use `FakeClient` with `lagsReads = true` in any delivery test, and type more than one word through it.

## Related
- [ad-hoc-hardened-runtime.md](ad-hoc-hardened-runtime.md)
