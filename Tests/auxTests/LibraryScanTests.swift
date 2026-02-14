import AuxLib
import Foundation
import Testing

@Suite struct LibraryScanTests {
    @Test func scanFindsAudioFiles() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        for i in 1...3 {
            try FixtureGenerator.generateTrack(
                at: dir.appendingPathComponent("track\(i).flac"),
                title: "Track \(i)", artist: "Artist", album: "Album",
                trackNumber: i, duration: 1.0
            )
        }

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 3)
    }

    @Test func scanGroupsByAlbum() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t1.flac"),
            title: "T1", artist: "Artist", album: "Album A",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t2.flac"),
            title: "T2", artist: "Artist", album: "Album B",
            trackNumber: 1, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 2)
    }

    @Test func scanSortsTracksCorrectly() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Create tracks out of order
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t3.flac"),
            title: "Track 3", artist: "Artist", album: "Album",
            trackNumber: 3, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t1.flac"),
            title: "Track 1", artist: "Artist", album: "Album",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t2.flac"),
            title: "Track 2", artist: "Artist", album: "Album",
            trackNumber: 2, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 1)
        let tracks = albums[0].tracks
        #expect(tracks[0].trackNumber == 1)
        #expect(tracks[1].trackNumber == 2)
        #expect(tracks[2].trackNumber == 3)
    }

    @Test func scanReadsMetadata() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("song.flac"),
            title: "My Song", artist: "My Artist", album: "My Album",
            trackNumber: 5, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 1)
        let track = albums[0].tracks[0]
        #expect(track.title == "My Song")
        #expect(track.artist == "My Artist")
        #expect(track.album == "My Album")
        #expect(track.trackNumber == 5)
    }

    @Test func scanIgnoresNonAudioFiles() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("song.flac"),
            title: "Song", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )
        // Create a non-audio file
        try "not audio".write(
            to: dir.appendingPathComponent("notes.txt"),
            atomically: true, encoding: .utf8
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 1) // Only the FLAC, not the .txt
    }

    @Test func scanEmptyDirectory() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("EmptyMusic")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.isEmpty)
    }

    @Test func scanRecursesSubdirectories() throws {
        let tempDir = try TemporaryDirectory()
        let root = tempDir.url.appendingPathComponent("Music")
        let subdir = root.appendingPathComponent("SubFolder")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: root.appendingPathComponent("t1.flac"),
            title: "T1", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: subdir.appendingPathComponent("t2.flac"),
            title: "T2", artist: "A", album: "B",
            trackNumber: 2, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: root)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 2) // Both files found
    }

    @Test func scanSkipsHiddenFiles() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("visible.flac"),
            title: "Visible", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )
        // Create a hidden audio file (dot-prefixed)
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent(".hidden.flac"),
            title: "Hidden", artist: "A", album: "B",
            trackNumber: 2, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 1) // Only the visible file
    }

    @Test func scanSkipsHiddenDirectories() throws {
        let tempDir = try TemporaryDirectory()
        let root = tempDir.url.appendingPathComponent("Music")
        let hiddenDir = root.appendingPathComponent(".hidden-folder")
        try FileManager.default.createDirectory(at: hiddenDir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: root.appendingPathComponent("visible.flac"),
            title: "Visible", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: hiddenDir.appendingPathComponent("hidden.flac"),
            title: "Hidden", artist: "A", album: "B",
            trackNumber: 2, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: root)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 1)
    }

    @Test func scanNonExistentDirectoryReturnsEmpty() {
        let albums = LibraryIndex.scan(
            directory: URL(fileURLWithPath: "/nonexistent/path/\(UUID().uuidString)")
        )
        #expect(albums.isEmpty)
    }

    @Test func scanAlbumsSortedAlphabetically() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("z.flac"),
            title: "T1", artist: "Zebra", album: "Z Album",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("a.flac"),
            title: "T1", artist: "Alpha", album: "A Album",
            trackNumber: 1, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 2)
        #expect(albums[0].artist == "Alpha")
        #expect(albums[1].artist == "Zebra")
    }

    @Test func scanReadsCodecAndSampleRate() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("hires.flac"),
            title: "HiRes", artist: "A", album: "B",
            trackNumber: 1, duration: 1.0, sampleRate: 96000
        )

        let albums = LibraryIndex.scan(directory: dir)
        let track = albums[0].tracks[0]
        #expect(track.codec.lowercased() == "flac")
        #expect(track.sampleRate == 96000)
    }

    @Test func scanDifferentArtistsSameAlbumNameCreatesSeparateAlbums() throws {
        let tempDir = try TemporaryDirectory()
        let dir = tempDir.url.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t1.flac"),
            title: "T1", artist: "Artist1", album: "Greatest Hits",
            trackNumber: 1, duration: 1.0
        )
        try FixtureGenerator.generateTrack(
            at: dir.appendingPathComponent("t2.flac"),
            title: "T2", artist: "Artist2", album: "Greatest Hits",
            trackNumber: 1, duration: 1.0
        )

        let albums = LibraryIndex.scan(directory: dir)
        #expect(albums.count == 2) // Grouped separately by artist
    }
}
