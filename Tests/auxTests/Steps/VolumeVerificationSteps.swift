import AuxLib
import Foundation
import PickleKit
import Testing

/// Then steps for volume verification.
struct VolumeVerificationSteps: StepDefinitions {
    init() {}

    /// Then the volume is N
    let thenVolumeIs = StepDefinition.then(
        #"the volume is (\d+)"#
    ) { match in
        let state = AuxTestContext.shared.ensureState()
        let expected = Int(match.captures[0])!
        let actual = Int(round(state.volume * 100))
        #expect(actual == expected,
            "Expected volume \(expected)%, got \(actual)%")
    }
}
