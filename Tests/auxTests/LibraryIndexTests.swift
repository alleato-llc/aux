@testable import AuxLib
import Foundation
import Testing

@Suite struct LibraryIndexTests {
    @Test func groupsSameAlbumTracks() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/t1.flac"), title: "T1", artist: "A", album: "B", trackNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/t2.flac"), title: "T2", artist: "A", album: "B", trackNumber: 2, duration: 100),
            Track(url: URL(fileURLWithPath: "/t3.flac"), title: "T3", artist: "A", album: "B", trackNumber: 3, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 3)
    }

    @Test func sortsByDiscThenTrack() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/t3.flac"), title: "T3", artist: "A", album: "B", trackNumber: 3, discNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/t1.flac"), title: "T1", artist: "A", album: "B", trackNumber: 1, discNumber: 2, duration: 100),
            Track(url: URL(fileURLWithPath: "/t2.flac"), title: "T2", artist: "A", album: "B", trackNumber: 1, discNumber: 1, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        #expect(albums.count == 1)
        let sortedTracks = albums[0].tracks
        // Disc 1 track 1 first, then disc 1 track 3, then disc 2 track 1
        #expect(sortedTracks[0].title == "T2") // disc 1, track 1
        #expect(sortedTracks[1].title == "T3") // disc 1, track 3
        #expect(sortedTracks[2].title == "T1") // disc 2, track 1
    }

    @Test func alphabeticalAlbumSort() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/c.flac"), title: "T1", artist: "Charlie", album: "C Album", trackNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/a.flac"), title: "T1", artist: "Alpha", album: "A Album", trackNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/b.flac"), title: "T1", artist: "Bravo", album: "B Album", trackNumber: 1, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        #expect(albums.count == 3)
        #expect(albums[0].displayName == "Alpha - A Album")
        #expect(albums[1].displayName == "Bravo - B Album")
        #expect(albums[2].displayName == "Charlie - C Album")
    }

    @Test func caseInsensitiveSort() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/z.flac"), title: "T1", artist: "zebra", album: "Z", trackNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/a.flac"), title: "T1", artist: "Apple", album: "A", trackNumber: 1, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        #expect(albums.count == 2)
        #expect(albums[0].artist == "Apple")
        #expect(albums[1].artist == "zebra")
    }

    @Test func singleTrackAlbum() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/t.flac"), title: "Solo", artist: "A", album: "B", trackNumber: 1, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        #expect(albums.count == 1)
        #expect(albums[0].trackCount == 1)
    }

    @Test func sameArtistDifferentAlbums() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/t1.flac"), title: "T1", artist: "A", album: "Album1", trackNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/t2.flac"), title: "T2", artist: "A", album: "Album2", trackNumber: 1, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        #expect(albums.count == 2)
    }

    @Test func differentArtistSameAlbumName() {
        let tracks = [
            Track(url: URL(fileURLWithPath: "/t1.flac"), title: "T1", artist: "Artist1", album: "Greatest Hits", trackNumber: 1, duration: 100),
            Track(url: URL(fileURLWithPath: "/t2.flac"), title: "T2", artist: "Artist2", album: "Greatest Hits", trackNumber: 1, duration: 100),
        ]
        let albums = LibraryIndex.buildAlbums(from: tracks)
        // Grouped separately because key includes artist
        #expect(albums.count == 2)
    }

    @Test func emptyInput() {
        let albums = LibraryIndex.buildAlbums(from: [])
        #expect(albums.isEmpty)
    }
}
