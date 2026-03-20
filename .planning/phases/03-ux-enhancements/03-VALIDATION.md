---
phase: 3
slug: ux-enhancements
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no test framework) |
| **Config file** | none |
| **Quick run command** | `swift build -c release 2>&1 \| tail -5` |
| **Full suite command** | `swift build -c release && python3 -c "exec(open('hooks/claumagotchi-hook.py').read())" 2>/dev/null; echo $?` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift build -c release 2>&1 | tail -5`
- **After every plan wave:** Run full build + Python syntax check
- **Before `/gsd:verify-work`:** Full build must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 03-01-01 | 01 | 1 | UX-01, UX-03 | build + grep | `swift build -c release && grep 'sessionCount' Sources/ClaudeMonitor.swift` | pending |
| 03-01-02 | 01 | 1 | UX-02 | build + grep | `swift build -c release && grep 'case idle' Sources/ClaudeMonitor.swift` | pending |
| 03-02-01 | 02 | 2 | UX-04 | build + grep | `swift build -c release && grep 'addGlobalMonitorForEvents' Sources/ClaudeMonitor.swift` | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Session count displays correctly | UX-01 | Visual on LCD screen | Start 2 Claude sessions, verify count shows "2" |
| Sleeping animation plays after idle | UX-02 | Visual + timing | Wait 60s after session ends, verify sleeping sprite |
| Full path shown in permission prompt | UX-03 | Visual + IPC flow | Trigger permission, verify full path not just basename |
| Option+A/D work system-wide | UX-04 | Requires Accessibility permission | Grant accessibility, trigger permission, press Option+A from another app |
| Hotkeys don't fire without pending permission | UX-04 | Behavioral edge case | Press Option+A with no pending permission, verify no action |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
