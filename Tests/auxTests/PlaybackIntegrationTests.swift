import AuxLib
import Foundation
import LibAVKit
import Testing

@Suite struct PlaybackIntegrationTests {
    @Test func playTrackOpensRealFile() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url
        let trackURL = dir.appendingPathComponent("test.flac")

        try FixtureGenerator.generateTrack(
            at: trackURL,
            title: "Test", artist: "A", album: "B",
            trackNumber: 1, duration: 2.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.playSelected()

        #expect(state.playbackStatus == .playing)
        #expect(state.currentTrack?.title == "Test")
    }

    @Test func nextTrackAdvancesWithRealAudio() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t1.flac"),
            title: "First", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t2.flac"),
            title: "Second", artist: "A", album: "B",
            trackNumber: 2, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.playSelected()

        #expect(state.currentTrack?.title == "First")

        state.nextTrack()
        #expect(state.currentTrack?.title == "Second")
        #expect(state.selectedTrackIndex == 1)
    }

    @Test func togglePlayPauseWithRealAudio() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("test.flac"),
            title: "Test", artist: "A", album: "B",
            trackNumber: 1, duration: 2.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.playSelected()
        #expect(state.playbackStatus == .playing)

        state.togglePlayPause()
        #expect(state.playbackStatus == .paused)

        state.togglePlayPause()
        #expect(state.playbackStatus == .playing)
    }

    @Test func previousTrackWithRealAudio() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t1.flac"),
            title: "First", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t2.flac"),
            title: "Second", artist: "A", album: "B",
            trackNumber: 2, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.moveDown()
        state.playSelected()
        #expect(state.currentTrack?.title == "Second")

        // currentTime is near 0, so previousTrack goes to prior track
        state.previousTrack()
        #expect(state.currentTrack?.title == "First")
        #expect(state.selectedTrackIndex == 0)
    }

    @Test func playbackDurationReportsNonZeroForRealFile() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("test.flac"),
            title: "Test", artist: "A", album: "B",
            trackNumber: 1, duration: 2.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.playSelected()

        // Real file should report non-zero duration
        #expect(state.player.duration > 0)
    }

    @Test func nextTrackAtEndOfAlbumIsNoOpWithRealAudio() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("only.flac"),
            title: "Only Track", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.playSelected()
        #expect(state.currentTrack?.title == "Only Track")

        state.nextTrack()
        // Still on the same track
        #expect(state.currentTrack?.title == "Only Track")
        #expect(state.selectedTrackIndex == 0)
    }

    @Test func scanAndPlayMultipleAlbums() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        // Album A
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("a1.flac"),
            title: "A Song", artist: "Alpha", album: "First Album",
            trackNumber: 1, duration: 1.0
        )
        // Album B
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("b1.flac"),
            title: "B Song", artist: "Beta", album: "Second Album",
            trackNumber: 1, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 2)

        let state = PlayerState(albums: albums)
        // Play from first album
        state.focusRight()
        state.playSelected()
        let firstAlbumTrack = state.currentTrack?.artist

        // Navigate to second album and play
        state.focusLeft()
        state.moveDown()
        state.focusRight()
        state.playSelected()
        let secondAlbumTrack = state.currentTrack?.artist

        #expect(firstAlbumTrack != secondAlbumTrack)
    }

    @Test func trackMetadataMatchesScannedData() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("song.flac"),
            title: "Specific Title", artist: "Specific Artist",
            album: "Specific Album", trackNumber: 7, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        let state = PlayerState(albums: albums)
        state.focusRight()
        state.playSelected()

        #expect(state.currentTrack?.title == "Specific Title")
        #expect(state.currentTrack?.artist == "Specific Artist")
        #expect(state.currentTrack?.album == "Specific Album")
        #expect(state.currentTrack?.trackNumber == 7)
    }
}
