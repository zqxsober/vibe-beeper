import XCTest
import Foundation

final class OldSchoolThemeXCTests: XCTestCase {
    func testThemeManagerRegistersOldSchoolThemeAndSizes() {
        guard let source = sourceIfExists(themeManagerPath()) else {
            return
        }

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

    func testThemeManagerDefinesThemeAwareWindowSizes() {
        guard let source = sourceIfExists(themeManagerPath()) else {
            return
        }

        XCTAssertTrue(source.contains("NSSize(width: 360, height: 405)"))
        XCTAssertTrue(source.contains("NSSize(width: 420, height: 472)"))
        XCTAssertTrue(source.contains("NSSize(width: 500, height: 562)"))
        XCTAssertTrue(source.contains("NSSize(width: 580, height: 652)"))
        XCTAssertTrue(source.contains("NSSize(width: 310, height: 349)"))
        XCTAssertTrue(source.contains("mainWindowSize(for widgetSize: WidgetSize)"))
    }

    func testAppRoutesOldSchoolToDedicatedViewsAndThemeAwareSizing() {
        guard let source = sourceIfExists(appPath()) else {
            return
        }

        XCTAssertTrue(source.contains(".onChange(of: themeManager.currentThemeId)"))
        XCTAssertTrue(source.contains(".onChange(of: themeManager.oldSchoolDisplaySize)"))
        XCTAssertTrue(source.contains("resizeVisibleMainWindow()"))
        XCTAssertTrue(source.contains("themeManager.mainWindowSize(for: monitor.widgetSize)"))
        XCTAssertTrue(source.contains("themeManager.mainWindowSize(for: size)"))

        guard let mainWidgetContent = sourceBlock(named: "mainWidgetContent", in: source) else {
            return
        }
        XCTAssertTrue(mainWidgetContent.contains("monitor.widgetSize == .compact"))
        XCTAssertTrue(mainWidgetContent.contains("themeManager.isOldSchoolTheme"))
        XCTAssertTrue(mainWidgetContent.contains("OldSchoolCompactView()"))
        XCTAssertTrue(mainWidgetContent.contains("CompactView()"))
        XCTAssertTrue(mainWidgetContent.contains("OldSchoolLargeView()"))
        XCTAssertTrue(mainWidgetContent.contains("ContentView()"))
    }

    func testOldSchoolViewsWireExistingActions() {
        guard let largeSource = sourceIfExists(oldSchoolLargeViewPath()),
              let chromeSource = sourceIfExists(oldSchoolChromePath()) else {
            return
        }

        XCTAssertTrue(largeSource.contains("monitor.respondToPermission(allow: true)"))
        XCTAssertTrue(largeSource.contains("monitor.respondToPermission(allow: false)"))
        XCTAssertTrue(largeSource.contains("monitor.voiceService.toggle()"))
        XCTAssertTrue(largeSource.contains("monitor.ttsService.stopSpeaking()"))
        XCTAssertTrue(largeSource.contains("monitor.goToConversation()"))
        XCTAssertTrue(chromeSource.contains("OldSchoolControls"))
        XCTAssertTrue(chromeSource.contains("OldSchoolControlHitAreas"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton"))
    }

    func testOldSchoolViewsMatchReferenceMacStructure() {
        guard let largeSource = sourceIfExists(oldSchoolLargeViewPath()),
              let compactSource = sourceIfExists(oldSchoolCompactViewPath()),
              let chromeSource = sourceIfExists(oldSchoolChromePath()),
              let settingsSource = sourceIfExists(settingsGeneralSectionPath()) else {
            return
        }

        XCTAssertTrue(largeSource.contains("OldSchoolShellArtwork()"))
        XCTAssertTrue(largeSource.contains("OldSchoolControlHitAreas"))
        XCTAssertTrue(largeSource.contains(".zIndex(1)"))
        XCTAssertFalse(largeSource.contains("OldSchoolRainbowBadge()"))

        XCTAssertTrue(compactSource.contains("OldSchoolShellArtwork()"))
        XCTAssertTrue(compactSource.contains("OldSchoolControlHitAreas"))
        XCTAssertTrue(compactSource.contains(".zIndex(1)"))

        XCTAssertTrue(chromeSource.contains("struct OldSchoolShellArtwork"))
        XCTAssertTrue(chromeSource.contains("struct OldSchoolReferenceScreen"))
        XCTAssertTrue(chromeSource.contains("Image(systemName: \"apple.logo\")"))
        XCTAssertFalse(chromeSource.contains("tree.fill"))

        XCTAssertTrue(settingsSource.contains("OldSchoolPreviewMachine"))
    }

    func testOldSchoolLargeViewUsesReferenceImageProportions() {
        guard let largeSource = sourceIfExists(oldSchoolLargeViewPath()),
              let chromeSource = sourceIfExists(oldSchoolChromePath()) else {
            return
        }

        XCTAssertTrue(largeSource.contains("min(size.width / 1020, size.height / 1147)"))
        XCTAssertTrue(largeSource.contains("OldSchoolShellArtwork()"))
        XCTAssertTrue(largeSource.contains(".frame(width: 736 * scale, height: 462 * scale)"))
        XCTAssertTrue(largeSource.contains(".offset(x: originX + 142 * scale, y: originY + 101 * scale)"))
        XCTAssertTrue(largeSource.contains(".offset(x: originX, y: originY)"))
        XCTAssertTrue(chromeSource.contains("OldSchoolScreenMetrics"))
        XCTAssertTrue(chromeSource.contains(".minimumScaleFactor(0.62)"))
    }

    func testOldSchoolArtworkAssetExistsAndIsBundledByBuildScript() {
        guard let chromeSource = sourceIfExists(oldSchoolChromePath()),
              let buildSource = sourceIfExists(buildScriptPath()) else {
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: projectRoot() + "/Sources/shells/vibe-beeper-old-school-shell.png"))
        XCTAssertTrue(chromeSource.contains("vibe-beeper-old-school-shell.png"))
        XCTAssertTrue(buildSource.contains("cp Sources/shells/vibe-beeper-*.png"))
    }

    func testOldSchoolKeyboardBaseHasLayeredLowerDeckStyling() {
        guard let chromeSource = sourceIfExists(oldSchoolChromePath()) else {
            return
        }

        XCTAssertTrue(chromeSource.contains("KeyboardBaseFrontEdgeShape"))
        XCTAssertTrue(chromeSource.contains("KeyboardBaseTrayShape"))
        XCTAssertTrue(chromeSource.contains("size.height * 0.18"))
        XCTAssertTrue(chromeSource.contains("size.height * 0.56"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyFaceShape"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyShadowShape"))
    }

    func testOldSchoolButtonsUsePixelIconArtworkInsteadOfSystemSymbols() {
        guard let chromeSource = sourceIfExists(oldSchoolChromePath()) else {
            return
        }

        XCTAssertTrue(chromeSource.contains("enum OldSchoolPixelIconKind"))
        XCTAssertTrue(chromeSource.contains("struct OldSchoolPixelIcon"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton(icon: .check"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton(icon: .cross"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton(icon: isRecording ? .stop : .microphone"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton(icon: .speaker"))
        XCTAssertTrue(chromeSource.contains("OldSchoolKeyButton(icon: .terminal"))
        XCTAssertFalse(chromeSource.contains("Image(systemName: symbol)"))
    }

    func testOldSchoolActiveTitleScalesWithEllipsisAsOneTextRun() {
        guard let chromeSource = sourceIfExists(oldSchoolChromePath()) else {
            return
        }

        XCTAssertTrue(chromeSource.contains("Text(displayTitleText)"))
        XCTAssertTrue(chromeSource.contains("private var displayTitleText"))
        XCTAssertTrue(chromeSource.contains("return shouldShowActivityDots ? \"\\(titleText)...\" : titleText"))
        XCTAssertFalse(chromeSource.contains("OldSchoolActivityDotsView(frame:"))
    }

    func testSettingsShowsOldSchoolSizePickerOnlyForOldSchool() {
        guard let source = sourceIfExists(settingsGeneralSectionPath()) else {
            return
        }

        XCTAssertTrue(source.contains("themeManager.isOldSchoolTheme"))
        XCTAssertTrue(source.contains("Old School Size"))
        XCTAssertTrue(source.contains("$themeManager.oldSchoolDisplaySize"))
        XCTAssertTrue(source.contains("OldSchoolSettingsPreview"))
    }

    func testOnboardingHasOldSchoolPreviewBranches() {
        guard let themeSource = sourceIfExists(onboardingThemeStepPath()),
              let sizesSource = sourceIfExists(onboardingSizesStepPath()) else {
            return
        }

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

    private func oldSchoolCompactViewPath() -> String {
        projectRoot() + "/Sources/Widget/OldSchoolCompactView.swift"
    }

    private func settingsGeneralSectionPath() -> String {
        projectRoot() + "/Sources/Settings/SettingsGeneralSection.swift"
    }

    private func buildScriptPath() -> String {
        projectRoot() + "/build.sh"
    }

    private func onboardingThemeStepPath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingThemeStep.swift"
    }

    private func onboardingSizesStepPath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingSizesStep.swift"
    }

    private func sourceIfExists(_ path: String, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard FileManager.default.fileExists(atPath: path) else {
            XCTFail("Expected source file to exist: \(path)", file: file, line: line)
            return nil
        }

        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            XCTFail("Expected source file to be readable: \(path). Error: \(error)", file: file, line: line)
            return nil
        }
    }

    private func sourceBlock(named name: String, in source: String, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard let declarationRange = source.range(of: "private var \(name)"),
              let openingBrace = source[declarationRange.upperBound...].firstIndex(of: "{") else {
            XCTFail("Expected source block to exist: \(name)", file: file, line: line)
            return nil
        }

        var depth = 0
        var index = openingBrace

        while index < source.endIndex {
            let character = source[index]

            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    return String(source[openingBrace...index])
                }
            }

            index = source.index(after: index)
        }

        XCTFail("Expected source block to close: \(name)", file: file, line: line)
        return nil
    }
}
