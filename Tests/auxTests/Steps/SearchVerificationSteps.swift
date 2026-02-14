import AuxLib
import PickleKit
import Testing

/// Then steps for search verification.
struct SearchVerificationSteps: StepDefinitions {
    init() {}

    /// Then search mode is active
    let thenSearchActive = StepDefinition.then(
        #"search mode is active"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.isSearching, "Expected search mode to be active")
    }

    /// Then search mode is inactive
    let thenSearchInactive = StepDefinition.then(
        #"search mode is inactive"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(!state.isSearching, "Expected search mode to be inactive")
    }

    /// Then the search query is empty
    let thenSearchQueryEmpty = StepDefinition.then(
        #"the search query is empty"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.searchQuery.isEmpty, "Expected empty search query, got '\(state.searchQuery)'")
    }

    /// Then the search query is "X"
    let thenSearchQueryEquals = StepDefinition.then(
        #"the search query is "([^"]*)""#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let expected = match.captures[0]
        #expect(state.searchQuery == expected,
            "Expected search query '\(expected)', got '\(state.searchQuery)'")
    }

    /// Then N album(s) is/are visible
    let thenAlbumsVisible = StepDefinition.then(
        #"(\d+) albums? (?:is|are) visible"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let expected = Int(match.captures[0])!
        let visibleCount = state.filteredAlbumIndices.count
        #expect(visibleCount == expected,
            "Expected \(expected) visible album(s), got \(visibleCount)")
    }
}
