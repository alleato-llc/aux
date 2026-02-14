import AuxLib
import Foundation
import LibAVKit
import Testing

@Suite struct TrackTests {
    @Test func metadataInitAllPresent() {
        var metadata = AudioMetadata()
        metadata.title = "My Song"
        metadata.artist = "My Artist"
        metadata.album = "My Album"
        metadata.trackNumber = 5
        metadata.discNumber = 2
        metadata.duration = 240.0
        metadata.codec = "flac"
        metadata.year = 2024
        metadata.genre = "Rock"
        metadata.sampleRate = 44100
        metadata.bitDepth = 16

        let track = Track(url: URL(fileURLWithPath: "/music/song.flac"), metadata: metadata)
        #expect(track.title == "My Song")
        #expect(track.artist == "My Artist")
        #expect(track.album == "My Album")
        #expect(track.trackNumber == 5)
        #expect(track.discNumber == 2)
        #expect(track.duration == 240.0)
        #expect(track.codec == "flac")
        #expect(track.year == 2024)
        #expect(track.genre == "Rock")
        #expect(track.sampleRate == 44100)
        #expect(track.bitDepth == 16)
    }

    @Test func metadataInitAllNil() {
        let metadata = AudioMetadata()
        let track = Track(url: URL(fileURLWithPath: "/music/cool_song.flac"), metadata: metadata)
        #expect(track.title == "cool_song")
        #expect(track.artist == "Unknown Artist")
        #expect(track.album == "Unknown Album")
        #expect(track.trackNumber == 0)
        #expect(track.discNumber == 1)
        #expect(track.duration == 0)
        #expect(track.codec == "")
    }

    @Test func metadataInitPartial() {
        var metadata = AudioMetadata()
        metadata.title = "Partial"
        metadata.trackNumber = 3
        metadata.codec = "mp3"
        metadata.duration = 180.0

        let track = Track(url: URL(fileURLWithPath: "/music/file.mp3"), metadata: metadata)
        #expect(track.title == "Partial")
        #expect(track.artist == "Unknown Artist")
        #expect(track.album == "Unknown Album")
        #expect(track.trackNumber == 3)
        #expect(track.discNumber == 1)
        #expect(track.duration == 180.0)
    }

    @Test func titleFallbackUsesFilename() {
        let metadata = AudioMetadata()
        let track = Track(url: URL(fileURLWithPath: "/music/cool_song.flac"), metadata: metadata)
        #expect(track.title == "cool_song")
    }

    @Test func formattedDurationZero() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 0
        )
        #expect(track.formattedDuration == "0:00")
    }

    @Test func formattedDurationThreeMinutes() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 180
        )
        #expect(track.formattedDuration == "3:00")
    }

    @Test func formattedDurationLarge() {
        let track = Track(
            url: URL(fileURLWithPath: "/test.flac"), title: "T", artist: "A",
            album: "B", trackNumber: 1, duration: 3661
        )
        #expect(track.formattedDuration == "61:01")
    }
}
