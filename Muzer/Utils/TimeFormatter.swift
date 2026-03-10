import Foundation

enum TimeFormatter {
    static func shortPlayback(_ time: TimeInterval?) -> String {
        guard let time else { return "--:--" }
        let total = Int(time)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
