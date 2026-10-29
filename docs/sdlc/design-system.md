# Design system

<!-- Project-owned. Written at setup (design-system step) on 2026-10-29 under autopilot, not yet reviewed by the user.
     minkey's UI is a small macOS settings window and the input menu, so the system is the platform's own: stock
     SwiftUI and AppKit controls with system semantic colors, no custom tokens. -->

## Source of truth
- Library: SwiftUI (macOS 13+), with AppKit only where SwiftUI has no equivalent (the IMK input menu is an `NSMenu`)
- Tokens: none of our own; system semantic colors and text styles (`.primary`, `.secondary`, `Color.accentColor`,
  `.font(.body)`, …)
- Components: `Sources/Minkey/**/*View.swift`
- Icons: SF Symbols; the menu-bar icon is a template image in the app bundle; never emoji as icons
- Fonts: system font only
- Themes: light + dark, following the system

## Tokens
- Color roles: system semantic colors only; never a hard-coded RGB value
- Spacing: SwiftUI defaults (`Form`, `Section`, default padding); custom spacing only as multiples of 4 pt
- Type: `.title2` window section headers, `.body` for rows, `.caption` with `.secondary` for help text
- Radius / shadow / motion: system defaults; none of our own

## Components to reuse
| Need | Use | Not |
|---|---|---|
| A settings page | `Form { Section { … } }` with `.formStyle(.grouped)` | a hand-laid `VStack` of controls |
| On/off setting | `Toggle` | a checkbox-styled `Button` |
| One of a few choices | `Picker` | custom segmented buttons |
| The shortcut | a recorder view that reads the key combination | a free-text field |
| Lists (macros, per-app) | `Table` with add and remove buttons below | a `ScrollView` of custom rows |

## Patterns
- Layout: one settings window with a tab per area (General, Macros, Apps, About); fixed width, about 520 pt
- Forms: labels on the left (the default `Form` layout), help text under the control in `.caption`
- Feedback: invalid input shown inline under the field; no alerts for validation
- Empty and error states: an empty table shows one `.secondary` line on what to add

## Don't
- No custom colors, gradients or branding inside the settings window: it should look like part of macOS.
- No dialogs or alerts while someone is typing; the input method never steals focus.
- Every visible string goes through localization (Vietnamese first, English).

## Changing the system
A new token, component or variant is proposed in the feature's design (Complexity Tracking) or in review, approved by the user, then added here and to the tokens or component files in the same change.
