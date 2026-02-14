import AuxLib
import PickleKit
import Testing

/// Then steps for help overlay verification.
struct HelpVerificationSteps: StepDefinitions {
    init() {}

    /// Then the help overlay is visible
    let thenHelpVisible = StepDefinition.then(
        #"the help overlay is visible"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.isShowingHelp, "Expected help overlay to be visible")
    }

    /// Then the help overlay is hidden
    let thenHelpHidden = StepDefinition.then(
        #"the help overlay is hidden"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(!state.isShowingHelp, "Expected help overlay to be hidden")
    }
}
