# minkey: product requirements

<!-- Written by /sdlc:setup on 2026-10-29 from the brainstorm (.sdlc/minkey-v1/change.md) under autopilot. The user
     asked to change some answers without saying which, so every line here is marked "(inferred, confirm)" until they
     review it. Yours from then on: sdlc never overwrites it, and eject keeps it. -->

## Problem

Vietnamese speakers on the Mac type through keyboards that glitch in web-based apps. Apple's built-in Vietnamese input
underlines the word being composed, and Microsoft Teams duplicates that unfinished word when Delete is pressed.
OpenKey and EVKey fake backspaces through an event tap, which races with web editors (lost or doubled tones) and needs
the Accessibility permission. Teams, Slack and the browser are where most daily typing happens, so the glitches hit
hardest exactly there. (inferred, confirm)

## Users and audience

Consumers and office workers: anyone on macOS who types Vietnamese daily, often mixed with English, mostly in Teams,
Slack, browsers and native apps. Installed by non-developers from GitHub. (inferred, confirm)

## Goals and non-goals

**Goals**
- Correct Telex in every common app, Teams first: no underline, no duplicated, lost or misplaced text. (inferred, confirm)
- No Accessibility permission. (inferred, confirm)
- Installable and updatable by non-developers. (inferred, confirm)

**Non-goals**
- VNI, VIQR and legacy encodings (TCVN3, VNI-Windows). (inferred, confirm)
- Windows, Linux and the Mac App Store. (inferred, confirm)
- Any network use beyond checking for updates. (inferred, confirm)

## Core capabilities

1. Telex with free tone placement. (inferred, confirm)
2. Spell check that restores the typed letters when a word can't be Vietnamese. (inferred, confirm)
3. Macros: user shorthand that expands and follows capitalisation. (inferred, confirm)
4. Per-app Vietnamese/English memory. (inferred, confirm)
5. A settings window in Vietnamese and English. (inferred, confirm)

## Constraints

- Swift; InputMethodKit only, no event tap. (inferred, confirm)
- MIT licence; no code copied from GPL projects such as OpenKey. (inferred, confirm)
- macOS 13 Ventura or later. (inferred, confirm)
- Nothing typed is ever stored or sent. (inferred, confirm)

## Success measures

- Zero duplicated or corrupted text in Teams across a test session of several paragraphs with @mentions, replies and
  mid-word Delete. (inferred, confirm)
- A public list of tested apps that grows with each release. (inferred, confirm)
- App-specific bug reports fixed with a per-app entry rather than a new workaround in the engine. (inferred, confirm)

## Voice and brand

Plain and friendly, bilingual with Vietnamese first. The name "minkey" is always lowercase. (inferred, confirm)

## Open questions

- The user asked to change some of the answers above and hasn't said which yet.
