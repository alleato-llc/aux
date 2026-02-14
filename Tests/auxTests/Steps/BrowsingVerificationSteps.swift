import AuxLib
import PickleKit
import Testing

/// Then steps for library browsing verification.
struct BrowsingVerificationSteps: StepDefinitions {
    init() {}

    /// Then the selected album index is N
    let thenSelectedAlbumIndex = StepDefinition.then(
        #"the selected album index is (\d+)"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let expected = Int(match.captures[0])!
        #expect(state.selectedAlbumIndex == expected,
            "Expected selected album index \(expected), got \(state.selectedAlbumIndex)")
    }

    /// Then the selected track index is N
    let thenSelectedTrackIndex = StepDefinition.then(
        #"the selected track index is (\d+)"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let expected = Int(match.captures[0])!
        #expect(state.selectedTrackIndex == expected,
            "Expected selected track index \(expected), got \(state.selectedTrackIndex)")
    }

    /// Then focus is on the track list
    let thenFocusTrackList = StepDefinition.then(
        #"focus is on the track list"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.focus == .trackList, "Expected focus on track list, got \(state.focus)")
    }

    /// Then focus is on the sidebar
    let thenFocusSidebar = StepDefinition.then(
        #"focus is on the sidebar"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.focus == .sidebar, "Expected focus on sidebar, got \(state.focus)")
    }
}
