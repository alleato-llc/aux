import AuxLib
import Testing
import Tint

@Suite struct KeyHandlerTests {
    private func makeState(albumCount: Int = 2, trackCount: Int = 3) -> (PlayerState, MockAppControl) {
        let albums = TestData.makeLibrary(albumCount: albumCount, tracksPerAlbum: trackCount)
        let state = PlayerState(albums: albums)
        let app = MockAppControl()
        return (state, app)
    }

    // MARK: - Arrow keys

    @Test func downArrowMovesDown() {
        let (state, app) = makeState()
        KeyHandler.handle(key: .down, state: state, app: app)
        #expect(state.selectedAlbumIndex == 1)
    }

    @Test func upArrowMovesUp() {
        let (state, app) = makeState()
        state.moveDown()
        KeyHandler.handle(key: .up, state: state, app: app)
        #expect(state.selectedAlbumIndex == 0)
    }

    @Test func leftArrowScrollsLeft() {
        let (state, app) = makeState()
        state.scrollRight() // sidebarHScroll = 4
        KeyHandler.handle(key: .left, state: state, app: app)
        #expect(state.sidebarHScroll == 0)
    }

    @Test func rightArrowScrollsRight() {
        let (state, app) = makeState()
        KeyHandler.handle(key: .right, state: state, app: app)
        #expect(state.sidebarHScroll == 4)
    }

    // MARK: - Uppercase H/L for scrolling

    @Test func uppercaseHScrollsLeft() {
        let (state, app) = makeState()
        state.scrollRight()
        KeyHandler.handle(key: .char("H"), state: state, app: app)
        #expect(state.sidebarHScroll == 0)
    }

    @Test func uppercaseLScrollsRight() {
        let (state, app) = makeState()
        KeyHandler.handle(key: .char("L"), state: state, app: app)
        #expect(state.sidebarHScroll == 4)
    }

    // MARK: - Zero key resets scroll

    @Test func zeroKeyResetsHScroll() {
        let (state, app) = makeState()
        state.scrollRight()
        state.scrollRight()
        #expect(state.sidebarHScroll == 8)
        KeyHandler.handle(key: .char("0"), state: state, app: app)
        #expect(state.sidebarHScroll == 0)
    }

    // MARK: - p key toggles play/pause

    @Test func pKeyTogglesPlayPause() {
        let (state, app) = makeState()
        state.focusRight()
        state.playSelected()
        #expect(state.playbackStatus == .playing)
        KeyHandler.handle(key: .char("p"), state: state, app: app)
        #expect(state.playbackStatus == .paused)
    }

    // MARK: - Escape in normal mode is no-op

    @Test func escapeInNormalModeIsNoOp() {
        let (state, app) = makeState()
        let albumBefore = state.selectedAlbumIndex
        let focusBefore = state.focus
        KeyHandler.handle(key: .escape, state: state, app: app)
        #expect(state.selectedAlbumIndex == albumBefore)
        #expect(state.focus == focusBefore)
        #expect(!state.isSearching)
        #expect(!state.isShowingHelp)
    }

    // MARK: - Unrecognized key is no-op

    @Test func unrecognizedKeyIsNoOp() {
        let (state, app) = makeState()
        let albumBefore = state.selectedAlbumIndex
        KeyHandler.handle(key: .char("z"), state: state, app: app)
        #expect(state.selectedAlbumIndex == albumBefore)
    }

    // MARK: - Ctrl+C quits

    @Test func ctrlCQuits() {
        let (state, app) = makeState()
        KeyHandler.handle(key: .ctrlC, state: state, app: app)
        #expect(app.didQuit)
    }

    // MARK: - q key quits

    @Test func qKeyQuits() {
        let (state, app) = makeState()
        KeyHandler.handle(key: .char("q"), state: state, app: app)
        #expect(app.didQuit)
    }

    // MARK: - Tab in search mode commits search

    @Test func tabInSearchModeCommitsSearch() {
        let (state, app) = makeState()
        state.startSearch()
        for char in "Album 1" { state.appendSearchChar(char) }
        #expect(state.isSearching)

        KeyHandler.handle(key: .tab, state: state, app: app)
        #expect(!state.isSearching)
        #expect(state.searchQuery == "Album 1")
    }

    // MARK: - Help overlay blocks all keys except ? and Escape

    @Test func helpOverlayBlocksNavigationKeys() {
        let (state, app) = makeState()
        state.toggleHelp()
        #expect(state.isShowingHelp)

        // j should not change album selection
        KeyHandler.handle(key: .char("j"), state: state, app: app)
        #expect(state.selectedAlbumIndex == 0)
        #expect(state.isShowingHelp) // still showing

        // q should not quit
        KeyHandler.handle(key: .char("q"), state: state, app: app)
        #expect(!app.didQuit)
        #expect(state.isShowingHelp)
    }

    @Test func helpOverlayBlocksSearchEntry() {
        let (state, app) = makeState()
        state.toggleHelp()
        KeyHandler.handle(key: .char("/"), state: state, app: app)
        #expect(!state.isSearching)
        #expect(state.isShowingHelp)
    }

    // MARK: - Search mode captures all keys

    @Test func searchModeBlocksNavigation() {
        let (state, app) = makeState()
        state.startSearch()
        // j in search mode types 'j', doesn't navigate
        KeyHandler.handle(key: .char("j"), state: state, app: app)
        #expect(state.searchQuery == "j")
        #expect(state.selectedAlbumIndex == 0)
    }

    @Test func searchModeDoesNotQuit() {
        let (state, app) = makeState()
        state.startSearch()
        KeyHandler.handle(key: .char("q"), state: state, app: app)
        #expect(!app.didQuit)
        #expect(state.searchQuery == "q")
    }

    // MARK: - Volume keys

    @Test func minusKeyDecreasesVolume() {
        let (state, app) = makeState()
        let before = state.volume
        KeyHandler.handle(key: .char("-"), state: state, app: app)
        #expect(state.volume < before)
    }

    @Test func plusKeyIncreasesVolumeWhenBelow100() {
        let (state, app) = makeState()
        state.volumeDown() // 95%
        let before = state.volume
        KeyHandler.handle(key: .char("+"), state: state, app: app)
        #expect(state.volume > before)
    }

    @Test func volumeKeysBlockedInSearchMode() {
        let (state, app) = makeState()
        state.startSearch()
        let before = state.volume
        KeyHandler.handle(key: .char("-"), state: state, app: app)
        #expect(state.volume == before)
        // "-" was typed into search query instead
        #expect(state.searchQuery == "-")
    }

    @Test func volumeKeysBlockedInHelpOverlay() {
        let (state, app) = makeState()
        state.toggleHelp()
        let before = state.volume
        KeyHandler.handle(key: .char("-"), state: state, app: app)
        #expect(state.volume == before)
        #expect(state.isShowingHelp)
    }

    // MARK: - Enter behavior depends on focus

    @Test func enterInSidebarFocusesTrackList() {
        let (state, app) = makeState()
        #expect(state.focus == .sidebar)
        KeyHandler.handle(key: .enter, state: state, app: app)
        #expect(state.focus == .trackList)
    }

    @Test func enterInTrackListPlaysTrack() {
        let (state, app) = makeState()
        state.focusRight()
        KeyHandler.handle(key: .enter, state: state, app: app)
        #expect(state.playbackStatus == .playing)
        #expect(state.currentTrack != nil)
    }
}
