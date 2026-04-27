import XCTest
import Foundation

/// Regression tests for the optional Chinese runtime copy shown in the app chrome and LCD.
final class WidgetChineseRuntimeCopyXCTests: XCTestCase {
    func testScreenContentKeepsEnglishCopyAsDefault() throws {
        let source = try String(contentsOfFile: screenContentPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("@AppStorage(\"useChineseRuntimeCopy\")"), "LCD copy should be controlled by the shared language preference")
        XCTAssertTrue(source.contains("useChineseRuntimeCopy ? chineseTitleText : englishTitleText"), "English title copy should remain the default path")
        XCTAssertTrue(source.contains("useChineseRuntimeCopy ? chineseDetailText : englishDetailText"), "English detail copy should remain the default path")

        let expectedEnglishTitles = [
            "SNOOZING",
            "WORKING",
            "DONE!",
            "ERROR",
            "ALLOW?",
            "INPUT?",
            "LISTENING",
            "RECAP",
        ]

        for title in expectedEnglishTitles {
            XCTAssertTrue(source.contains("return \"\(title)\""), "LCD English title should still include \(title)")
        }
    }

    func testScreenContentProvidesPlayfulChineseRuntimeCopy() throws {
        let source = try String(contentsOfFile: screenContentPath(), encoding: .utf8)

        let expectedChineseTitles = [
            "摸鱼中",
            "搬砖中",
            "搞定啦",
            "翻车了",
            "等放行",
            "喊你呢",
            "听着呢",
            "开讲啦",
        ]

        for title in expectedChineseTitles {
            XCTAssertTrue(source.contains("return \"\(title)\""), "LCD Chinese title should include playful copy \(title)")
        }

        let expectedChineseDetails = [
            "梦里写码",
            "正在捣鼓",
            "新鲜出炉",
            "需要救场",
            "给个许可",
            "有个小问号",
            "耳朵竖起",
            "小广播开",
        ]

        for detail in expectedChineseDetails {
            XCTAssertTrue(source.contains("\"\(detail)\""), "LCD Chinese detail should include playful copy \(detail)")
        }
    }

    func testMenuBarAddsLanguageMenuAndUsesToggleForStateCopy() throws {
        let appSource = try String(contentsOfFile: appPath(), encoding: .utf8)
        let agentStateSource = try String(contentsOfFile: agentStatePath(), encoding: .utf8)
        let onboardingSource = try String(contentsOfFile: onboardingThemePath(), encoding: .utf8)

        XCTAssertTrue(agentStateSource.contains("var chineseLabel: String"), "AgentState should expose a Chinese display label for app chrome")
        XCTAssertTrue(agentStateSource.contains("func displayLabel(useChinese: Bool) -> String"), "AgentState should centralize language selection for menu state text")
        XCTAssertTrue(appSource.contains("@AppStorage(\"useChineseRuntimeCopy\")"), "Menu bar should persist the language preference")
        XCTAssertTrue(appSource.contains("monitor.state.displayLabel(useChinese: useChineseRuntimeCopy)"), "Menu bar status should respect the language preference")
        XCTAssertTrue(appSource.contains("Menu(\"Language · \\(useChineseRuntimeCopy ? \"中文\" : \"English\")\")"), "Menu bar should expose a language menu")
        XCTAssertTrue(onboardingSource.contains("@AppStorage(\"useChineseRuntimeCopy\")"), "Onboarding preview should read the same language preference")
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func screenContentPath() -> String {
        projectRoot() + "/Sources/Widget/ScreenContentView.swift"
    }

    private func appPath() -> String {
        projectRoot() + "/Sources/App/CCBeeperApp.swift"
    }

    private func agentStatePath() -> String {
        projectRoot() + "/Sources/Monitor/Core/AgentState.swift"
    }

    private func onboardingThemePath() -> String {
        projectRoot() + "/Sources/Onboarding/OnboardingThemeStep.swift"
    }
}
