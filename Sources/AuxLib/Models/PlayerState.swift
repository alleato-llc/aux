import Foundation
import LibAVKit

public enum Focus: Sendable {
    case sidebar
    case trackList
}

public enum VisualizerMode: Sendable {
    case oscilloscope
    case spectrum
}

public enum PlaybackStatus: Sendable {
    case idle
    case playing
    case paused
}

public final class PlayerState: @unchecked Sendable {
    public let albums: [Album]
    public private(set) var selectedAlbumIndex: Int = 0
    public private(set) var selectedTrackIndex: Int = 0
    public private(set) var focus: Focus = .sidebar
    public private(set) var searchQuery: String = ""
    public private(set) var isSearching: Bool = false
    public private(set) var sidebarHScroll: Int = 0
    public private(set) var trackListHScroll: Int = 0
    public private(set) var visualizerMode: VisualizerMode = .spectrum
    public private(set) var isShowingHelp: Bool = false
    public private(set) var playbackStatus: PlaybackStatus = .idle
    private static let musicIcons = ["♪", "♫", "♬", "♩", "◉", "⏵", "☊", "⊛"]
    private var musicIconIndex: Int = Int.random(in: 0..<musicIcons.count)

    public let sampleBuffer = SampleBuffer()
    public let player: AudioPlayer
    public private(set) var currentTrack: Track?

    public init(albums: [Album], player: AudioPlayer = AudioPlayer()) {
        self.albums = albums
        self.player = player
        player.onStateChange = { [weak self] state in
            guard let self else { return }
            if state == .completed {
                let tracks = self.currentAlbumTracks
                let nextIndex = self.selectedTrackIndex + 1
                if nextIndex < tracks.count {
                    self.nextTrack()
                } else {
                    self.playbackStatus = .idle
                }
            }
        }
    }

    public var selectedAlbum: Album? {
        guard selectedAlbumIndex < albums.count else { return nil }
        return albums[selectedAlbumIndex]
    }

    public var currentAlbumTracks: [Track] {
        selectedAlbum?.tracks ?? []
    }

    public var playbackProgress: Double {
        guard player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }

    public var musicIcon: String {
        Self.musicIcons[musicIconIndex % Self.musicIcons.count]
    }

    // MARK: - Navigation

    public func moveUp() {
        switch focus {
        case .sidebar:
            let indices = filteredAlbumIndices
            guard let pos = indices.firstIndex(of: selectedAlbumIndex) else {
                if let first = indices.first {
                    selectedAlbumIndex = first
                    selectedTrackIndex = 0
                }
                return
            }
            if pos > 0 {
                selectedAlbumIndex = indices[pos - 1]
                selectedTrackIndex = 0
            }
        case .trackList:
            if selectedTrackIndex > 0 {
                selectedTrackIndex -= 1
            }
        }
    }

    public func moveDown() {
        switch focus {
        case .sidebar:
            let indices = filteredAlbumIndices
            guard let pos = indices.firstIndex(of: selectedAlbumIndex) else {
                if let first = indices.first {
                    selectedAlbumIndex = first
                    selectedTrackIndex = 0
                }
                return
            }
            if pos < indices.count - 1 {
                selectedAlbumIndex = indices[pos + 1]
                selectedTrackIndex = 0
            }
        case .trackList:
            if selectedTrackIndex < currentAlbumTracks.count - 1 {
                selectedTrackIndex += 1
            }
        }
    }

    public func focusLeft() {
        focus = .sidebar
    }

    public func focusRight() {
        focus = .trackList
    }

    // MARK: - Horizontal Scroll

    private static let hScrollStep = 4

    public var activeHScroll: Int {
        switch focus {
        case .sidebar: return sidebarHScroll
        case .trackList: return trackListHScroll
        }
    }

    public func scrollRight() {
        switch focus {
        case .sidebar: sidebarHScroll += Self.hScrollStep
        case .trackList: trackListHScroll += Self.hScrollStep
        }
    }

    public func scrollLeft() {
        switch focus {
        case .sidebar: sidebarHScroll = max(0, sidebarHScroll - Self.hScrollStep)
        case .trackList: trackListHScroll = max(0, trackListHScroll - Self.hScrollStep)
        }
    }

    public func resetHScroll() {
        switch focus {
        case .sidebar: sidebarHScroll = 0
        case .trackList: trackListHScroll = 0
        }
    }

    // MARK: - Visualizer

    public func cycleVisualizerMode() {
        switch visualizerMode {
        case .oscilloscope: visualizerMode = .spectrum
        case .spectrum: visualizerMode = .oscilloscope
        }
    }

    // MARK: - Playback

    public func playSelected() {
        let tracks = currentAlbumTracks
        guard selectedTrackIndex < tracks.count else { return }
        let track = tracks[selectedTrackIndex]
        playTrack(track)
    }

    private var lastPlayedAlbum: String?

    public func playTrack(_ track: Track) {
        player.stop()
        currentTrack = track
        playbackStatus = .playing
        // Cycle icon when a different album starts playing
        let albumKey = "\(track.artist) - \(track.album)"
        if albumKey != lastPlayedAlbum {
            lastPlayedAlbum = albumKey
            musicIconIndex = (musicIconIndex + 1) % Self.musicIcons.count
        }
        do {
            try player.open(url: track.url)
            player.play()
        } catch {
            // Silently skip unplayable tracks
        }
    }

    public func togglePlayPause() {
        switch playbackStatus {
        case .playing:
            player.pause()
            playbackStatus = .paused
        case .paused:
            player.play()
            playbackStatus = .playing
        case .idle:
            playSelected()
        }
    }

    public func nextTrack() {
        let tracks = currentAlbumTracks
        guard !tracks.isEmpty else { return }
        let nextIndex = selectedTrackIndex + 1
        if nextIndex < tracks.count {
            selectedTrackIndex = nextIndex
            playTrack(tracks[nextIndex])
        }
    }

    public func previousTrack() {
        let tracks = currentAlbumTracks
        guard !tracks.isEmpty else { return }
        // If more than 3 seconds in, restart current track
        if player.currentTime > 3.0, let track = currentTrack {
            player.seek(to: 0)
            playbackStatus = .playing
            _ = track
            return
        }
        let prevIndex = selectedTrackIndex - 1
        if prevIndex >= 0 {
            selectedTrackIndex = prevIndex
            playTrack(tracks[prevIndex])
        }
    }

    // MARK: - Search

    public func startSearch() {
        isSearching = true
        searchQuery = ""
    }

    public func commitSearch() {
        isSearching = false
    }

    public func cancelSearch() {
        isSearching = false
        searchQuery = ""
    }

    public func clearFilter() {
        searchQuery = ""
    }

    // MARK: - Help

    public func toggleHelp() {
        isShowingHelp.toggle()
    }

    public func appendSearchChar(_ char: Character) {
        searchQuery.append(char)
        snapSelectionToFilter()
    }

    public func deleteSearchChar() {
        _ = searchQuery.popLast()
        snapSelectionToFilter()
    }

    private func snapSelectionToFilter() {
        let indices = filteredAlbumIndices
        if !indices.contains(selectedAlbumIndex), let first = indices.first {
            selectedAlbumIndex = first
            selectedTrackIndex = 0
        }
    }

    public var filteredAlbumIndices: [Int] {
        guard !searchQuery.isEmpty else {
            return Array(0..<albums.count)
        }
        let query = searchQuery.lowercased()
        return albums.indices.filter {
            albums[$0].displayName.lowercased().contains(query)
        }
    }
}
