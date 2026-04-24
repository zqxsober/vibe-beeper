import Foundation

struct CodexDetector {
    /// Returns true when the ~/.codex/ directory exists (soft signal — indicates prior install).
    static var codexDirExists: Bool {
        FileManager.default.fileExists(atPath: NSHomeDirectory() + "/.codex")
    }

    /// Searches common install locations for the `codex` binary and returns the first found path.
    static var codexBinaryPath: String? {
        let fm = FileManager.default
        let candidates = [
            NSHomeDirectory() + "/.local/bin/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
        ]

        for candidate in candidates where fm.fileExists(atPath: candidate) {
            return candidate
        }

        return nil
    }

    /// True if Codex appears to be installed (binary found OR ~/.codex/ directory exists).
    static var isInstalled: Bool {
        codexBinaryPath != nil || codexDirExists
    }
}
