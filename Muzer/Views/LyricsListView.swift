import SwiftUI

struct LyricsListView: View {
    let lines: [LyricLine]
    let activeLineIndex: Int?
    let plainLyrics: String
    let displayMode: PlayerLyricsViewModel.LyricsDisplayMode
    let onModeChange: (PlayerLyricsViewModel.LyricsDisplayMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mod", selection: Binding(
                get: { displayMode },
                set: { onModeChange($0) }
            )) {
                Text("Senkronize").tag(PlayerLyricsViewModel.LyricsDisplayMode.synced)
                Text("Düz").tag(PlayerLyricsViewModel.LyricsDisplayMode.plain)
            }
            .pickerStyle(.segmented)

            if displayMode == .synced, !lines.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(TimeFormatter.shortPlayback(line.time))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 48, alignment: .leading)

                                    Text(line.text)
                                        .font(.body.weight(activeLineIndex == index ? .semibold : .regular))
                                        .foregroundStyle(activeLineIndex == index ? .primary : .secondary)
                                        .animation(.easeInOut(duration: 0.2), value: activeLineIndex)
                                }
                                .id(index)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .onChange(of: activeLineIndex) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            } else {
                ScrollView {
                    Text(plainLyrics)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
