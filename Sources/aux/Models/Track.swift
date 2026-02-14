import Foundation
import LibAVKit

struct Track: Sendable {
    let url: URL
    let title: String
    let artist: String
    let album: String
    let trackNumber: Int
    let discNumber: Int
    let duration: TimeInterval
    let codec: String
    let year: Int?
    let genre: String?
    let sampleRate: Int?
    let bitDepth: Int?

    init(url: URL, metadata: AudioMetadata) {
        self.url = url
        self.title = metadata.title ?? url.deletingPathExtension().lastPathComponent
        self.artist = metadata.artist ?? "Unknown Artist"
        self.album = metadata.album ?? "Unknown Album"
        self.trackNumber = metadata.trackNumber ?? 0
        self.discNumber = metadata.discNumber ?? 1
        self.duration = metadata.duration
        self.codec = metadata.codec
        self.year = metadata.year
        self.genre = metadata.genre
        self.sampleRate = metadata.sampleRate
        self.bitDepth = metadata.bitDepth
    }

    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
