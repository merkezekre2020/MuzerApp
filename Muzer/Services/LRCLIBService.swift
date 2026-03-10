import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol LRCLIBServicing {
    func fetchLyrics(for song: SongInfo) async throws -> LyricsResult
}

struct LyricsResult: Equatable {
    enum Source: String, Equatable {
        case synced
        case plain

        var displayTitle: String {
            switch self {
            case .synced:
                return "Senkronize"
            case .plain:
                return "Düz"
            }
        }
    }

    let response: LRCLIBResponse
    let source: Source
}

enum LRCLIBServiceError: LocalizedError, Equatable {
    case invalidURL
    case noInternet
    case decodingFailed
    case emptyResponse
    case notFound
    case rateLimited
    case requestFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Muzer söz servis adresine ulaşamadı."
        case .noInternet:
            return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edip tekrar deneyin."
        case .decodingFailed:
            return "Söz verisi işlenirken bir sorun oluştu."
        case .emptyResponse, .notFound:
            return "Bu şarkı için LRCLIB üzerinde söz bulunamadı."
        case .rateLimited:
            return "Çok fazla istek gönderildi. Birkaç saniye sonra tekrar deneyin."
        case .requestFailed:
            return "LRCLIB servisine bağlanırken beklenmeyen bir hata oluştu."
        }
    }
}

final class LRCLIBService: LRCLIBServicing {
    private enum Constants {
        static let baseURL = "https://lrclib.net/api/search"
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func fetchLyrics(for song: SongInfo) async throws -> LyricsResult {
        guard var components = URLComponents(string: Constants.baseURL) else {
            throw LRCLIBServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "track_name", value: song.title),
            URLQueryItem(name: "artist_name", value: song.artist),
            URLQueryItem(name: "album_name", value: song.album)
        ]

        guard let url = components.url else {
            throw LRCLIBServiceError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LRCLIBServiceError.emptyResponse
            }

            switch httpResponse.statusCode {
            case 200:
                break
            case 404:
                throw LRCLIBServiceError.notFound
            case 429:
                throw LRCLIBServiceError.rateLimited
            default:
                throw LRCLIBServiceError.requestFailed(statusCode: httpResponse.statusCode)
            }

            let results: [LRCLIBResponse]
            do {
                results = try decoder.decode([LRCLIBResponse].self, from: data)
            } catch {
                throw LRCLIBServiceError.decodingFailed
            }

            guard !results.isEmpty else {
                throw LRCLIBServiceError.emptyResponse
            }

            let bestMatch = selectBestMatch(from: results, song: song)

            if let synced = bestMatch.syncedLyrics, !synced.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return LyricsResult(response: bestMatch, source: .synced)
            }

            if let plain = bestMatch.plainLyrics, !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return LyricsResult(response: bestMatch, source: .plain)
            }

            throw LRCLIBServiceError.emptyResponse
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet {
                throw LRCLIBServiceError.noInternet
            }
            throw LRCLIBServiceError.requestFailed(statusCode: -1)
        }
    }

    private func selectBestMatch(from results: [LRCLIBResponse], song: SongInfo) -> LRCLIBResponse {
        results.max(by: { score($0, for: song) < score($1, for: song) }) ?? results[0]
    }

    private func score(_ response: LRCLIBResponse, for song: SongInfo) -> Int {
        var value = 0
        if normalized(response.trackName) == normalized(song.title) { value += 5 }
        if normalized(response.artistName) == normalized(song.artist) { value += 4 }
        if normalized(response.albumName) == normalized(song.album) { value += 3 }
        if response.syncedLyrics != nil { value += 2 }
        if response.plainLyrics != nil { value += 1 }
        return value
    }

    private func normalized(_ text: String?) -> String {
        text?
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}
