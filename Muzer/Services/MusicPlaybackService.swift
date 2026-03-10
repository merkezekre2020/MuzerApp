import Foundation
import MediaPlayer
import UIKit

protocol MusicPlaybackServicing {
    func requestMediaLibraryAccessIfNeeded() async -> Bool
    func currentSongInfo() -> SongInfo?
    func startObserving(_ onUpdate: @escaping @Sendable (SongInfo?) -> Void)
    func stopObserving()
}

final class MusicPlaybackService: MusicPlaybackServicing {
    private let notificationCenter: NotificationCenter
    private var observationTokens: [NSObjectProtocol] = []
    private var pollingTask: Task<Void, Never>?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func requestMediaLibraryAccessIfNeeded() async -> Bool {
        let status = MPMediaLibrary.authorizationStatus()

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                MPMediaLibrary.requestAuthorization { newStatus in
                    continuation.resume(returning: newStatus == .authorized)
                }
            }
        default:
            return false
        }
    }

    func currentSongInfo() -> SongInfo? {
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return nil
        }

        guard
            let title = info[MPMediaItemPropertyTitle] as? String,
            let artist = info[MPMediaItemPropertyArtist] as? String
        else {
            return nil
        }

        let album = info[MPMediaItemPropertyAlbumTitle] as? String
        let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
        let duration = info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval
        let elapsedTime = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval
        let status: SongInfo.PlaybackStatus = playbackRate > 0 ? .playing : .paused

        var artworkData: Data?
        if let artwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            let image = artwork.image(at: CGSize(width: 600, height: 600))
            artworkData = image?.jpegData(compressionQuality: 0.85)
        }

        return SongInfo(
            title: title,
            artist: artist,
            album: album,
            artworkData: artworkData,
            playbackStatus: status,
            duration: duration,
            elapsedTime: elapsedTime
        )
    }

    func startObserving(_ onUpdate: @escaping @Sendable (SongInfo?) -> Void) {
        stopObserving()

        let appActiveToken = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            onUpdate(self?.currentSongInfo())
        }
        observationTokens.append(appActiveToken)

        pollingTask = Task {
            while !Task.isCancelled {
                onUpdate(self.currentSongInfo())
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        onUpdate(currentSongInfo())
    }

    func stopObserving() {
        observationTokens.forEach(notificationCenter.removeObserver)
        observationTokens.removeAll()
        pollingTask?.cancel()
        pollingTask = nil
    }
}
