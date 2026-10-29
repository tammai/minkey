---
paths:
  - "Sources/MinkeyEngine/**/*"
  - "Tests/MinkeyEngineTests/**/*"
---

# Engine rules

- Never import AppKit, InputMethodKit or any UI framework here; the engine never knows which app it is in.
- Every Telex edge case from a bug report becomes a test before the fix.
- Rules may come from OpenKey's documented behaviour; never copy or translate its GPL code.
