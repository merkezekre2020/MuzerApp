import Foundation

struct LRCParser {
    private static let timestampPattern = #"\[(\d{1,2}:\d{1,2}(?:\.\d{1,3})?)\]"#

    func parse(_ content: String) -> [LyricLine] {
        content
            .split(whereSeparator: \.isNewline)
            .compactMap(parseLine(_:))
            .sorted(by: { $0.time < $1.time })
    }

    private func parseLine(_ rawLine: Substring) -> LyricLine? {
        let line = String(rawLine)
        guard let regex = try? NSRegularExpression(pattern: Self.timestampPattern) else {
            return nil
        }

        let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)
        let matches = regex.matches(in: line, range: nsrange)
        guard let lastMatch = matches.last,
              let timestampRange = Range(lastMatch.range(at: 1), in: line),
              let fullTagRange = Range(lastMatch.range(at: 0), in: line),
              let timestamp = parseTimestamp(String(line[timestampRange]))
        else {
            return nil
        }

        let lyricText = line[fullTagRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lyricText.isEmpty else { return nil }

        return LyricLine(time: timestamp, text: lyricText)
    }

    private func parseTimestamp(_ raw: String) -> TimeInterval? {
        let parts = raw.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return nil
        }
        return (minutes * 60) + seconds
    }

    func activeLineIndex(for time: TimeInterval, in lines: [LyricLine]) -> Int? {
        guard !lines.isEmpty else { return nil }
        return lines.lastIndex(where: { $0.time <= time })
    }
}
