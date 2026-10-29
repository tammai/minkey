---
type: gotcha
title: Ad-hoc signing plus the hardened runtime can't load an embedded framework
description: Why a locally built Minkey.app crashed at launch once Sparkle was embedded.
tags: [build, signing]
updated: 2026-10-29
---

# Ad-hoc signing plus the hardened runtime can't load an embedded framework

## Symptom
`Minkey` aborts at launch (exit 134): dyld reports `Sparkle.framework … not valid for use in process: mapping process
and mapped file (non-platform) have different Team IDs`. `codesign --verify --deep --strict` still passes.

## Cause
With `--options runtime`, library validation requires the framework to carry the same team ID as the app. An ad-hoc
signature has no team ID at all, so no framework passes. `codesign --deep` also leaves the framework's original
(Sparkle's) signature in place.

## Fix
`scripts/bundle.sh` signs Sparkle's parts inside out, and adds the hardened runtime only when `SIGN_IDENTITY` is a
real certificate. Releases get the runtime from the Developer ID export, which `scripts/release.sh` checks.

## How to detect early
`scripts/test-bundle.sh` launches the app (`Minkey --version`); `codesign --verify` alone doesn't catch this.

## Related
- [teams-lagging-reads.md](teams-lagging-reads.md)
