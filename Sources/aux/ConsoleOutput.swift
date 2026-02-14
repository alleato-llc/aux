import Foundation

func printHeader(
    title: String?, artist: String?, album: String?,
    codec: String, sampleRate: Int, channels: Int, duration: TimeInterval
) {
    print("Now playing:")
    if let title { print("  Title:  \(title)") }
    if let artist { print("  Artist: \(artist)") }
    if let album { print("  Album:  \(album)") }
    if !codec.isEmpty { print("  Codec:  \(codec)") }
    print("  Format: \(sampleRate) Hz, \(channels) ch")
    if duration > 0 { print("  Length: \(formatTime(duration))") }
    print()
}

func writeProgress(elapsed: TimeInterval, duration: TimeInterval) {
    if duration > 0 {
        let pct = elapsed / duration * 100
        fputs("\r  \(formatTime(elapsed)) / \(formatTime(duration))  [\(String(format: "%.0f", pct))%]", stdout)
    } else {
        fputs("\r  \(formatTime(elapsed))", stdout)
    }
}

func formatTime(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}
