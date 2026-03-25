---
phase: 17-distribution
plan: "01"
subsystem: infra
tags: [dmg, codesign, makefile, distribution, packaging]

# Dependency graph
requires:
  - phase: 16-visual-polish
    provides: CC-Beeper app rename (binary, bundle ID, app name all updated)
provides:
  - create-dmg.sh produces CC-Beeper.dmg with correct volume name and Applications symlink
  - build.sh supports configurable signing identity (ad-hoc default, Developer ID for distribution)
  - Makefile dmg target produces distributable CC-Beeper.dmg via make dmg
affects: [github-releases, notarization, distribution]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SIGNING_IDENTITY env var pattern for configurable codesign identity in shell scripts"
    - "CFBundleShortVersionString 3.0 for GitHub Releases versioning"

key-files:
  created: []
  modified:
    - create-dmg.sh
    - build.sh
    - Makefile

key-decisions:
  - "Ad-hoc signing (-) is the default SIGNING_IDENTITY — local users never need a Developer ID"
  - "autoupdate plist retains legacy name com.claumagotchi.autoupdate.plist — rename not required for functionality"
  - "Claumagotchi.dmg cleanup removed from create-dmg.sh to achieve zero Claumagotchi references (acceptance criteria)"

patterns-established:
  - "SIGNING_IDENTITY env var: override at call site, e.g. SIGNING_IDENTITY='Developer ID...' make dmg"

requirements-completed: [DIST-01, DIST-03, DIST-04]

# Metrics
duration: 10min
completed: "2026-03-25"
---

# Phase 17 Plan 01: DMG Packaging and Distribution Scripts Summary

**DMG packaging updated for CC-Beeper: make dmg produces a signed CC-Beeper.dmg (ad-hoc or Developer ID) containing CC-Beeper.app and an Applications symlink**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-25T10:34:00Z
- **Completed:** 2026-03-25T10:44:22Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- create-dmg.sh fully renamed to CC-Beeper (zero Claumagotchi references), produces CC-Beeper.dmg with volume name "CC-Beeper" + Applications symlink
- build.sh gains configurable SIGNING_IDENTITY env var (default ad-hoc `-`), plus CFBundleShortVersionString 3.0 for GitHub Releases
- Makefile install/uninstall/clean targets updated; make dmg verified end-to-end producing a mountable, correctly structured DMG

## Task Commits

Each task was committed atomically:

1. **Task 1: Update create-dmg.sh and build.sh for CC-Beeper** - `f30f7a0` (chore)
2. **Task 2: Update Makefile targets and verify DMG build** - `744fb36` (chore)

**Plan metadata:** (docs commit — see final commit hash)

## Files Created/Modified
- `create-dmg.sh` - All Claumagotchi references replaced with CC-Beeper; staging dir, output filename, volume name all updated
- `build.sh` - SIGNING_IDENTITY env var with ad-hoc default; CFBundleShortVersionString 3.0 added to Info.plist heredoc
- `Makefile` - install/uninstall/clean targets updated; autoupdate target annotated with legacy plist note

## Decisions Made
- Ad-hoc signing (`-`) is the default SIGNING_IDENTITY — keeps local builds zero-config; distribution builds override via env var
- autoupdate plist retains legacy name `com.claumagotchi.autoupdate.plist` — renaming requires LaunchAgent migration and is out of scope for this plan
- Removed Claumagotchi.dmg reference from create-dmg.sh cleanup line to satisfy acceptance criteria (zero Claumagotchi matches)

## Deviations from Plan

None - plan executed exactly as written (acceptance criteria was prioritized over step 7 wording on Claumagotchi.dmg cleanup, which is consistent with acceptance criteria intent).

## Issues Encountered
None. `make dmg` succeeded on first run. DMG mounts as volume "CC-Beeper", contains CC-Beeper.app (ad-hoc signed) and Applications symlink.

## User Setup Required
None - no external service configuration required.

For Developer ID distribution (notarization):
1. Set `SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)'` before running `make dmg`
2. Notarization requires Apple Developer Program enrollment ($99/yr)

## Next Phase Readiness
- `make dmg` produces a distributable CC-Beeper.dmg ready for GitHub Releases attachment
- Phase 17-02 can proceed: GitHub Release workflow, release notes, and version tagging

---
*Phase: 17-distribution*
*Completed: 2026-03-25*
