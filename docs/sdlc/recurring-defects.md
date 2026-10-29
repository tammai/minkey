# Recurring defects

Defects review found in this project that a reviewer can check next time. One line each: what it looks like, then the severity.

- **A lagging client read changes delivery state:** a read right after minkey's own edit (Teams) returns stale or nil text and the code switches mode, stops typing or resumes the wrong word; delivery tests must type several words through `FakeClient(lagsReads: true)`. High.
- **Resume rewrites text minkey can't represent:** letters with marks outside Vietnamese (ç, ü, ñ) are rebuilt and "corrected". High.
- **A Vietnamese word can't be typed:** a valid syllable (`thuở`, `huơ`) is rejected by spell check and restored to keys. High.
- **A default shortcut that macOS already owns:** Control+Space or Control+Option+Space for the toggle. High.
- **A signed bundle that verifies but doesn't launch:** check by launching the app, not only `codesign --verify`. High.
