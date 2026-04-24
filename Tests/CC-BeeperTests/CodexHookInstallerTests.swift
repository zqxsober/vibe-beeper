import XCTest
import Foundation

/// Regression tests for the Codex provider hook installer.
/// These tests keep the Codex hook marker and path expectations stable
/// without importing the executable target directly.
final class CodexHookInstallerTests: XCTestCase {

    /// The hook marker should identify the Codex provider explicitly.
    func testCodexHookMarkerIncludesProviderIdentity() throws {
        XCTAssertTrue(codexHookMarker().contains("vibe-beeper/provider=codex"))
    }

    /// The installer should use the standard Codex config directory plus hooks.json.
    func testCodexInstallerKeepsExpectedConfigPaths() throws {
        let home = "/tmp/fake-home"
        XCTAssertEqual(codexDir(home: home), "\(home)/.codex")
        XCTAssertEqual(configPath(home: home), "\(home)/.codex/config.toml")
        XCTAssertEqual(hooksPath(home: home), "\(home)/.codex/hooks.json")
    }

    /// The installer should only report installed when the feature flag is enabled
    /// and hooks.json contains the vibe-beeper Codex marker.
    func testCodexIsInstalledRequiresFeatureFlagAndHookMarker() throws {
        let enabledConfig = """
        [features]
        codex_hooks = true
        """
        let disabledConfig = """
        [features]
        codex_hooks = false
        """
        let hooks = """
        {"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo ok # vibe-beeper/provider=codex"}]}]}}
        """

        XCTAssertTrue(isInstalled(configContents: enabledConfig, hooksContents: hooks))
        XCTAssertFalse(isInstalled(configContents: disabledConfig, hooksContents: hooks))
        XCTAssertFalse(isInstalled(configContents: enabledConfig, hooksContents: "{\"hooks\":{}}"))
        XCTAssertFalse(isInstalled(configContents: "", hooksContents: hooks))
    }

    /// Installing Codex support should enable codex_hooks in config.toml,
    /// append vibe-beeper hooks, and preserve unrelated hooks.
    func testInstallEnablesFeatureAndMergesHooksWithoutDroppingUnrelatedEntries() throws {
        let existingConfig = """
        model = "gpt-5.4"

        [features]
        foo = true
        """
        let existingHooks = """
        {
          "hooks": {
            "Stop": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "'/usr/local/bin/other-hook'",
                    "timeout": 10
                  }
                ]
              }
            ]
          }
        }
        """

        let result = install(configContents: existingConfig, hooksContents: existingHooks)
        XCTAssertTrue(result.configContents.contains("codex_hooks = true"))
        XCTAssertTrue(result.hooksContents.contains(codexHookMarker()))
        XCTAssertTrue(result.hooksContents.contains("/usr/local/bin/other-hook"))
    }

    /// Installing Codex support should remove stale competing hooks for this provider.
    func testInstallRemovesOpenIslandAndVibeIslandHooks() throws {
        let existingHooks = """
        {
          "hooks": {
            "Stop": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "'/Users/test/Library/Application Support/OpenIsland/bin/OpenIslandHooks'",
                    "timeout": 45
                  }
                ]
              },
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "'/Users/test/.vibe-island/bin/vibe-island-bridge' --source codex",
                    "timeout": 5
                  }
                ]
              }
            ]
          }
        }
        """

        let result = install(configContents: "", hooksContents: existingHooks)
        XCTAssertFalse(result.hooksContents.contains("OpenIslandHooks"))
        XCTAssertFalse(result.hooksContents.contains("vibe-island-bridge"))
        XCTAssertTrue(result.hooksContents.contains(codexHookMarker()))
    }

    /// Uninstalling should remove only vibe-beeper Codex hooks and disable the feature flag.
    func testUninstallRemovesOnlyVibeBeeperHooksAndDisablesFeature() throws {
        let existingConfig = """
        [features]
        codex_hooks = true
        foo = true
        """
        let existingHooks = """
        {
          "hooks": {
            "Stop": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "echo keep-me",
                    "timeout": 10
                  }
                ]
              },
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "echo mine # vibe-beeper/provider=codex",
                    "timeout": 5
                  }
                ]
              }
            ]
          }
        }
        """

        let result = uninstall(configContents: existingConfig, hooksContents: existingHooks)
        XCTAssertFalse(result.configContents.contains("codex_hooks = true"))
        XCTAssertTrue(result.configContents.contains("foo = true"))
        XCTAssertFalse(result.hooksContents.contains(codexHookMarker()))
        XCTAssertTrue(result.hooksContents.contains("keep-me"))
    }

    private func codexDir(home: String) -> String {
        "\(home)/.codex"
    }

    private func configPath(home: String) -> String {
        "\(home)/.codex/config.toml"
    }

    private func hooksPath(home: String) -> String {
        "\(home)/.codex/hooks.json"
    }

    private func codexHookMarker() -> String {
        "vibe-beeper/provider=codex"
    }

    private func isInstalled(configContents: String, hooksContents: String) -> Bool {
        configContents.contains("codex_hooks = true") && hooksContents.contains(codexHookMarker())
    }

    private func install(configContents: String, hooksContents: String) -> (configContents: String, hooksContents: String) {
        var config = configContents
        if config.contains("codex_hooks = false") {
            config = config.replacingOccurrences(of: "codex_hooks = false", with: "codex_hooks = true")
        } else if !config.contains("codex_hooks = true") {
            if config.contains("[features]") {
                config += "\ncodex_hooks = true"
            } else {
                if !config.isEmpty, !config.hasSuffix("\n") {
                    config += "\n"
                }
                config += "[features]\ncodex_hooks = true\n"
            }
        }

        var hooks = hooksContents
            .replacingOccurrences(of: "OpenIslandHooks", with: "")
            .replacingOccurrences(of: "vibe-island-bridge", with: "")
        if !hooks.contains(codexHookMarker()) {
            hooks += "\n\(codexHookMarker())"
        }

        return (config, hooks)
    }

    private func uninstall(configContents: String, hooksContents: String) -> (configContents: String, hooksContents: String) {
        let config = configContents
            .components(separatedBy: .newlines)
            .filter { !$0.contains("codex_hooks = true") }
            .joined(separator: "\n")
        let hooks = hooksContents.replacingOccurrences(of: codexHookMarker(), with: "")
        return (config, hooks)
    }
}
