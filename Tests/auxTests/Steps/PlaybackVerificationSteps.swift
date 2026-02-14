import AuxLib
import PickleKit
import Testing

/// Then steps for playback verification.
struct PlaybackVerificationSteps: StepDefinitions {
    init() {}

    /// Then the first track is playing
    let thenFirstTrackPlaying = StepDefinition.then(
        #"the first track is playing"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.currentTrack != nil, "No track is playing")
        #expect(state.currentTrack?.trackNumber == 1,
            "Expected track 1 playing, got track \(state.currentTrack?.trackNumber ?? -1)")
        #expect(state.playbackStatus == .playing, "Expected playing status")
    }

    /// Then track N is playing
    let thenTrackNPlaying = StepDefinition.then(
        #"track (\d+) is playing"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let expected = Int(match.captures[0])!
        #expect(state.currentTrack != nil, "No track is playing")
        #expect(state.currentTrack?.trackNumber == expected,
            "Expected track \(expected) playing, got track \(state.currentTrack?.trackNumber ?? -1)")
        #expect(state.playbackStatus == .playing, "Expected playing status")
    }

    /// Then playback is paused
    let thenPlaybackPaused = StepDefinition.then(
        #"playback is paused"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.playbackStatus == .paused, "Expected paused status, got \(state.playbackStatus)")
    }

    /// Then playback is resumed
    let thenPlaybackResumed = StepDefinition.then(
        #"playback is resumed"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.playbackStatus == .playing, "Expected playing status, got \(state.playbackStatus)")
    }

    /// Then the last track remains playing
    let thenLastTrackRemainsPlaying = StepDefinition.then(
        #"the last track remains playing"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        let tracks = state.currentAlbumTracks
        #expect(state.currentTrack != nil, "No track is playing")
        #expect(state.currentTrack?.trackNumber == tracks.last?.trackNumber,
            "Expected last track playing")
        #expect(state.playbackStatus == .playing, "Expected playing status")
    }
}
