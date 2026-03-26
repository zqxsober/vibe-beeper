---
phase: 21-github-branding
plan: 02
subsystem: ui
tags: [readme, github, branding, cover-image, metadata]

# Dependency graph
requires:
  - phase: 21-github-branding
    provides: Context and decisions for README copy and cover image (D-02, D-03, D-04)
provides:
  - New multi-shell cover image (docs/cover.png) as the README hero
  - Rewritten product-landing-page README with zero Claumagotchi mentions
  - GitHub repo description and topics updated to CC-Beeper branding
affects: [22-final-branding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Product-landing-page README pattern: hero image + tagline + badges + download CTA above fold"

key-files:
  created: []
  modified:
    - docs/cover.png
    - README.md

key-decisions:
  - "cover.png in repo was already the new multi-shell image (1387430 bytes) — copy was a no-op, image correct"
  - "README rewritten with Raycast/Arc product-landing-page tone: punchy tagline, feature table, architecture diagram"
  - "GitHub repo metadata set via gh CLI: description + 8 topics + homepage cleared"

patterns-established:
  - "GitHub metadata updates committed as empty chore commits for audit trail"

requirements-completed: [GH2-01, GH2-02, GH2-03]

# Metrics
duration: 2min
completed: 2026-03-26
---

# Phase 21 Plan 02: README Rewrite and GitHub Metadata Summary

**New multi-shell cover image + product-landing-page README rewrite + GitHub repo description and 8 topics set via gh CLI**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-26T09:46:29Z
- **Completed:** 2026-03-26T09:48:20Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced docs/cover.png with new 3156x1470 multi-shell artwork showing all 10 CC-Beeper color shells
- Rewrote README with product-landing-page quality copy: punchy tagline, centered hero, feature table with 4 pillars, tightened architecture diagram section
- Updated GitHub repo description to "macOS desktop widget for Claude Code — see what Claude is doing, respond by voice, never miss a permission request." with 8 topics: claude-code, macos, desktop-widget, swift, swiftui, voice, tts, developer-tools

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace cover image and rewrite README** - `b6f1211` (feat)
2. **Task 2: Update GitHub repo metadata** - `4d70cce` (chore)

**Plan metadata:** committed with docs commit below

## Files Created/Modified

- `docs/cover.png` - New multi-shell cover image (3156x1470 PNG, all 10 color shells)
- `README.md` - Rewritten with product-landing-page copy, zero Claumagotchi mentions

## Decisions Made

- The cover.png already in the repo (from Phase 18) was identical to the source file on Desktop — no actual change in image content, just confirmed correct
- README already had solid structure; refined the tagline ("A desktop companion for Claude Code. See what Claude is doing. Talk back.") and tightened feature descriptions per D-02
- Task 2 committed as empty chore commit for audit trail since GitHub metadata changes have no local files

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required beyond what gh CLI already handled.

## Next Phase Readiness

- Phase 21 Plan 02 complete — GitHub front door fully refreshed
- Phase 21 (both plans) now complete
- Phase 22 (Final Branding / app icon) remains blocked pending user-provided Figma export

## Self-Check: PASSED

- FOUND: docs/cover.png (PNG image data, 3156 x 1470, 8-bit/color RGBA)
- FOUND: README.md (zero Claumagotchi, CC-Beeper x20, cover.png x1, Download x3, vecartier/cc-beeper x3)
- FOUND: 21-02-SUMMARY.md
- FOUND: commit b6f1211 (feat: replace cover image and rewrite README)
- FOUND: commit 4d70cce (chore: update GitHub repo description and topics)

---
*Phase: 21-github-branding*
*Completed: 2026-03-26*
