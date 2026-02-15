import AuxLib
import Foundation
import Testing

@Suite struct PlayerStatePlaybackTests {
    // MARK: - playbackProgress

    @Test func playbackProgressWhenDurationIsZero() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        // No track playing, player.duration == 0
        #expect(state.playbackProgress == 0)
    }

    // MARK: - musicIcon

    @Test func musicIconReturnsNonEmpty() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        #expect(!state.musicIcon.isEmpty)
    }

    @Test func musicIconCyclesOnAlbumChange() {
        let albums = TestData.makeLibrary(albumCount: 2, tracksPerAlbum: 2)
        let state = PlayerState(albums: albums)

        // Play track from album 1
        state.focusRight()
        state.playSelected()
        let icon1 = state.musicIcon

        // Play track from album 2
        state.focusLeft()
        state.moveDown()
        state.focusRight()
        state.playSelected()
        let icon2 = state.musicIcon

        // Icon should have cycled (different album)
        #expect(icon1 != icon2)
    }

    @Test func musicIconStaysOnSameAlbum() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 3))
        state.focusRight()
        state.playSelected()
        let icon1 = state.musicIcon

        // Play next track on same album
        state.nextTrack()
        let icon2 = state.musicIcon

        // Same album → icon should not change
        #expect(icon1 == icon2)
    }

    // MARK: - togglePlayPause

    @Test func togglePlayPauseFromIdleCallsPlaySelected() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 3))
        state.focusRight()
        #expect(state.playbackStatus == .idle)
        #expect(state.currentTrack == nil)

        state.togglePlayPause()

        #expect(state.playbackStatus == .playing)
        #expect(state.currentTrack != nil)
    }

    @Test func togglePlayPauseFromPlayingPauses() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.focusRight()
        state.playSelected()
        #expect(state.playbackStatus == .playing)

        state.togglePlayPause()
        #expect(state.playbackStatus == .paused)
    }

    @Test func togglePlayPauseFromPausedResumes() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.focusRight()
        state.playSelected()
        state.togglePlayPause() // pause
        #expect(state.playbackStatus == .paused)

        state.togglePlayPause() // resume
        #expect(state.playbackStatus == .playing)
    }

    // MARK: - playSelected edge cases

    @Test func playSelectedWithEmptyAlbum() {
        let album = Album(name: "Empty", artist: "Nobody", tracks: [], year: nil, genre: nil)
        let state = PlayerState(albums: [album])
        state.focusRight()
        state.playSelected()
        // Should be no-op — guard catches out-of-bounds
        #expect(state.currentTrack == nil)
        #expect(state.playbackStatus == .idle)
    }

    @Test func playSelectedSetsCurrentTrack() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 3))
        state.focusRight()
        state.moveDown() // select track 2
        state.playSelected()
        #expect(state.currentTrack?.title == "Track 2")
        #expect(state.selectedTrackIndex == 1)
    }

    // MARK: - activeHScroll

    @Test func activeHScrollReturnsSidebarWhenFocusSidebar() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.scrollRight()
        #expect(state.activeHScroll == 4)
    }

    @Test func activeHScrollReturnsTrackListWhenFocusTrackList() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.focusRight()
        state.scrollRight()
        #expect(state.activeHScroll == 4)
        // Sidebar should still be 0
        state.focusLeft()
        #expect(state.activeHScroll == 0)
    }

    // MARK: - nextTrack/previousTrack on empty albums

    @Test func nextTrackWithEmptyAlbumIsNoOp() {
        let album = Album(name: "Empty", artist: "Nobody", tracks: [], year: nil, genre: nil)
        let state = PlayerState(albums: [album])
        state.nextTrack()
        #expect(state.currentTrack == nil)
    }

    @Test func previousTrackWithEmptyAlbumIsNoOp() {
        let album = Album(name: "Empty", artist: "Nobody", tracks: [], year: nil, genre: nil)
        let state = PlayerState(albums: [album])
        state.previousTrack()
        #expect(state.currentTrack == nil)
    }

    // MARK: - selectedAlbum / currentAlbumTracks

    @Test func selectedAlbumReturnsCorrectAlbum() {
        let albums = TestData.makeLibrary(albumCount: 3, tracksPerAlbum: 2)
        let state = PlayerState(albums: albums)
        state.moveDown()
        #expect(state.selectedAlbum?.name == "Album 2")
    }

    @Test func currentAlbumTracksReturnsTracksForSelectedAlbum() {
        let albums = TestData.makeLibrary(albumCount: 2, tracksPerAlbum: 3)
        let state = PlayerState(albums: albums)
        #expect(state.currentAlbumTracks.count == 3)
    }

    // MARK: - Search state methods

    @Test func startSearchEnablesSearchMode() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.startSearch()
        #expect(state.isSearching)
        #expect(state.searchQuery == "")
    }

    @Test func commitSearchKeepsQuery() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.startSearch()
        state.appendSearchChar("a")
        state.commitSearch()
        #expect(!state.isSearching)
        #expect(state.searchQuery == "a")
    }

    @Test func cancelSearchClearsQuery() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.startSearch()
        state.appendSearchChar("a")
        state.cancelSearch()
        #expect(!state.isSearching)
        #expect(state.searchQuery == "")
    }

    @Test func clearFilterRestoresAllAlbums() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 3, tracksPerAlbum: 1))
        state.startSearch()
        for char in "Album 1" { state.appendSearchChar(char) }
        state.commitSearch()
        #expect(state.filteredAlbumIndices.count == 1)

        state.clearFilter()
        #expect(state.filteredAlbumIndices.count == 3)
    }

    @Test func deleteSearchCharRemovesLastChar() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.startSearch()
        state.appendSearchChar("a")
        state.appendSearchChar("b")
        #expect(state.searchQuery == "ab")

        state.deleteSearchChar()
        #expect(state.searchQuery == "a")
    }

    @Test func deleteSearchCharOnEmptyQueryIsNoOp() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.startSearch()
        state.deleteSearchChar()
        #expect(state.searchQuery == "")
    }

    // MARK: - Help toggle

    @Test func toggleHelpShowsAndHides() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        #expect(!state.isShowingHelp)
        state.toggleHelp()
        #expect(state.isShowingHelp)
        state.toggleHelp()
        #expect(!state.isShowingHelp)
    }

    // MARK: - Visualizer mode

    @Test func cycleVisualizerMode() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        #expect(state.visualizerMode == .spectrum)
        state.cycleVisualizerMode()
        #expect(state.visualizerMode == .oscilloscope)
        state.cycleVisualizerMode()
        #expect(state.visualizerMode == .spectrum)
    }

    // MARK: - Volume

    @Test func volumeDefaultIsPlayerVolume() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        #expect(state.volume == state.player.volume)
    }

    @Test func volumeDownDecreasesByStep() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        state.volumeDown()
        #expect(state.volume == 0.95)
    }

    @Test func volumeUpAtMaxStaysAtMax() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        #expect(state.volume == 1.0)
        state.volumeUp()
        #expect(state.volume == 1.0)
    }

    @Test func volumeDownClampsAtZero() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        for _ in 0..<25 { state.volumeDown() }
        #expect(state.volume == 0.0)
    }

    @Test func volumeUpFromZero() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        for _ in 0..<20 { state.volumeDown() }
        #expect(state.volume == 0.0)
        state.volumeUp()
        #expect(abs(state.volume - 0.05) < 0.001)
    }

    // MARK: - Focus

    @Test func focusLeftAndRight() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 1))
        #expect(state.focus == .sidebar)
        state.focusRight()
        #expect(state.focus == .trackList)
        state.focusLeft()
        #expect(state.focus == .sidebar)
    }

    // MARK: - filteredAlbumIndices

    @Test func filteredAlbumIndicesWithNoQuery() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 5, tracksPerAlbum: 1))
        #expect(state.filteredAlbumIndices == [0, 1, 2, 3, 4])
    }

    @Test func filteredAlbumIndicesWithQuery() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 5, tracksPerAlbum: 1))
        state.startSearch()
        for char in "Album 3" { state.appendSearchChar(char) }
        #expect(state.filteredAlbumIndices == [2])
    }

    @Test func filteredAlbumIndicesCaseInsensitive() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 3, tracksPerAlbum: 1))
        state.startSearch()
        for char in "album 1" { state.appendSearchChar(char) }
        #expect(state.filteredAlbumIndices == [0])
    }
}
