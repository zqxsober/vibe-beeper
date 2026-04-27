import Foundation

public struct GitHubRelease: Decodable, Equatable {
    public let tagName: String
    public let htmlURL: URL

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

