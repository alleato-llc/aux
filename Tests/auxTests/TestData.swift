import AuxLib
import Foundation

enum TestData {
    static func makeTrack(
        artist: String, album: String, trackNumber: Int,
        title: String? = nil, duration: TimeInterval = 180
    ) -> Track {
        Track(
            url: URL(fileURLWithPath: "/test/\(artist)/\(album)/track\(trackNumber).flac"),
            title: title ?? "Track \(trackNumber)",
            artist: artist,
            album: album,
            trackNumber: trackNumber,
            duration: duration
        )
    }

    static func makeAlbum(
        name: String, artist: String, trackCount: Int,
        year: Int? = 2024, genre: String? = "Rock"
    ) -> Album {
        let tracks = (1...trackCount).map { i in
            makeTrack(artist: artist, album: name, trackNumber: i, duration: TimeInterval(180 + i * 10))
        }
        return Album(name: name, artist: artist, tracks: tracks, year: year, genre: genre)
    }

    static func makeLibrary(albumCount: Int, tracksPerAlbum: Int) -> [Album] {
        (1...albumCount).map { i in
            makeAlbum(name: "Album \(i)", artist: "Artist \(i)", trackCount: tracksPerAlbum)
        }
    }

    static func makeLibrary(albumCount: Int = 1, trackCount: Int) -> [Album] {
        (1...albumCount).map { i in
            makeAlbum(name: "Album \(i)", artist: "Artist \(i)", trackCount: trackCount)
        }
    }
}
