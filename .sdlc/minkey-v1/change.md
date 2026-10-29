# minkey v1: a Vietnamese Telex input method for macOS

<!-- Size L. Brainstormed 2026-10-29. Define fills Acceptance criteria, Acceptance tests, Must never break and
     Failure modes from the design below; the seeds listed under them are from the brainstorm. -->

## Why

**Request (verbatim):** "brainstorm for a vietnamese input keyboard for macos using InputMethodKit and Swift"

Vietnamese typists on the Mac today use either Apple's built-in Vietnamese input or OpenKey / EVKey. Both glitch in
web-based apps, Microsoft Teams worst of all. minkey is a free, open-source Vietnamese Telex input method, built in
Swift on InputMethodKit, that types correctly in those apps, Teams first. It is for everyone, not only its author:
published on GitHub, installed by non-developers.

Why the existing tools fail (established in this brainstorm, see "Spike results" below):

- **OpenKey and EVKey on macOS** don't use the input-method system. They watch keystrokes through an event tap
  (needing the Accessibility permission) and fake edits: a backspace per changed letter, then the new letters.
  Web editors handle keys on their own timing, so this races. OpenKey's source shows the workarounds this forces:
  inserting an invisible U+202F to defeat browser autocomplete, per-app lists for Chrome/Edge, Sublime, Spotlight.
  Teams is on none of its lists.
- **Apple's built-in Vietnamese input** uses marked text (the underlined, still-composing word). Teams' message box
  loses track when Delete is pressed inside a composing word, and pastes its stale copy of the whole unfinished word at
  the end of the message. This is the bug the user hits.

**The user's words:**

- Why build one: "existing ones glitch in many apps, espectially on MS Teams"
- The Teams bug: "it has underline sometime I delete a key it duplicate the whole uncomplete word to the end of string"
- Approach to prior art: "learn from openkey and evkey to create a new one"
- Features they use day to day: "telex, free tone, spell check, macros, per-app switching"
- Audience: "minkey is for everyone"
- Release: "free and opensource on github"
- Approach chosen: "option 3, swift engine, run the teams test first" (option 3 is described under Decisions)
- Spike outcome in Teams: "yes it looked fine, no duplicates"
- Spike bug 1: "tưần <- this word is incorrect and should not be compose" (typed `tuần` + `w`)
- Spike bug 2: "when i typing english here, it also turn into vietnamese too but dont show up" (in a terminal app)
- Spike bug 3: "tieengs -> delete to tieens and continue typing f o x or j does change" (in Spotlight; the tone keys did
  not apply after deleting back into a finished word)

**What success looks like:** a person types a few paragraphs of Vietnamese with English words mixed in, in Teams
(including @mentions, replies, and Delete in the middle of words), with no underline, no duplicated, lost or misplaced
text and no mangled English. The same holds in Slack, Chrome (pages and address bar), Spotlight, native apps and
terminals. Installing it needs no Accessibility permission.

**Anti-goals (a failure even if it technically works):**

- Any text duplication or corruption in Teams. That is the reason this project exists.
- Mangling English words that can't be Vietnamese (`class` → `cláss`, `mention` → `méntion`). English words that are
  also valid Telex (`is` → `í`, `as` → `á`, `of` → `ò`, `bus` → `bú`) are accepted collisions, as in OpenKey and
  EVKey: typing the tone key twice gives the English back (`iss` → `is`), and the toggle covers longer English. No
  English dictionary overrides Vietnamese, so every Vietnamese word stays typable.
- Ever writing into the wrong place: when minkey is unsure what is before the cursor, it must fall back to safe
  behaviour, never guess.
- Collecting or sending what people type.

## Decisions

| Decision | Ruled out | Why |
|---|---|---|
| **Option 3: direct replacement by default, marked-text fallback per app.** Each keystroke is committed as final text; when a key changes earlier letters, minkey calls `insertText(_:replacementRange:)` on the client for just the changed characters. Apps that can't report the text before the cursor get marked text instead. | **Option 1**, direct replacement only: breaks outright in apps that ignore `replacementRange` or misreport the cursor (the spike's terminal). **Option 2**, marked text like Apple's: it is exactly what breaks Teams today. | Teams gets no underline (proven by the spike), and awkward apps still work. A new app quirk becomes a one-line override, not a hack. |
| **Our own Swift Telex engine, MIT-licensed**, written from OpenKey's documented rules, with OpenKey's changelog edge cases as tests | Porting OpenKey's C++ engine as-is (GPL-3, global-state design, C++ inside a Swift project) | Easier to test and read for contributors; licence stays free. We learn from OpenKey's rules but copy none of its code. |
| **InputMethodKit, no event tap** | Event tap + faked backspaces (OpenKey/EVKey style) | The root cause of their glitches; also needs the Accessibility permission, which minkey avoids. |
| **Telex only, Unicode precomposed output only** | VNI, VIQR, TCVN3, VNI-Windows, Unicode compound | Not used by the user; can be added later as engine input/output tables. |
| **Run a throwaway Teams spike before designing** | Designing on assumptions | Whether Teams honours `replacementRange` was the one fact reading could not settle. It does. |

### Spike results (2026-10-29)

A ~250-line throwaway IMK input method (minimal Telex, direct replacement only, per-keystroke logging) was installed
and used by the user. Bundle id `top.bigin.inputmethod.MinkeySpike`; source kept outside the repo, not to be reused as
code.

| App (bundle id) | `selectedRange` | `attributedSubstring` before cursor | `replacementRange` honoured | Notes |
|---|---|---|---|---|
| Teams (`com.microsoft.teams2`) | correct | correct, but **can lag one edit behind** (reads right after an edit return pre-edit text; twice right after a fast Delete) | yes, every time; user confirmed no duplicates on screen | @mentions and replies fine |
| Chrome page (`com.google.Chrome`) | correct | correct, immediate | yes | address bar not yet tested |
| Spotlight (`com.apple.Spotlight`) | correct | correct, immediate | yes | |
| Orca terminal (`com.stablyai.orca`, xterm.js in Electron) | **always `{1, 0}`** | nil or wrong | **no**: replacements silently dropped, so the screen kept `i` while minkey believed `í` | needs the marked-text fallback |

Bugs the spike exposed, all fixed by the design below:

1. No spell check: `tuần` + `w` → `tưần`, and English words got tones (`mention` → `méntion`, `is` → `í`).
2. Undo looped: repeated `f` toggled the tone on and off forever instead of typing `f` after one undo.
3. A word was forgotten at the space, so deleting back into it and typing a tone key did nothing.
4. With no fallback, a terminal silently ignored edits.

### The design

**Pieces.** Three separately testable parts:

1. **Engine** (pure Swift package, no AppKit): keystrokes in, the current word out. Knows Telex, tones, spelling.
   Has no idea which app it is in.
2. **Delivery**: turns "the word changed from A to B" into client calls, in direct or marked mode, and owns the
   capability check and the safety rules.
3. **App shell**: the IMK server and controller, settings, per-app memory, macros, the menu, the updater.

**Engine behaviour.**

- **Telex**: `aa`→â, `ee`→ê, `oo`→ô, `aw`→ă, `ow`→ơ, `uw`→ư, `uow`→ươ, `dd`→đ. Tones `s f r x j`, and `z` removes
  the tone. `w` on its own (no vowel yet) → ư.
- **Free tone**: tone and shape keys apply anywhere in the word (`tieengs`, `tieesng` and `tiengse` all give
  `tiếng`). The tone is re-placed automatically as the word grows.
- **Tone placement**: new style by default (`hoà`, `thuý`); a setting switches to old style (`hòa`, `thúy`).
  Handles `qu`/`gi` as onsets and `ươ` taking the tone on ơ.
- **Undo**: a repeated modifier key undoes and types the key literally (`ass` → `as`, `aaa` → `aa`, `ddd` → `dd`).
  After an undo, the word is treated as literal: further Telex keys in that word are typed as letters (fixes spike
  bug 2).
- **Spell check (always on by default)**: a change is applied only if the result is a valid Vietnamese syllable
  (onset + medial + nucleus + coda, with the tone allowed by the coda: stop codas `p t c ch` take only sắc or nặng).
  Otherwise the key is typed literally (fixes spike bug 1).
- **Restore when the word ends invalid**: if, at the word boundary, the word is not a valid syllable, it reverts to
  exactly the keys typed (`class` stays `class`; `mentions` stays `mentions`).
- **Uppercase**: per-letter case is kept (`Vieetj` → `Việt`, `DDaay` → `Đây`).
- OpenKey's changelog edge cases become engine tests from day one: `duocd`, `duongd`, `quatw`, `oăc`, `quởn`, `gì`,
  plus the words from this brainstorm (`tiếng`, `được`, `người`, `trường`, `hoặc`, `quá`, `Việt`, `Đây`, `tuần`+`w`).

**Delivery behaviour.**

- **minkey owns every edit inside the current word.** Plain letters inside a tracked word are inserted by minkey too,
  not passed through, and Delete inside a tracked word is done by minkey (replacing the last character with nothing).
  minkey tracks the word and the cursor offset itself and never trusts a read taken right after its own edit. This
  is the lesson of Teams' lagging reads.
- **Capability check per app** (at activation, cached per bundle id; re-checked if a check later fails): does
  `selectedRange` return a plausible location, and does `attributedSubstring` return text? Both yes → direct mode.
  Otherwise → marked mode.
- **Safety rule in direct mode**: verify once, at the word's first key, before minkey has edited anything: the
  character before the cursor must be a boundary (not a letter), or the word must resume (below). From then on
  minkey trusts its own tracking of the word and doesn't re-read, because a read right after its own edit lags in
  Teams. Tracking is dropped (the key typed literally) on any event that could move the cursor or change the text
  outside minkey: a boundary key, a mouse click, focus change, or `selectedRange` jumping to a location minkey didn't
  produce. That last one is only treated as a jump when it is outside the one-edit lag window.
- **Marked mode**: the current word is marked text and is committed at the word boundary, on Delete-to-empty,
  on focus loss and on `commitComposition`. (Terminals; anything that fails the check.)
- **Per-app override**: a built-in list shipped inside the app (changed only by app updates, so no extra network
  endpoint) plus a user setting to force direct, marked or off for any app.
- **Resume a word after deleting back into it** (fixes spike bug 3, direct mode only): when a letter is typed with
  no tracked word and the character before the cursor is a letter, read the word before the cursor and continue it.
  Because Teams can lag, read twice and resume only if both reads agree; otherwise start a new word. In marked mode
  there's no resume: the letters are taken as a new word, which is the safe failure.
- **Word boundaries**: space, punctuation, Return, Tab, arrows, Esc, any Cmd/Ctrl/Option chord, mouse click (detected
  as an unexpected cursor jump), focus change.

**App shell behaviour.**

- **Vietnamese/English toggle** inside minkey with one configurable shortcut (the default is left to the builder;
  Ctrl+Space is already macOS's input-source switch). English mode passes every key through untouched.
- **Per-app memory**: remembers Vietnamese or English per app and restores it when you switch back. Sensible
  built-in defaults: terminals and code editors start in English.
- **Macros**: user-defined shorthand, expanded at the word boundary, case-following (`btw`, `Btw`, `BTW`). Settings
  allow add, edit, delete, import and export (a plain file format). An option controls whether macros also work in
  English mode.
- **Settings window** in Vietnamese and English, reachable from minkey's input menu: toggle shortcut, tone style,
  spell check on/off, macros, the per-app list (Vietnamese/English default and the delivery override).
- **Privacy**: no network access except the update check. Nothing typed is stored or sent, and logs never contain
  typed text, the diagnostic mode included.

**Distribution.**

- Public GitHub repo, MIT licence. Free.
- Signed with Developer ID and notarized; installed as a `.pkg` into `~/Library/Input Methods` (or
  `/Library/Input Methods`; the builder's call), then the user adds it under System Settings → Keyboard → Input
  Sources. No Accessibility permission.
- Automatic updates with Sparkle (signed appcast on GitHub Releases).
- **Releases are cut on the author's Mac**, not in CI: the existing Developer ID certificate is cloud-managed and can't
  be exported to GitHub Actions. A release script archives, exports with `xcodebuild -exportArchive`, notarizes,
  staples, signs the Sparkle update with an EdDSA key kept in the author's Keychain, and uploads to GitHub Releases.
  CI builds and runs tests unsigned on every push.
- Minimum macOS 13 Ventura; the spike ran on macOS 26.6.
- A public compatibility list of tested apps and their delivery mode, starting from the spike table above.

### Goals, non-goals, constraints

- **Goals**: correct Telex in Teams with no underline; free tone; spell check with restore; macros; per-app
  Vietnamese/English memory; installable by non-developers.
- **Non-goals for v1**: VNI/VIQR, legacy encodings, quick Telex (`cc`→`ch`), auto-capitalising the first letter, an
  encoding converter, the Mac App Store, Windows or Linux.
- **Constraints**: Swift; InputMethodKit only (no event tap, no Accessibility permission); MIT, so no OpenKey code is
  copied; macOS 13+.

### Calls made by Claude (not asked of the user)

- New-style tone placement as default; old style as a setting.
- Spell check on by default; after an undo, the rest of the word is literal.
- minkey inserts plain letters itself inside a tracked word (not passthrough), from the Teams lag finding.
- Resume-after-delete reads twice before trusting Teams.
- Direct-mode verification happens once at the word's first key, then minkey trusts its own tracking (from the
  builder check: re-reading after each edit would always fail in Teams).
- The built-in per-app list changes only with app updates.
- Releases are signed and notarized on the author's Mac with the existing cloud-managed Developer ID; CI is unsigned.
- English/Telex collisions (`is` → `í`) are accepted, with double-key undo; no English dictionary (user: "i dont know,
  you do your best").
- Both unasked proposals kept; the diagnostic mode masks letters and expires after 24 hours.
- Terminals and code editors default to English in per-app memory.
- MIT licence, Sparkle, macOS 13 minimum, `.pkg` installer.
- The bundle id domain `top.bigin` reused from the spike; the builder may change it before first release.

### Left to the builder

- The default toggle shortcut (it must not clash with macOS input-source switching).
- The exact syllable validation tables (from Vietnamese phonotactics; OpenKey's tables are a reference for rules,
  not code to copy).
- How the capability check probes an app without side effects.
- Settings UI layout (SwiftUI is expected), the macro file format, and the installer location.
- Project layout and build tooling (Xcode project or SwiftPM plus a script), CI, and how the IMK bundle is tested.

**Proposals not asked for (user left them to Claude; both kept):**

- A public compatibility list of tested apps and the delivery mode each uses, in the repo's docs.
- A diagnostic logging mode, off by default, turned on from settings for troubleshooting one app. It records the app's
  bundle id, the delivery mode, `selectedRange`, replacement ranges and whether reads matched, but **masks letters**:
  it never records what was typed. It turns itself off after 24 hours.

## Acceptance criteria

<!-- Define writes these. Seeds from the brainstorm: Teams no-duplicate after Delete mid-word; spell check rejects
     `tuần`+`w`; English words that can't be Vietnamese survive Vietnamese mode; `iss` → `is`; terminal falls back to marked text; resume after deleting into
     a finished word; undo stops toggling; macros keep case; per-app memory restores the mode. -->

## Acceptance tests

<!-- Define writes these. -->

## Must never break

- minkey never writes into text it hasn't verified is the current word.
- Nothing typed leaves the machine or is logged by default.

## Failure modes

<!-- Define writes these. Seeds: an app that lags its text reports (Teams); an app that ignores replacementRange
     (terminals); a mouse click or programmatic text change mid-word; focus change mid-word; a very long "word"
     (pasted or held key). -->

## Out of scope

- VNI, VIQR, legacy encodings, quick Telex, auto-capitalise, the encoding converter (not used by the user).
- Mac App Store distribution, Windows, Linux.
- Reusing the spike's code; it was throwaway.

## Review
