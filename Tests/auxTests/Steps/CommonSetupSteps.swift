import AuxLib
import Foundation
import PickleKit

/// Given steps for aux BDD scenarios.
struct CommonSetupSteps: StepDefinitions {
    init() {
        let ctx = AuxTestContext.shared
        ctx.reset()
    }

    /// Given a library with N albums of M tracks each
    let givenLibraryAlbumsAndTracks = StepDefinition.given(
        #"a library with (\d+) albums? of (\d+) tracks? each"#
    ) { match in
        let ctx = AuxTestContext.shared
        let albumCount = Int(match.captures[0])!
        let trackCount = Int(match.captures[1])!
        let albums = TestData.makeLibrary(albumCount: albumCount, tracksPerAlbum: trackCount)
        ctx.state = PlayerState(albums: albums)
        ctx.appControl = MockAppControl()
    }

    /// Given a library with N album of M tracks
    let givenLibrarySingleAlbum = StepDefinition.given(
        #"a library with (\d+) albums? of (\d+) tracks?$"#
    ) { match in
        let ctx = AuxTestContext.shared
        let albumCount = Int(match.captures[0])!
        let trackCount = Int(match.captures[1])!
        let albums = TestData.makeLibrary(albumCount: albumCount, trackCount: trackCount)
        ctx.state = PlayerState(albums: albums)
        ctx.appControl = MockAppControl()
    }

    /// Given I am focused on the sidebar
    let givenFocusSidebar = StepDefinition.given(
        #"I am focused on the sidebar"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.focusLeft()
    }

    /// Given I am focused on the track list
    let givenFocusTrackList = StepDefinition.given(
        #"I am focused on the track list"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.focusRight()
    }

    /// Given I navigate down N times
    let givenNavigateDown = StepDefinition.given(
        #"I navigate down (\d+) times?"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let times = Int(match.captures[0])!
        for _ in 0..<times {
            state.moveDown()
        }
    }

    /// Given a track is playing
    let givenTrackPlaying = StepDefinition.given(
        #"a track is playing"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.focusRight()
        state.playSelected()
    }

    /// Given a track is paused
    let givenTrackPaused = StepDefinition.given(
        #"a track is paused"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.focusRight()
        state.playSelected()
        state.togglePlayPause()
    }

    /// Given I am playing track N
    let givenSpecificTrackPlaying = StepDefinition.given(
        #"I am playing track (\d+)$"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let trackNum = Int(match.captures[0])!
        state.focusRight()
        // Navigate to the track (trackNum is 1-based)
        for _ in 0..<(trackNum - 1) {
            state.moveDown()
        }
        state.playSelected()
    }

    /// Given track N is playing at the beginning
    let givenTrackPlayingAtBeginning = StepDefinition.given(
        #"track (\d+) is playing at the beginning"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let trackNum = Int(match.captures[0])!
        state.focusRight()
        for _ in 0..<(trackNum - 1) {
            state.moveDown()
        }
        state.playSelected()
        // player.currentTime will be 0 (no real audio), which is "at the beginning"
    }

    /// Given the last track is playing
    let givenLastTrackPlaying = StepDefinition.given(
        #"the last track is playing"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.focusRight()
        let trackCount = state.currentAlbumTracks.count
        for _ in 0..<(trackCount - 1) {
            state.moveDown()
        }
        state.playSelected()
    }

    /// Given the help overlay is open
    let givenHelpVisible = StepDefinition.given(
        #"the help overlay is open"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.toggleHelp()
    }

    /// Given the visualizer is set to oscilloscope
    let givenVisualizerOscilloscope = StepDefinition.given(
        #"the visualizer is set to oscilloscope"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.cycleVisualizerMode()
    }

    /// Given the volume is set to N
    let givenVolumeSetTo = StepDefinition.given(
        #"the volume is set to (\d+)"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let target = Int(match.captures[0])!
        let current = Int(round(state.volume * 100))
        if target < current {
            for _ in 0..<((current - target) / 5) { state.volumeDown() }
        } else if target > current {
            for _ in 0..<((target - current) / 5) { state.volumeUp() }
        }
    }

    /// Given I am in search mode
    let givenSearchActive = StepDefinition.given(
        #"I am in search mode$"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        state.startSearch()
    }

    /// Given I am in search mode with query "X"
    let givenSearchActiveWithQuery = StepDefinition.given(
        #"I am in search mode with query "([^"]*)""#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        state.startSearch()
        for char in match.captures[0] {
            state.appendSearchChar(char)
        }
    }
}
