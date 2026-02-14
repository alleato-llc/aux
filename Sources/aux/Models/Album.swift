import Foundation

struct Album: Sendable {
    let name: String
    let artist: String
    let tracks: [Track]
    let year: Int?
    let genre: String?

    var displayName: String {
        "\(artist) - \(name)"
    }

    var trackCount: Int { tracks.count }

    var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }

    var formattedDuration: String {
        let total = Int(totalDuration)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Format description from first track, e.g. "FLAC 16-bit/44.1kHz"
    var formatDescription: String? {
        guard let first = tracks.first else { return nil }
        var parts = [first.codec.uppercased()]
        if let bitDepth = first.bitDepth {
            parts.append("\(bitDepth)-bit")
        }
        if let sampleRate = first.sampleRate {
            let kHz = Double(sampleRate) / 1000.0
            if kHz == kHz.rounded() {
                parts.append("\(Int(kHz))kHz")
            } else {
                parts.append(String(format: "%.1fkHz", kHz))
            }
        }
        return parts.count > 1 ? parts.joined(separator: "/") : parts.first
    }
}
