# In-App Update Check Design

## Goal

Add a production-safe, manual in-app update check for vibe-beeper without changing the current GitHub Releases + DMG distribution flow.

## Selected Approach

Use the GitHub Releases latest API from inside the app, compare the latest release tag with the running app version, and open the release page when a newer version exists.

This is preferred for the current app because the project already publishes DMG artifacts through GitHub Releases. It avoids bundling the existing source-tree update script into the app, which would require git, Swift toolchains, and repository paths on end-user machines.

## User Experience

The About settings page shows the current version and an Updates section. Users can click "Check for Updates"; the app displays checking, up-to-date, update-available, and failure states. When an update is available, the primary action opens the GitHub release page so the user can download the DMG.

## Components

- `UpdateCore`: small testable SwiftPM target for version comparison and GitHub release JSON decoding.
- `InAppUpdateChecker`: app-side observable object that fetches the latest release and exposes UI state.
- `SettingsAboutSection`: existing settings view that owns the checker and renders the manual update controls.

## Data Flow

1. User clicks the update button in Settings → About.
2. `InAppUpdateChecker` requests `https://api.github.com/repos/zqxsober/vibe-beeper/releases/latest`.
3. The response decodes into `GitHubRelease`.
4. `AppVersion` compares the remote tag with `CFBundleShortVersionString`.
5. The UI either reports up-to-date, reports an available update, opens the release page, or shows a retryable error.

## Error Handling

Network failures, non-2xx responses, and malformed release payloads are converted into short user-facing messages. The feature never auto-installs, never mutates `/Applications`, and never terminates the app.

## Testing

Add tests for semantic version comparison, GitHub release decoding, and source-level integration checks for the About UI and update endpoint. This matches the repo's current executable-target testing constraints while keeping core logic importable.

