import SwiftUI

struct PlayerLyricsView: View {
    @StateObject private var viewModel = PlayerLyricsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.12, green: 0.11, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                content
                    .padding(16)
            }
            .navigationTitle("Muzer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Yenile")
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView()
        case let .empty(message):
            EmptyStateView(
                title: "Muzer şu an sessiz",
                message: message
            )
        case let .error(message):
            ErrorStateView(
                title: "Muzer bir sorun yaşadı",
                message: message,
                retryAction: viewModel.retry
            )
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AlbumArtworkView(artworkData: viewModel.song?.artworkData)

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.song?.title ?? "Bilinmeyen Parça")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(viewModel.song?.artist ?? "Bilinmeyen Sanatçı")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                    if let album = viewModel.song?.album, !album.isEmpty {
                        Text(album)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.song?.playbackStatus == .playing ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(viewModel.song?.playbackStatus.displayText ?? "Bilinmiyor")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(viewModel.sourceTag)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                if let warning = viewModel.matchedSongWarning {
                    Label(warning, systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                LyricsListView(
                    lines: viewModel.syncedLines,
                    activeLineIndex: viewModel.activeLineIndex,
                    plainLyrics: viewModel.plainLyrics,
                    displayMode: viewModel.displayMode,
                    onModeChange: viewModel.setDisplayMode
                )
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

#Preview {
    PlayerLyricsView()
}
