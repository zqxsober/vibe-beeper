# Old School Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `old school` theme that preserves all existing vibe-beeper behavior while rendering the main widget and theme settings area in the approved retro Macintosh-inspired style.

**Architecture:** Keep existing themes on their current `ContentView` and `CompactView` paths. Add an isolated old-school rendering path with dedicated SwiftUI chrome, large/compact views, and a theme-specific size setting that only affects `old-school + Large`. Centralize window-size calculation in `ThemeManager` so app launch, menu size changes, and settings changes all use the same rules.

**Tech Stack:** Swift 6 package, SwiftUI, AppKit window sizing, UserDefaults via `@Published` / `@AppStorage`, XCTest source-level regression tests.

---

## File Structure

- Modify `Sources/Theme/ThemeManager.swift`
  - Add `old-school` theme entry.
  - Add `OldSchoolDisplaySize`.
  - Add `oldSchoolDisplaySize`, `isOldSchoolTheme`, and theme-aware window sizing.
- Modify `Sources/App/CCBeeperApp.swift`
  - Route old-school `Large` to `OldSchoolLargeView`.
  - Route old-school `Compact` to `OldSchoolCompactView`.
  - Use theme-aware window sizes in launch, onboarding completion, menu size changes, wake, and theme/old-school-size changes.
- Create `Sources/Widget/OldSchoolChrome.swift`
  - Shared palette, body shell, LCD panel, rainbow badge, drive slot, LED, and key button controls.
- Create `Sources/Widget/OldSchoolLargeView.swift`
  - Large old-school full machine layout with existing actions wired through `ClaudeMonitor`.
- Create `Sources/Widget/OldSchoolCompactView.swift`
  - Compact old-school machine layout without control buttons.
- Modify `Sources/Settings/SettingsGeneralSection.swift`
  - Show an old-school preview when selected.
  - Show `Old School Size` segmented picker only when current theme is old-school.
- Modify `Sources/Onboarding/OnboardingThemeStep.swift`
  - Render a nonblank old-school preview if the new theme appears during onboarding.
- Modify `Sources/Onboarding/OnboardingSizesStep.swift`
  - Render a nonblank old-school size preview if selected during onboarding.
- Create `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`
  - Source-level regression tests for theme registration, sizing, routing, settings picker, and onboarding preview branches.

This plan intentionally contains no `git commit` step because the user explicitly forbids automatic commits and pushes.

---

### Task 1: Add Failing Regression Tests

**Files:**
- Create: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Create tests for old-school theme contract**

Add this file:

```swift
import XCTest
import Foundation

final class OldSchoolThemeXCTests: XCTestCase {
    func testThemeManagerRegistersOldSchoolThemeAndSizes() throws {
        let source = try String(contentsOfFile: themeManagerPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("ShellTheme(id: \"old-school\""))
        XCTAssertTrue(source.contains("displayName: \"Old School\""))
        XCTAssertTrue(source.contains("enum OldSchoolDisplaySize"))
        XCTAssertTrue(source.contains("case small"))
        XCTAssertTrue(source.contains("case medium"))
        XCTAssertTrue(source.contains("case large"))
        XCTAssertTrue(source.contains("case showcase"))
        XCTAssertTrue(source.contains("oldSchoolDisplaySize"))
        XCTAssertTrue(source.contains("\"oldSchoolDisplaySize\""))
        XCTAssertTrue(source.contains("var isOldSchoolTheme: Bool"))
    }

    func testThemeManagerDefinesThemeAwareWindowSizes() throws {
        let source = try String(contentsOfFile: themeManagerPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("NSSize(width: 360, height: 270)"))
        XCTAssertTrue(source.contains("NSSize(width: 420, height: 320)"))
        XCTAssertTrue(source.contains("NSSize(width: 500, height: 380)"))
        XCTAssertTrue(source.contains("NSSize(width: 580, height: 440)"))
        XCTAssertTrue(source.contains("NSSize(width: 310, height: 200)"))
        XCTAssertTrue(source.contains("mainWindowSize(for widgetSize: WidgetSize)"))
    }

    func testAppRoutesOldSchoolToDedicatedViewsAndThemeAwareSizing() throws {
        let source = try String(contentsOfFile: appPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("OldSchoolLargeView()"))
        XCTAssertTrue(source.contains("OldSchoolCompactView()"))
        XCTAssertTrue(source.contains("themeManager.mainWindowSize(for:"))
        XCTAssertFalse(source.contains("monitor.widgetSize == .compact\n                            ? NSSize(width: 300, height: 193)\n                            : NSSize(width: 440, height: 240)"))
    }

    func testOldSchoolViewsWireExistingActions() throws {
        let largeSource = try String(contentsOfFile: oldSchoolLargeViewPath(), encoding: .utf8)
        let chromeSource = try String(contentsOfFile: oldSchoolChromePath(), encoding: .utf8)

        XCTAssertTrue(largeSource.contains("monitor.respondToPermission(allow: true)"))
        XCTAssertTrue(largeSource.contains("monitor.respondToPermission(allow: false)"))
        XCTAssertTrue(largeSource.contains("monitor.voiceService.toggle()"))
        XCTAssertTrue(largeSource.contains("monitor.ttsService.stopSpeaking()"))
        XCTAssertTrue(largeSource.contains("monitor.goToConversation()"))
        XCTAssertTrue(chromeSource.contains("OldSchoolControls"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton"))
    }

    func testSettingsShowsOldSchoolSizePickerOnlyForOldSchool() throws {
        let source = try String(contentsOfFile: settingsGeneralSectionPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("themeManager.isOldSchoolTheme"))
        XCTAssertTrue(source.contains("Old School Size"))
        XCTAssertTrue(source.contains("$themeManager.oldSchoolDisplaySize"))
        XCTAssertTrue(source.contains("OldSchoolSettingsPreview"))
    }

    func testOnboardingHasOldSchoolPreviewBranches() throws {
        let themeSource = try String(contentsOfFile: onboardingThemeStepPath(), encoding: .utf8)
        let sizesSource = try String(contentsOfFile: onboardingSizesStepPath(), encoding: .utf8)

        XCTAssertTrue(themeSource.contains("theme.id == \"old-school\""))
        XCTAssertTrue(themeSource.contains("OldSchoolOnboardingPreview"))
        XCTAssertTrue(sizesSource.contains("themeId == \"old-school\""))
        XCTAssertTrue(sizesSource.contains("OldSchoolSizePreview"))
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func themeManagerPath() -> String {
        projectRoot() + "/Sources/Theme/ThemeManager.swift"
    }

    private func appPath() -> String {
        projectRoot() + "/Sources/App/CCBeeperApp.swift"
    }

    private func oldSchoolChromePath() -> String {
        projectRoot() + "/Sources/Widget/OldSchoolChrome.swift"
    }

    private func oldSchoolLargeViewPath() -> String {
        projectRoot() + "/Sources/Widget/OldSchoolLargeView.swift"
    }

    private func settingsGeneralSectionPath() -> String {
        projectRoot() + "/Sources/Settings/SettingsGeneralSection.swift"
    }

    private func onboardingThemeStepPath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingThemeStep.swift"
    }

    private func onboardingSizesStepPath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingSizesStep.swift"
    }
}
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run:

```bash
swift test --filter OldSchoolThemeXCTests
```

Expected: FAIL because `OldSchoolChrome.swift`, `OldSchoolLargeView.swift`, and old-school theme wiring do not exist yet.

---

### Task 2: Add Theme Model And Window Size Contract

**Files:**
- Modify: `Sources/Theme/ThemeManager.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Update imports**

At the top of `Sources/Theme/ThemeManager.swift`, change imports to:

```swift
import SwiftUI
import AppKit
```

- [ ] **Step 2: Add `OldSchoolDisplaySize` below `ShellTheme`**

Insert after `ShellTheme`:

```swift
enum OldSchoolDisplaySize: String, CaseIterable, Identifiable, Equatable {
    case small
    case medium
    case large
    case showcase

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .showcase: return "Showcase"
        }
    }

    var windowSize: NSSize {
        switch self {
        case .small: return NSSize(width: 360, height: 270)
        case .medium: return NSSize(width: 420, height: 320)
        case .large: return NSSize(width: 500, height: 380)
        case .showcase: return NSSize(width: 580, height: 440)
        }
    }
}
```

- [ ] **Step 3: Add the theme entry**

Add this item at the end of `ThemeManager.themes`, after `apple`:

```swift
ShellTheme(id: "old-school", name: "Old School", displayName: "Old School", shellImage: "vibe-beeper-apple.png", dotColor: "ECE7D5"),
```

The `shellImage` intentionally points to an existing safe fallback asset. Actual old-school rendering uses SwiftUI views; this fallback prevents image-loading callers from returning a blank image before their explicit old-school branch runs.

- [ ] **Step 4: Add old-school storage and published setting**

Inside `ThemeManager`, add:

```swift
private static let oldSchoolDisplaySizeKey = "oldSchoolDisplaySize"

@Published var oldSchoolDisplaySize: OldSchoolDisplaySize {
    didSet {
        UserDefaults.standard.set(oldSchoolDisplaySize.rawValue, forKey: Self.oldSchoolDisplaySizeKey)
    }
}
```

Update `init()` to initialize it:

```swift
init() {
    currentThemeId = UserDefaults.standard.string(forKey: "themeId") ?? "black"
    oldSchoolDisplaySize = OldSchoolDisplaySize(
        rawValue: UserDefaults.standard.string(forKey: Self.oldSchoolDisplaySizeKey) ?? ""
    ) ?? .medium
}
```

- [ ] **Step 5: Add theme helpers and window sizing**

Replace the existing `smallShellImageName`, `isAppleTheme`, and `lcdOn` area with:

```swift
var shellImageName: String { theme.shellImage }

var smallShellImageName: String {
    isOldSchoolTheme ? "vibe-beeper-small-apple.png" : "vibe-beeper-small-\(currentThemeId).png"
}

var isAppleTheme: Bool { currentThemeId == "apple" }
var isOldSchoolTheme: Bool { currentThemeId == "old-school" }

func mainWindowSize(for widgetSize: WidgetSize) -> NSSize {
    switch widgetSize {
    case .large:
        return isOldSchoolTheme ? oldSchoolDisplaySize.windowSize : NSSize(width: 440, height: 240)
    case .compact:
        return isOldSchoolTheme ? NSSize(width: 310, height: 200) : NSSize(width: 300, height: 193)
    case .menuOnly:
        return NSSize(width: 1, height: 1)
    }
}

// MARK: - LCD Colors (dark mode support)

var lcdBg: Color { Color(hex: "98D65A") }
var lcdOn: Color { (isAppleTheme || isOldSchoolTheme) ? Color(hex: "2F3A29") : Color(hex: "2A4A10") }
```

- [ ] **Step 6: Run focused tests**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testThemeManagerRegistersOldSchoolThemeAndSizes
swift test --filter OldSchoolThemeXCTests/testThemeManagerDefinesThemeAwareWindowSizes
```

Expected: both tests PASS. Other old-school tests still fail because views, settings, and app routing are not implemented yet.

---

### Task 3: Route App Window To Old-School Views

**Files:**
- Modify: `Sources/App/CCBeeperApp.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Replace the main window content group**

In the `Window("vibe-beeper", id: "main")` scene, replace the current Group-based content selection with:

```swift
mainWidgetContent
    .environmentObject(monitor)
    .environmentObject(themeManager)
    .background(WindowConfigurator())
```

Add this computed property inside `CCBeeperApp`:

```swift
@ViewBuilder
private var mainWidgetContent: some View {
    if monitor.widgetSize == .compact {
        if themeManager.isOldSchoolTheme {
            OldSchoolCompactView()
        } else {
            CompactView()
        }
    } else {
        if themeManager.isOldSchoolTheme {
            OldSchoolLargeView()
        } else {
            ContentView()
        }
    }
}
```

- [ ] **Step 2: Add a resize helper**

Add this instance helper inside `CCBeeperApp`:

```swift
private func resizeVisibleMainWindow() {
    guard monitor.widgetSize != .menuOnly else {
        Self.hideMainWindow()
        return
    }
    Self.resizeMainWindow(to: themeManager.mainWindowSize(for: monitor.widgetSize))
}
```

- [ ] **Step 3: Replace hard-coded large/compact sizes**

Replace every hard-coded branch like this:

```swift
let size = monitor.widgetSize == .compact
    ? NSSize(width: 300, height: 193)
    : NSSize(width: 440, height: 240)
Self.resizeMainWindow(to: size)
```

with:

```swift
Self.resizeMainWindow(to: themeManager.mainWindowSize(for: monitor.widgetSize))
```

In the menu `Size` handler, replace the `.large` and `.compact` cases with:

```swift
case .large, .compact:
    Self.showMainWindow()
    Self.resizeMainWindow(to: themeManager.mainWindowSize(for: size))
case .menuOnly:
    Self.hideMainWindow()
```

- [ ] **Step 4: Resize when theme or old-school size changes**

Add these `onChange` handlers to the main window chain after existing state handlers:

```swift
.onChange(of: themeManager.currentThemeId) { _, _ in
    guard hasCompletedOnboarding, monitor.isActive else { return }
    resizeVisibleMainWindow()
}
.onChange(of: themeManager.oldSchoolDisplaySize) { _, _ in
    guard hasCompletedOnboarding, monitor.isActive, themeManager.isOldSchoolTheme else { return }
    resizeVisibleMainWindow()
}
```

- [ ] **Step 5: Run routing test**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testAppRoutesOldSchoolToDedicatedViewsAndThemeAwareSizing
```

Expected: FAIL only because `OldSchoolLargeView` and `OldSchoolCompactView` are not created yet, or PASS if placeholder types were added by the compiler in a later task. Continue to Task 4.

---

### Task 4: Create Shared Old-School Chrome

**Files:**
- Create: `Sources/Widget/OldSchoolChrome.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Add shared chrome components**

Create `Sources/Widget/OldSchoolChrome.swift` with this implementation:

```swift
import SwiftUI

enum OldSchoolPalette {
    static let plasticTop = Color(hex: "F1E8D0")
    static let plasticMid = Color(hex: "D8CDB0")
    static let plasticBottom = Color(hex: "BFB394")
    static let plasticStroke = Color(hex: "9E947C")
    static let lcd = Color(hex: "B5BFA3")
    static let lcdDark = Color(hex: "1F2A1B")
    static let lcdOn = Color(hex: "2F3A29")
    static let shadow = Color.black.opacity(0.24)
}

struct OldSchoolLCDHeader: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "apple.logo")
                .font(.system(size: 9, weight: .black))
            Text("VIBE-BEEPER")
                .font(.system(size: 9, weight: .black, design: .monospaced))
            Spacer(minLength: 0)
        }
        .foregroundStyle(OldSchoolPalette.lcdDark)
        .padding(.horizontal, 7)
        .allowsHitTesting(false)
    }
}

struct OldSchoolLCDPanel<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius + 5, style: .continuous)
                .fill(OldSchoolPalette.lcdDark)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(OldSchoolPalette.lcd)
                .padding(5)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(OldSchoolPalette.lcdDark.opacity(0.65), lineWidth: 1)
                        .padding(5)
                )
            content()
                .padding(5)
        }
    }
}

struct OldSchoolDriveSlot: View {
    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: "1E1B15"))
                .frame(height: 9)
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: "F6ECD2"))
                .frame(width: 68, height: 3)
                .offset(x: -34)
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: "12100D"))
                .frame(width: 17, height: 6)
                .padding(.trailing, 4)
        }
        .frame(width: 96, height: 12)
    }
}

struct OldSchoolRainbowBadge: View {
    private let colors = ["5EB24F", "F4D34D", "F08B31", "E94648", "8E67B5", "5B7DDB"]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(colors, id: \.self) { hex in
                Rectangle().fill(Color(hex: hex))
            }
        }
        .frame(width: 22, height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 1, x: 0, y: 1)
    }
}

struct OldSchoolLED: View {
    let color: Color
    let active: Bool

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 5, height: 5)
            .opacity(active ? 1 : 0.7)
            .shadow(color: color.opacity(active ? 0.7 : 0), radius: active ? 4 : 0)
    }
}

struct OldSchoolControls: View {
    let permissionActive: Bool
    let isRecording: Bool
    let isSpeaking: Bool
    let onAccept: () -> Void
    let onDeny: () -> Void
    let onRecord: () -> Void
    let onStopSpeaking: () -> Void
    let onTerminal: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            OldSchoolKeyButton(symbol: "checkmark", isEnabled: permissionActive, action: onAccept)
                .help("Accept")
            OldSchoolKeyButton(symbol: "xmark", isEnabled: permissionActive, action: onDeny)
                .help("Deny")
            OldSchoolKeyButton(symbol: isRecording ? "stop.fill" : "mic.fill", isEnabled: true, action: onRecord)
                .help(isRecording ? "Stop recording" : "Record")
            OldSchoolKeyButton(symbol: "speaker.wave.2.fill", isEnabled: isSpeaking, action: onStopSpeaking)
                .help("Stop speaking")
            OldSchoolKeyButton(symbol: "terminal.fill", isEnabled: true, action: onTerminal)
                .help("Go to terminal")
        }
    }
}

struct OldSchoolKeyButton: View {
    let symbol: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(isEnabled ? Color(hex: "1F1D16") : Color(hex: "8C8779"))
                .frame(width: 34, height: 30)
        }
        .buttonStyle(OldSchoolKeyButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
    }
}

struct OldSchoolKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [Color(hex: "B9AE93"), Color(hex: "DED4B9")]
                        : [Color(hex: "F7EED6"), Color(hex: "CFC3A4")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(OldSchoolPalette.plasticStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.24), radius: 2, x: 0, y: configuration.isPressed ? 0 : 2)
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}
```

- [ ] **Step 2: Run the action-wiring test**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testOldSchoolViewsWireExistingActions
```

Expected: FAIL because `OldSchoolLargeView.swift` is still missing.

---

### Task 5: Create Old-School Large View

**Files:**
- Create: `Sources/Widget/OldSchoolLargeView.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Add large old-school view**

Create `Sources/Widget/OldSchoolLargeView.swift` with this implementation:

```swift
import SwiftUI
import AppKit

struct OldSchoolLargeView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let buzzService = BuzzService()

    var body: some View {
        let size = themeManager.oldSchoolDisplaySize.windowSize
        let scale = min(size.width / 420, size.height / 320)

        ZStack(alignment: .topLeading) {
            oldSchoolBody(size: size)

            VStack(alignment: .leading, spacing: 0) {
                OldSchoolLCDHeader()
                    .frame(height: 18 * scale)
                OldSchoolLCDPanel(cornerRadius: 6 * scale) {
                    ScreenView()
                        .frame(width: 278 * scale, height: 58 * scale)
                        .clipped()
                        .allowsHitTesting(false)
                }
                .frame(width: 304 * scale, height: 84 * scale)
            }
            .offset(x: 58 * scale, y: 44 * scale)

            OldSchoolRainbowBadge()
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: 62 * scale, y: 184 * scale)

            OldSchoolDriveSlot()
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: 250 * scale, y: 190 * scale)

            OldSchoolLED(color: driveLEDColor, active: ledAlertActive && ledPulse)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: 356 * scale, y: 194 * scale)

            OldSchoolControls(
                permissionActive: monitor.state.needsAttention,
                isRecording: monitor.isRecording,
                isSpeaking: monitor.ttsService.isSpeaking,
                onAccept: { monitor.respondToPermission(allow: true) },
                onDeny: { monitor.respondToPermission(allow: false) },
                onRecord: { monitor.voiceService.toggle() },
                onStopSpeaking: {
                    if monitor.ttsService.isSpeaking {
                        monitor.ttsService.stopSpeaking()
                    }
                },
                onTerminal: { monitor.goToConversation() }
            )
            .scaleEffect(scale, anchor: .topLeading)
            .offset(x: 106 * scale, y: 254 * scale)
        }
        .frame(width: size.width, height: size.height)
        .background(Color.clear)
        .onTapGesture {
            if buzzService.isVibrating {
                buzzService.cancelVibration()
            }
        }
        .contextMenu {
            Button("Quit vibe-beeper") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(monitor.$state) { newState in
            handleStateChange(newState)
        }
        .onReceive(ledTimer) { _ in
            if monitor.state.needsAttention || monitor.state == .working {
                ledPulse.toggle()
            }
        }
    }

    private func oldSchoolBody(size: NSSize) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OldSchoolPalette.shadow)
                .offset(y: 7)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [OldSchoolPalette.plasticTop, OldSchoolPalette.plasticMid, OldSchoolPalette.plasticBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(hex: "D4C8AA"))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(OldSchoolPalette.plasticStroke.opacity(0.65), lineWidth: 1)
                )
                .frame(width: size.width * 0.78, height: size.height * 0.42)
                .offset(x: size.width * 0.11, y: size.height * 0.08)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "D6CAA9"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "AFA383"), lineWidth: 1)
                )
                .frame(width: size.width * 0.9, height: size.height * 0.18)
                .offset(x: size.width * 0.05, y: size.height * 0.76)
        }
    }

    private func handleStateChange(_ newState: ClaudeState) {
        if !(newState.needsAttention || newState == .working) {
            ledPulse = false
        }
        buzzService.handleStateChange(newState, vibrationEnabled: monitor.vibrationEnabled, soundEnabled: monitor.soundEnabled && !monitor.isMuted)
    }

    private var ledAlertActive: Bool {
        monitor.state == .working || monitor.state.needsAttention
    }

    private var driveLEDColor: Color {
        if ledAlertActive {
            return AppConstants.ledAmber
        }
        if monitor.state == .done {
            return AppConstants.ledGreen
        }
        return Color(hex: "D64A3A")
    }
}

#Preview {
    OldSchoolLargeView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
```

- [ ] **Step 2: Run action-wiring test**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testOldSchoolViewsWireExistingActions
```

Expected: PASS.

---

### Task 6: Create Old-School Compact View

**Files:**
- Create: `Sources/Widget/OldSchoolCompactView.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Add compact old-school view**

Create `Sources/Widget/OldSchoolCompactView.swift` with this implementation:

```swift
import SwiftUI
import AppKit

struct OldSchoolCompactView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private let shellW: CGFloat = 310
    private let shellH: CGFloat = 200

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OldSchoolPalette.shadow)
                .offset(y: 6)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [OldSchoolPalette.plasticTop, OldSchoolPalette.plasticMid, OldSchoolPalette.plasticBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 0) {
                OldSchoolLCDHeader()
                    .frame(height: 14)
                OldSchoolLCDPanel(cornerRadius: 5) {
                    ScreenView(compact: true)
                        .frame(width: 212, height: 48)
                        .clipped()
                        .allowsHitTesting(false)
                }
                .frame(width: 234, height: 70)
            }
            .offset(x: 38, y: 42)

            OldSchoolRainbowBadge()
                .offset(x: 44, y: 132)

            OldSchoolDriveSlot()
                .scaleEffect(0.72, anchor: .topLeading)
                .offset(x: 184, y: 136)

            OldSchoolLED(color: driveLEDColor, active: ledAlertActive && ledPulse)
                .offset(x: 258, y: 139)
        }
        .frame(width: shellW, height: shellH)
        .background(Color.clear)
        .contextMenu {
            Button("Quit vibe-beeper") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(ledTimer) { _ in
            if monitor.state.needsAttention || monitor.state == .working {
                ledPulse.toggle()
            }
        }
        .onChange(of: monitor.state) { _, newState in
            if !(newState.needsAttention || newState == .working) {
                ledPulse = false
            }
        }
    }

    private var ledAlertActive: Bool {
        monitor.state == .working || monitor.state.needsAttention
    }

    private var driveLEDColor: Color {
        if ledAlertActive {
            return AppConstants.ledAmber
        }
        if monitor.state == .done {
            return AppConstants.ledGreen
        }
        return Color(hex: "D64A3A")
    }
}

#Preview {
    OldSchoolCompactView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
```

- [ ] **Step 2: Run app routing test**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testAppRoutesOldSchoolToDedicatedViewsAndThemeAwareSizing
```

Expected: PASS.

---

### Task 7: Add Settings Preview And Size Picker

**Files:**
- Modify: `Sources/Settings/SettingsGeneralSection.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`
- Test: `Tests/CC-BeeperTests/SettingsThemeLayoutTests.swift`

- [ ] **Step 1: Branch the preview row**

In `SettingsThemeSection`, replace the current preview `Image` with:

```swift
Group {
    if themeManager.isOldSchoolTheme {
        OldSchoolSettingsPreview()
            .frame(width: 132, height: 86)
    } else {
        Image(nsImage: loadShellPreview(themeManager.smallShellImageName))
            .resizable()
            .interpolation(.high)
            .frame(width: 132, height: 68)
    }
}
.padding(8)
.background(Color(.controlBackgroundColor))
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
```

- [ ] **Step 2: Update theme subtitle**

Replace the subtitle expression with:

```swift
Text(themeSubtitle)
    .font(.caption)
    .foregroundStyle(.secondary)
```

Add this computed property inside `SettingsThemeSection`:

```swift
private var themeSubtitle: String {
    if themeManager.isOldSchoolTheme {
        return "retro Mac shell"
    }
    return themeManager.isAppleTheme ? "Classic Mac shell" : "Original color shell"
}
```

- [ ] **Step 3: Add old-school size segmented picker**

Below `ThemeDotsRow()`, add:

```swift
if themeManager.isOldSchoolTheme {
    VStack(alignment: .leading, spacing: 6) {
        Text("Old School Size")
            .font(.caption)
            .foregroundStyle(.secondary)
        Picker("Old School Size", selection: $themeManager.oldSchoolDisplaySize) {
            ForEach(OldSchoolDisplaySize.allCases) { size in
                Text(size.label).tag(size)
            }
        }
        .pickerStyle(.segmented)
    }
}
```

- [ ] **Step 4: Add settings preview component**

Add this private component at the bottom of `SettingsGeneralSection.swift`:

```swift
private struct OldSchoolSettingsPreview: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [OldSchoolPalette.plasticTop, OldSchoolPalette.plasticMid, OldSchoolPalette.plasticBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(OldSchoolPalette.plasticStroke.opacity(0.7), lineWidth: 1)
                )

            OldSchoolLCDPanel(cornerRadius: 3) {
                HStack(spacing: 4) {
                    PixelCharacterView(state: .idle, frame: 0, onColor: OldSchoolPalette.lcdOn)
                        .frame(width: 20, height: 18)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("摸鱼中")
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        Text("省电模式")
                            .font(.system(size: 5, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(OldSchoolPalette.lcdOn)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 6)
            }
            .frame(width: 100, height: 38)
            .offset(x: 16, y: 16)

            OldSchoolRainbowBadge()
                .scaleEffect(0.55, anchor: .topLeading)
                .offset(x: 18, y: 62)

            OldSchoolDriveSlot()
                .scaleEffect(0.45, anchor: .topLeading)
                .offset(x: 74, y: 65)
        }
    }
}
```

- [ ] **Step 5: Run settings tests**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testSettingsShowsOldSchoolSizePickerOnlyForOldSchool
swift test --filter SettingsThemeLayoutXCTests
```

Expected: both commands PASS.

---

### Task 8: Keep Onboarding Previews Nonblank

**Files:**
- Modify: `Sources/Onboarding/OnboardingThemeStep.swift`
- Modify: `Sources/Onboarding/OnboardingSizesStep.swift`
- Test: `Tests/CC-BeeperTests/OldSchoolThemeTests.swift`

- [ ] **Step 1: Add old-school branch to large onboarding preview**

In `LargeShellPreview.body`, before the `if let img = loadImage(theme.shellImage)` branch, add:

```swift
if theme.id == "old-school" {
    OldSchoolOnboardingPreview(compact: false)
        .frame(width: shellW, height: shellH)
} else if let img = loadImage(theme.shellImage) {
    Image(nsImage: img)
        .resizable()
        .interpolation(.high)
        .frame(width: shellW, height: shellH)
}
```

Keep the existing Apple/non-Apple overlays inside `if theme.id != "old-school"` so old-school does not receive old beeper LEDs or button overlays.

- [ ] **Step 2: Add old-school branch to compact onboarding preview**

In `CompactShellPreview.body`, before the small image loading branch, add:

```swift
if theme.id == "old-school" {
    OldSchoolOnboardingPreview(compact: true)
        .frame(width: shellW, height: shellH)
} else if let img = loadImage("vibe-beeper-small-\(theme.id).png") {
    Image(nsImage: img)
        .resizable()
        .interpolation(.high)
        .frame(width: shellW, height: shellH)
}
```

Keep existing Apple/non-Apple overlays inside `if theme.id != "old-school"`.

- [ ] **Step 3: Add reusable onboarding preview component**

Add this component near the other preview components in `OnboardingThemeStep.swift`:

```swift
private struct OldSchoolOnboardingPreview: View {
    let compact: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [OldSchoolPalette.plasticTop, OldSchoolPalette.plasticMid, OldSchoolPalette.plasticBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                        .stroke(OldSchoolPalette.plasticStroke.opacity(0.7), lineWidth: 1)
                )

            OldSchoolLCDPanel(cornerRadius: compact ? 3 : 4) {
                PixelCharacterView(state: .idle, frame: 0, onColor: OldSchoolPalette.lcdOn)
                    .frame(width: compact ? 20 : 28, height: compact ? 18 : 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, compact ? 8 : 14)
            }
            .frame(width: compact ? 110 : 188, height: compact ? 32 : 46)
            .offset(x: compact ? 24 : 42, y: compact ? 24 : 28)

            OldSchoolRainbowBadge()
                .scaleEffect(compact ? 0.45 : 0.65, anchor: .topLeading)
                .offset(x: compact ? 28 : 46, y: compact ? 62 : 88)

            OldSchoolDriveSlot()
                .scaleEffect(compact ? 0.38 : 0.52, anchor: .topLeading)
                .offset(x: compact ? 96 : 170, y: compact ? 64 : 92)
        }
    }
}
```

- [ ] **Step 4: Add old-school branch to size step large card**

In `OnboardingSizesStep`, replace the large preview image block with:

```swift
if themeId == "old-school" {
    OldSchoolSizePreview(compact: false)
        .frame(width: 183, height: 80)
} else if let img = loadSizeImage(theme.shellImage) {
    Image(nsImage: img)
        .resizable()
        .interpolation(.high)
        .frame(width: 183, height: 80)
}
```

Only show `OnboardingButtonRow` when `theme.id != "apple" && theme.id != "old-school"`.

- [ ] **Step 5: Add old-school branch to size step compact card**

Replace the compact preview block with:

```swift
if themeId == "old-school" {
    OldSchoolSizePreview(compact: true)
        .frame(width: 110, height: 57)
} else if let img = loadSizeImage("vibe-beeper-small-\(themeId).png") {
    Image(nsImage: img)
        .resizable()
        .interpolation(.high)
        .frame(width: 110, height: 57)
}
```

- [ ] **Step 6: Add size preview component**

Add this component at the bottom of `OnboardingSizesStep.swift`:

```swift
private struct OldSchoolSizePreview: View {
    let compact: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: compact ? 6 : 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [OldSchoolPalette.plasticTop, OldSchoolPalette.plasticMid, OldSchoolPalette.plasticBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 6 : 8, style: .continuous)
                        .stroke(OldSchoolPalette.plasticStroke.opacity(0.65), lineWidth: 1)
                )

            OldSchoolLCDPanel(cornerRadius: 3) {
                PixelCharacterView(state: .idle, frame: 0, onColor: OldSchoolPalette.lcdOn)
                    .frame(width: compact ? 16 : 22, height: compact ? 14 : 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, compact ? 6 : 10)
            }
            .frame(width: compact ? 78 : 132, height: compact ? 24 : 36)
            .offset(x: compact ? 16 : 26, y: compact ? 14 : 16)

            OldSchoolDriveSlot()
                .scaleEffect(compact ? 0.28 : 0.38, anchor: .topLeading)
                .offset(x: compact ? 64 : 112, y: compact ? 43 : 58)
        }
    }
}
```

- [ ] **Step 7: Run onboarding branch test**

Run:

```bash
swift test --filter OldSchoolThemeXCTests/testOnboardingHasOldSchoolPreviewBranches
```

Expected: PASS.

---

### Task 9: Compile And Fix SwiftUI Integration Issues

**Files:**
- Modify only files touched in Tasks 2-8 if compilation reveals type or layout errors.

- [ ] **Step 1: Build tests**

Run:

```bash
swift test --filter OldSchoolThemeXCTests
```

Expected: PASS.

- [ ] **Step 2: Run related existing tests**

Run:

```bash
swift test --filter SettingsThemeLayoutXCTests
swift test --filter ShellAssetReferenceXCTests
swift test --filter WidgetBrandingXCTests
```

Expected: PASS.

- [ ] **Step 3: Run a full Swift test pass if focused tests are clean**

Run:

```bash
swift test
```

Expected: PASS. If unrelated tests fail because of environment or external model dependencies, record the exact failing test names and error output before continuing.

---

### Task 10: Visual Runtime Verification

**Files:**
- No planned source edits. If visual QA reveals overlap, adjust only `OldSchoolChrome.swift`, `OldSchoolLargeView.swift`, `OldSchoolCompactView.swift`, or `SettingsGeneralSection.swift`.

- [ ] **Step 1: Run the app in debug mode**

Run:

```bash
swift run vibe-beeper
```

Expected: app starts without a crash. If another instance is running, quit the running app and rerun the command.

- [ ] **Step 2: Verify settings behavior**

Open Settings from the menu bar and confirm:

```text
Theme tab shows Old School as a selectable theme.
Old School selected shows the retro preview.
Old School Size appears only for Old School.
Small / Medium / Large / Showcase can be selected.
Switching away from Old School hides Old School Size.
Switching back restores the last selected Old School Size.
```

- [ ] **Step 3: Verify main widget behavior**

In the menu bar, check:

```text
Old School + Large + Small     uses a smaller full-machine window.
Old School + Large + Medium    uses the default full-machine window.
Old School + Large + Large     uses the larger full-machine window.
Old School + Large + Showcase  uses the largest full-machine window.
Old School + Compact           uses the fixed compact retro window.
Menu only                      hides the main window.
Old non-old-school themes      still use the original Large and Compact sizes.
```

- [ ] **Step 4: Verify controls**

Exercise available controls:

```text
Permission pending state enables checkmark and X keys.
Checkmark accepts permission.
X denies permission.
Microphone key toggles dictation.
Speaker key stops active read-over speech.
Terminal key focuses the active conversation.
LED pulses during working or permission-attention states.
```

Expected: behavior matches old theme behavior; only appearance differs.

---

## Self-Review Checklist

- Spec coverage:
  - Theme registration: Task 2.
  - Old-school size model and persistence: Task 2.
  - Theme-aware app routing and window resizing: Task 3.
  - Retro large/compact visuals: Tasks 4-6.
  - Settings preview and segmented size picker: Task 7.
  - Existing behavior preservation: Tasks 5, 6, 9, 10.
  - Onboarding nonblank preview guard: Task 8.
- Placeholder scan:
  - No placeholder markers or open-ended test instructions are intentionally present.
- Type consistency:
  - `OldSchoolDisplaySize`, `oldSchoolDisplaySize`, `isOldSchoolTheme`, and `mainWindowSize(for:)` are introduced in Task 2 and used by later tasks.
  - `OldSchoolLargeView`, `OldSchoolCompactView`, `OldSchoolControls`, and `OldSchoolKeyButton` names are consistent across tests and source tasks.
