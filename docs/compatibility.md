# App compatibility

How minkey sends text to each app it has been tested in. **Direct** means finished text replaced in place, with no
underline. **Marked** means underlined composing text, used where an app can't report what is before the cursor.
minkey picks the mode itself; a per-app setting can force either.

| App | Bundle id | Mode | Last checked | Notes |
|---|---|---|---|---|
| Microsoft Teams | `com.microsoft.teams2` | direct | 2026-10-29 (spike) | reads lag one edit behind; minkey tracks the word itself |
| Google Chrome | `com.google.Chrome` | direct | 2026-10-29 (spike) | page fields; address bar not yet checked |
| Spotlight | `com.apple.Spotlight` | direct | 2026-10-29 (spike) | |
| Orca (xterm.js terminal) | `com.stablyai.orca` | marked | 2026-10-29 (spike) | reports the cursor as `{1, 0}` and ignores replacements |

## Manual check (before each release)

Install with `scripts/install-dev.sh`, pick minkey from the input menu, then in each app:

1. **Teams**, in a chat message box: type `Tieengs Vieetj raast hay, class mention with`. Expect `Tiếng Việt rất hay,
   class mention with`, with no underline.
2. Type `tieengs`, press Delete three times (`tiế`), then type `ngf`. Expect `tiềng`, nothing duplicated.
3. Type `@` and part of a colleague's name with a tone (`@Tuaans`). Pick them, then keep typing `caamf giusp mif`.
4. Reply to a message and repeat step 1.
5. **Chrome**: a page's text field and the address bar, step 1.
6. **Spotlight** (Cmd+Space): step 1 and step 2.
7. **A terminal**: terminals start in English, so press Control+Shift+Space first, then step 1. Expect underlined
   text while typing, committed at each space.
8. **Settings**: from the input menu, open Settings…, switch tone placement to old style and type `hoaf` (expect
   `hòa`); add the macro `ko` → `không` and type `ko `; press Control+Shift+Space and check the app switches to
   English, then switch to another app and back. With macOS set to Vietnamese, the window and menu are in Vietnamese.
   In the Macros tab, type a Vietnamese expansion with minkey itself (`khoong` → `không`), and check Cmd-C, Cmd-V and
   Cmd-W work in the window.

Record each app's result in the table above.
