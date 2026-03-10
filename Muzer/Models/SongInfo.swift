import Foundation

struct SongInfo: Codable, Equatable, Identifiable {
    var id: String { [title, artist, album ?? ""].joined(separator: "|") }

    let title: String
    let artist: String
    let album: String?
    let artworkData: Data?
    let playbackStatus: PlaybackStatus
    let duration: TimeInterval?
    let elapsedTime: TimeInterval?

    enum PlaybackStatus: String, Codable, Equatable {
        case playing
        case paused
        case stopped

        var displayText: String {
            switch self {
            case .playing:
                return "Çalıyor"
            case .paused:
                return "Duraklatıldı"
            case .stopped:
                return "Durduruldu"
            }
        }
    }
}
