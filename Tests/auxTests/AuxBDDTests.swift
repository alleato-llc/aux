import Foundation
import PickleKit
import Testing

@Suite(.serialized)
struct AuxBDDTests {
    private static let featuresPath: String = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/auxTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // project root
            .appendingPathComponent("Features")
            .path
    }()

    static let allScenarios = GherkinTestScenario.scenarios(paths: [featuresPath])

    @Test(arguments: AuxBDDTests.allScenarios)
    func scenario(_ test: GherkinTestScenario) async throws {
        let result = try await test.run(stepDefinitions: [
            CommonSetupSteps.self,
            CommonActionSteps.self,
            BrowsingVerificationSteps.self,
            PlaybackVerificationSteps.self,
            SearchVerificationSteps.self,
            HelpVerificationSteps.self,
            VisualizerVerificationSteps.self,
        ])
        #expect(result.passed, "Scenario '\(test.description)' failed: \(failureDetails(result))")
    }

    private func failureDetails(_ result: ScenarioResult) -> String {
        result.stepResults
            .filter { $0.status != .passed }
            .map { "\($0.keyword) \($0.text): \($0.error ?? "unknown error")" }
            .joined(separator: "\n")
    }
}
