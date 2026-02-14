import Foundation
import LibAVKit

/// Generates real audio fixture files for integration tests.
/// Combines SineWaveGenerator + Encoder to create FLAC files with metadata.
enum FixtureGenerator {
    /// Generate a FLAC file with a sine wave and metadata.
    static func generateTrack(
        at url: URL,
        title: String, artist: String, album: String,
        trackNumber: Int, duration: Double = 2.0,
        sampleRate: Int = 44100
    ) throws {
        let samples = SineWaveGenerator.generate(
            frequency: 440.0, sampleRate: sampleRate,
            duration: duration, channels: 2
        )

        var metadata = AudioMetadata()
        metadata.title = title
        metadata.artist = artist
        metadata.album = album
        metadata.trackNumber = trackNumber

        let config = ConversionConfig(
            outputFormat: .flac,
            encodingSettings: .defaults(for: .flac),
            destination: .folder(url.deletingLastPathComponent(), template: nil)
        )

        let encoder = Encoder()
        try encoder.encode(
            samples: samples,
            sampleRate: sampleRate,
            outputURL: url,
            config: config,
            metadata: metadata
        )
    }
}
