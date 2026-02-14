import Foundation
import LibAVKit

public struct Track: Sendable {
    public let url: URL
    public let title: String
    public let artist: String
    public let album: String
    public let trackNumber: Int
    public let discNumber: Int
    public let duration: TimeInterval
    public let codec: String
    public let year: Int?
    public let genre: String?
    public let sampleRate: Int?
    public let bitDepth: Int?

    public init(url: URL, metadata: AudioMetadata) {
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

    public init(
        url: URL, title: String, artist: String, album: String,
        trackNumber: Int, discNumber: Int = 1, duration: TimeInterval,
        codec: String = "flac", year: Int? = nil, genre: String? = nil,
        sampleRate: Int? = nil, bitDepth: Int? = nil
    ) {
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.codec = codec
        self.year = year
        self.genre = genre
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
    }

    public var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
