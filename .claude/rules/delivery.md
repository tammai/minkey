---
paths:
  - "Sources/Minkey/**/*"
---

# Delivery and app rules

- Never replace text minkey hasn't verified is the current word; when unsure, type the key literally.
- Never trust a client read taken right after minkey's own edit: Teams reports text one edit late.
- App quirks go in the per-app list or a delivery mode, never as injected keystrokes or invisible characters.
- Never log, store or send typed letters, the diagnostic mode included.
