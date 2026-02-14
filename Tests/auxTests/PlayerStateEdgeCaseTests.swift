import AuxLib
import Testing

@Suite struct PlayerStateEdgeCaseTests {
    // MARK: - Filtered navigation

    @Test func moveDownWithFilter() {
        // Albums: "Album 1" (idx 0), "Album 2" (idx 1), "Album 3" (idx 2),
        //         "Album 4" (idx 3), "Album 5" (idx 4)
        // Filter "Album 1" matches only index 0, but let's use a filter that matches 1, 3, 5
        let albums = (1...5).map {
            TestData.makeAlbum(name: "Album \($0)", artist: "Artist \($0)", trackCount: 1)
        }
        let state = PlayerState(albums: albums)

        // Search for "1" matches "Album 1" (idx 0) — only one match
        state.startSearch()
        state.appendSearchChar("1")
        // filteredAlbumIndices should be [0] ("Artist 1 - Album 1" contains "1")
        // Actually "1" matches indices 0 ("Artist 1 - Album 1") only? No, all contain "1" in "Artist 1"
        // Let's use a more specific query
        state.cancelSearch()

        // Use "Album 3" to match only index 2
        state.startSearch()
        for char in "Album 3" { state.appendSearchChar(char) }
        state.commitSearch()

        #expect(state.filteredAlbumIndices == [2])
        // moveDown should be no-op (only one match)
        state.moveDown()
        #expect(state.selectedAlbumIndex == 2)
    }

    @Test func moveUpWithFilter() {
        let albums = (1...5).map {
            TestData.makeAlbum(name: "Album \($0)", artist: "Musician \($0)", trackCount: 1)
        }
        let state = PlayerState(albums: albums)

        // Filter to match albums containing "3" or "5"
        state.startSearch()
        for char in "Musician" { state.appendSearchChar(char) }
        state.commitSearch()

        // All 5 albums match "Musician", navigate to last
        let indices = state.filteredAlbumIndices
        #expect(indices.count == 5)

        // Navigate to last album
        for _ in 0..<4 { state.moveDown() }
        #expect(state.selectedAlbumIndex == 4)

        // Move up one
        state.moveUp()
        #expect(state.selectedAlbumIndex == 3)
    }

    @Test func moveWhenNotInFilteredResults() {
        let albums = (1...5).map {
            TestData.makeAlbum(name: "Album \($0)", artist: "Artist \($0)", trackCount: 1)
        }
        let state = PlayerState(albums: albums)
        // Select album 3 (index 2)
        state.moveDown()
        state.moveDown()
        #expect(state.selectedAlbumIndex == 2)

        // Now filter to "Album 5" — selection not in results, should snap
        state.startSearch()
        for char in "Album 5" { state.appendSearchChar(char) }

        #expect(state.filteredAlbumIndices == [4])
        #expect(state.selectedAlbumIndex == 4)
    }

    @Test func filterNoMatches() {
        let albums = TestData.makeLibrary(albumCount: 3, tracksPerAlbum: 1)
        let state = PlayerState(albums: albums)

        state.startSearch()
        for char in "zzzzz" { state.appendSearchChar(char) }

        #expect(state.filteredAlbumIndices.isEmpty)
        // moveDown/moveUp should be no-ops
        let before = state.selectedAlbumIndex
        state.moveDown()
        #expect(state.selectedAlbumIndex == before)
        state.moveUp()
        #expect(state.selectedAlbumIndex == before)
    }

    // MARK: - Horizontal scroll

    @Test func scrollRightIncrementsBy4() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, tracksPerAlbum: 1))
        #expect(state.sidebarHScroll == 0)
        state.scrollRight()
        #expect(state.sidebarHScroll == 4)
    }

    @Test func scrollLeftClampsAtZero() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, tracksPerAlbum: 1))
        state.scrollLeft()
        #expect(state.sidebarHScroll == 0)
    }

    @Test func scrollRightTrackList() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, tracksPerAlbum: 1))
        state.focusRight()
        state.scrollRight()
        #expect(state.trackListHScroll == 4)
    }

    @Test func resetHScroll() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, tracksPerAlbum: 1))
        state.scrollRight()
        state.scrollRight()
        #expect(state.sidebarHScroll == 8)
        state.resetHScroll()
        #expect(state.sidebarHScroll == 0)
    }

    // MARK: - Track navigation edge cases

    @Test func previousTrackAtFirstTrack() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 3))
        state.focusRight()
        #expect(state.selectedTrackIndex == 0)
        state.previousTrack()
        // At track 0 with player.currentTime == 0, should be no-op
        #expect(state.selectedTrackIndex == 0)
    }

    @Test func nextTrackAtLastTrack() {
        let state = PlayerState(albums: TestData.makeLibrary(albumCount: 1, trackCount: 3))
        state.focusRight()
        // Navigate to last track
        state.moveDown()
        state.moveDown()
        #expect(state.selectedTrackIndex == 2)
        state.nextTrack()
        // At last track, nextTrack should be no-op
        #expect(state.selectedTrackIndex == 2)
    }
}
