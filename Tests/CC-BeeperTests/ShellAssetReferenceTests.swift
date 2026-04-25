import XCTest
import Foundation

final class ShellAssetReferenceXCTests: XCTestCase {
    func testThemeManagerUsesVibeShellAssets() throws {
        let source = try String(contentsOfFile: themeManagerPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("vibe-beeper-black.png"))
        XCTAssertTrue(source.contains("var smallShellImageName: String { \"vibe-beeper-small-\\(currentThemeId).png\" }"))
        XCTAssertFalse(source.contains(#""beeper-black.png""#))
        XCTAssertFalse(source.contains("\"beeper-small-\\(currentThemeId).png\""))
    }

    func testOnboardingPreviewsUseVibeShellAssets() throws {
        let themeSource = try String(contentsOfFile: onboardingThemeStepPath(), encoding: .utf8)
        XCTAssertTrue(themeSource.contains("\"vibe-beeper-small-\\(theme.id).png\""))
        XCTAssertFalse(themeSource.contains("\"beeper-small-\\(theme.id).png\""))

        let sizeSource = try String(contentsOfFile: onboardingSizesStepPath(), encoding: .utf8)
        XCTAssertTrue(sizeSource.contains("\"vibe-beeper-small-\\(themeId).png\""))
        XCTAssertFalse(sizeSource.contains("\"beeper-small-\\(themeId).png\""))
    }

    func testBuildScriptCopiesVibeShellAssets() throws {
        let source = try String(contentsOfFile: buildScriptPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("cp Sources/shells/vibe-beeper-*.png"))
        XCTAssertFalse(source.contains("cp Sources/shells/beeper-*.png"))
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

    private func onboardingThemeStepPath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingThemeStep.swift"
    }

    private func onboardingSizesStepPath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingSizesStep.swift"
    }

    private func buildScriptPath() -> String {
        projectRoot() + "/build.sh"
    }
}
