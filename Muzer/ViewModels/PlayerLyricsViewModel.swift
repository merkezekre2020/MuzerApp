import Foundation

@MainActor
final class PlayerLyricsViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case empty(String)
        case error(String)
    }

    enum LyricsDisplayMode: String, CaseIterable {
        case synced
        case plain

        var title: String {
            switch self {
            case .synced:
                return "Senkronize"
            case .plain:
                return "Düz"
            }
        }
    }

    @Published private(set) var song: SongInfo?
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var sourceTag: String = "LRCLIB"
    @Published private(set) var syncedLines: [LyricLine] = []
    @Published private(set) var plainLyrics: String = ""
    @Published private(set) var activeLineIndex: Int?
    @Published var displayMode: LyricsDisplayMode = .synced
    @Published private(set) var matchedSongWarning: String?

    private let musicService: MusicPlaybackServicing
    private let lyricsService: LRCLIBServicing
    private let parser: LRCParser

    private var playbackTickerTask: Task<Void, Never>?
    private var currentElapsedTime: TimeInterval = 0
    private var currentlyFetchingSongID: String?

    init(
        musicService: MusicPlaybackServicing = MusicPlaybackService(),
        lyricsService: LRCLIBServicing = LRCLIBService(),
        parser: LRCParser = LRCParser()
    ) {
        self.musicService = musicService
        self.lyricsService = lyricsService
        self.parser = parser
    }

    deinit {
        musicService.stopObserving()
        playbackTickerTask?.cancel()
    }

    func onAppear() {
        Task {
            _ = await musicService.requestMediaLibraryAccessIfNeeded()
            startPlaybackObservation()
        }
    }

    func refresh() {
        fetchLyricsForCurrentSong(forceRefresh: true)
    }

    func retry() {
        fetchLyricsForCurrentSong(forceRefresh: true)
    }

    func setDisplayMode(_ mode: LyricsDisplayMode) {
        displayMode = mode
    }

    private func startPlaybackObservation() {
        musicService.startObserving { [weak self] updatedSong in
            guard let self else { return }
            Task { @MainActor in
                self.handleSongUpdate(updatedSong)
            }
        }
    }

    private func handleSongUpdate(_ updatedSong: SongInfo?) {
        guard let updatedSong else {
            clearLyricsAndShowEmptyState(
                message: "Muzer şu anda çalan bir parça algılayamadı. Apple Music'te bir parça başlatın."
            )
            return
        }

        let hasSongChanged = updatedSong.id != song?.id
        song = updatedSong
        currentElapsedTime = updatedSong.elapsedTime ?? currentElapsedTime

        if updatedSong.playbackStatus == .playing {
            startTickerIfNeeded()
        } else {
            playbackTickerTask?.cancel()
            playbackTickerTask = nil
        }

        if hasSongChanged {
            fetchLyricsForCurrentSong(forceRefresh: true)
        } else if !syncedLines.isEmpty {
            activeLineIndex = parser.activeLineIndex(for: currentElapsedTime, in: syncedLines)
        }
    }

    private func fetchLyricsForCurrentSong(forceRefresh: Bool) {
        guard let song else {
            clearLyricsAndShowEmptyState(message: "Muzer için önce bir parça oynatın.")
            return
        }

        if !forceRefresh, currentlyFetchingSongID == song.id { return }
        currentlyFetchingSongID = song.id
        state = .loading

        Task {
            defer { currentlyFetchingSongID = nil }
            do {
                let result = try await lyricsService.fetchLyrics(for: song)
                applyLyrics(result, for: song)
            } catch let serviceError as LRCLIBServiceError {
                state = .error(serviceError.errorDescription ?? "Muzer sözleri yükleyemedi.")
            } catch {
                state = .error("Muzer beklenmeyen bir hata ile karşılaştı. Tekrar deneyin.")
            }
        }
    }

    private func applyLyrics(_ result: LyricsResult, for currentSong: SongInfo) {
        matchedSongWarning = mismatchWarningIfNeeded(currentSong: currentSong, matchedSong: result.response)
        plainLyrics = result.response.plainLyrics ?? ""

        if let synced = result.response.syncedLyrics {
            let lines = parser.parse(synced)
            syncedLines = lines
            if !lines.isEmpty {
                displayMode = .synced
                activeLineIndex = parser.activeLineIndex(for: currentElapsedTime, in: lines)
                state = .loaded
                return
            }
        }

        syncedLines = []
        if !plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayMode = .plain
            state = .loaded
        } else {
            state = .empty("Muzer bu parça için söz bulamadı.")
        }
    }

    private func clearLyricsAndShowEmptyState(message: String) {
        song = nil
        syncedLines = []
        plainLyrics = ""
        activeLineIndex = nil
        matchedSongWarning = nil
        state = .empty(message)
    }

    private func startTickerIfNeeded() {
        guard playbackTickerTask == nil else { return }

        playbackTickerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    guard self.song?.playbackStatus == .playing else { return }
                    self.currentElapsedTime += 0.5
                    if !self.syncedLines.isEmpty {
                        self.activeLineIndex = self.parser.activeLineIndex(for: self.currentElapsedTime, in: self.syncedLines)
                    }
                }
            }
        }
    }

    private func mismatchWarningIfNeeded(currentSong: SongInfo, matchedSong: LRCLIBResponse) -> String? {
        let currentKey = [currentSong.title, currentSong.artist, currentSong.album ?? ""]
            .joined(separator: "|")
            .lowercased()
        let matchedKey = [matchedSong.trackName, matchedSong.artistName, matchedSong.albumName ?? ""]
            .joined(separator: "|")
            .lowercased()

        return currentKey == matchedKey ? nil : "LRCLIB eşleşmesi çalan parça ile tam uyuşmuyor."
    }
}
