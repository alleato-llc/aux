import Foundation

public struct Album: Sendable {
    public let name: String
    public let artist: String
    public let tracks: [Track]
    public let year: Int?
    public let genre: String?

    public init(name: String, artist: String, tracks: [Track], year: Int?, genre: String?) {
        self.name = name
        self.artist = artist
        self.tracks = tracks
        self.year = year
        self.genre = genre
    }

    public var displayName: String {
        "\(artist) - \(name)"
    }

    public var trackCount: Int { tracks.count }

    public var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }

    public var formattedDuration: String {
        let total = Int(totalDuration)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Format description from first track, e.g. "FLAC 16-bit/44.1kHz"
    public var formatDescription: String? {
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
