import Foundation

struct LRCLIBResponse: Codable, Equatable, Identifiable {
    var id: String { [trackName, artistName, albumName ?? ""].joined(separator: "|") }

    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: TimeInterval?
    let syncedLyrics: String?
    let plainLyrics: String?

    private enum CodingKeys: String, CodingKey {
        case trackName = "trackName"
        case artistName = "artistName"
        case albumName = "albumName"
        case duration = "duration"
        case syncedLyrics = "syncedLyrics"
        case plainLyrics = "plainLyrics"
    }
}
