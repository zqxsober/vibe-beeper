# In-App Update Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add manual in-app update checks that compare the running app version against GitHub Releases and open the latest release page.

**Architecture:** A small `UpdateCore` target owns version comparison and release decoding so it can be tested directly. The app target owns networking and UI state through `InAppUpdateChecker`, then renders the control in `SettingsAboutSection`.

**Tech Stack:** SwiftPM, Swift, SwiftUI, Foundation `URLSession`, GitHub Releases latest API.

---

### Task 1: Core Version Tests

**Files:**
- Create: `Tests/CC-BeeperTests/AppVersionTests.swift`
- Modify: `Package.swift`
- Create: `Sources/UpdateCore/AppVersion.swift`
- Create: `Sources/UpdateCore/GitHubRelease.swift`

- [ ] **Step 1: Write failing tests** for `AppVersion` comparison and `GitHubRelease` decoding.
- [ ] **Step 2: Run** `swift test --filter AppVersionTests` and verify the module is missing.
- [ ] **Step 3: Add `UpdateCore` target** and implement minimal version comparison and JSON decoding.
- [ ] **Step 4: Re-run** `swift test --filter AppVersionTests` and verify pass.

### Task 2: App Update Checker

**Files:**
- Create: `Sources/Updates/InAppUpdateChecker.swift`
- Create: `Tests/CC-BeeperTests/InAppUpdateIntegrationTests.swift`

- [ ] **Step 1: Write failing source integration tests** for the GitHub latest endpoint and About update entry.
- [ ] **Step 2: Run** `swift test --filter InAppUpdateIntegrationTests` and verify failures.
- [ ] **Step 3: Implement `InAppUpdateChecker`** with `idle`, `checking`, `upToDate`, `updateAvailable`, and `failed` states.
- [ ] **Step 4: Re-run** `swift test --filter InAppUpdateIntegrationTests` and verify pass.

### Task 3: Settings UI Integration

**Files:**
- Modify: `Sources/Settings/SettingsAboutSection.swift`

- [ ] **Step 1: Add `@StateObject` checker** to the About section.
- [ ] **Step 2: Render update status text** beside the update button.
- [ ] **Step 3: Open the release page** with `NSWorkspace.shared.open` when an update is available.
- [ ] **Step 4: Run** `swift test` and verify the suite passes.

