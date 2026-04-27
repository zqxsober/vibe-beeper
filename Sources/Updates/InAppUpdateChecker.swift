import AppKit
import Foundation
import UpdateCore

@MainActor
final class InAppUpdateChecker: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate(version: String)
        case updateAvailable(version: String, url: URL)
        case failed(message: String)
    }

    @Published private(set) var status: Status = .idle

    private let currentVersion: String
    private let latestReleaseURL: URL
    private let session: URLSession

    init(
        currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0",
        latestReleaseURL: URL = URL(string: "https://api.github.com/repos/zqxsober/vibe-beeper/releases/latest")!,
        session: URLSession = .shared
    ) {
        self.currentVersion = currentVersion
        self.latestReleaseURL = latestReleaseURL
        self.session = session
    }

    func checkForUpdates() {
        Task {
            await checkForUpdatesNow()
        }
    }

    func checkForUpdatesNow() async {
        status = .checking

        do {
            let latestRelease = try await fetchLatestRelease()
            if AppVersion.isRemoteVersion(latestRelease.tagName, newerThan: currentVersion) {
                status = .updateAvailable(version: latestRelease.tagName, url: latestRelease.htmlURL)
            } else {
                status = .upToDate(version: latestRelease.tagName)
            }
        } catch {
            status = .failed(message: userMessage(for: error))
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("vibe-beeper", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateCheckError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UpdateCheckError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func userMessage(for error: Error) -> String {
        if let updateError = error as? UpdateCheckError {
            switch updateError {
            case .invalidResponse:
                return "Could not read the update response."
            case .httpStatus(let statusCode):
                return "Could not check for updates. GitHub returned HTTP \(statusCode)."
            }
        }

        if error is DecodingError {
            return "Could not read the latest release information."
        }

        return "Could not check for updates. Please try again later."
    }
}

private enum UpdateCheckError: Error {
    case invalidResponse
    case httpStatus(Int)
}

