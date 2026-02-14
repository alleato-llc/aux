import AuxLib
import PickleKit
import Testing

/// Then steps for visualizer verification.
struct VisualizerVerificationSteps: StepDefinitions {
    init() {}

    /// Then the visualizer mode is spectrum
    let thenVisualizerSpectrum = StepDefinition.then(
        #"the visualizer mode is spectrum"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.visualizerMode == .spectrum,
            "Expected spectrum mode, got \(state.visualizerMode)")
    }

    /// Then the visualizer mode is oscilloscope
    let thenVisualizerOscilloscope = StepDefinition.then(
        #"the visualizer mode is oscilloscope"#
    ) { _ in
        let state = AuxTestContext.shared.ensureState()
        #expect(state.visualizerMode == .oscilloscope,
            "Expected oscilloscope mode, got \(state.visualizerMode)")
    }
}
