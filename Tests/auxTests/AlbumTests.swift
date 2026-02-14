import AuxLib
import Foundation
import Testing

@Suite struct AlbumTests {
    @Test func displayName() {
        let album = TestData.makeAlbum(name: "Nevermind", artist: "Nirvana", trackCount: 1)
        #expect(album.displayName == "Nirvana - Nevermind")
    }

    @Test func totalDuration() {
        let album = TestData.makeAlbum(name: "A", artist: "B", trackCount: 3)
        // TestData.makeTrack uses duration: 180 + i * 10 for tracks 1..3
        // Track 1: 190, Track 2: 200, Track 3: 210
        let expected: TimeInterval = 190 + 200 + 210
        #expect(album.totalDuration == expected)
    }

    @Test func formattedDuration() {
        let album = TestData.makeAlbum(name: "A", artist: "B", trackCount: 3)
        let total = Int(album.totalDuration)
        let mins = total / 60
        let secs = total % 60
        let expected = String(format: "%d:%02d", mins, secs)
        #expect(album.formattedDuration == expected)
    }

    @Test func trackCount() {
        let album = TestData.makeAlbum(name: "A", artist: "B", trackCount: 5)
        #expect(album.trackCount == 5)
    }

    @Test func formatDescriptionNoTracks() {
        let album = Album(name: "Empty", artist: "Nobody", tracks: [], year: nil, genre: nil)
        #expect(album.formatDescription == nil)
    }

    @Test func formatDescriptionCodecOnly() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 100, codec: "flac"
        )
        let album = Album(name: "B", artist: "A", tracks: [track], year: nil, genre: nil)
        #expect(album.formatDescription == "FLAC")
    }

    @Test func formatDescriptionCodecAndBitDepth() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 100, codec: "flac", bitDepth: 16
        )
        let album = Album(name: "B", artist: "A", tracks: [track], year: nil, genre: nil)
        #expect(album.formatDescription == "FLAC/16-bit")
    }

    @Test func formatDescriptionWholeSampleRate() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 100, codec: "flac", sampleRate: 48000
        )
        let album = Album(name: "B", artist: "A", tracks: [track], year: nil, genre: nil)
        #expect(album.formatDescription == "FLAC/48kHz")
    }

    @Test func formatDescriptionDecimalSampleRate() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 100, codec: "flac", sampleRate: 44100
        )
        let album = Album(name: "B", artist: "A", tracks: [track], year: nil, genre: nil)
        #expect(album.formatDescription == "FLAC/44.1kHz")
    }

    @Test func formatDescriptionAllFields() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 100, codec: "flac",
            sampleRate: 192000, bitDepth: 24
        )
        let album = Album(name: "B", artist: "A", tracks: [track], year: nil, genre: nil)
        #expect(album.formatDescription == "FLAC/24-bit/192kHz")
    }
}
