import AuxLib
import Foundation

final class MockAppControl: AppControl {
    var didQuit = false
    func quit() { didQuit = true }
}

/// Shared mutable state for aux BDD step definitions.
/// Reset per-scenario via `CommonSetupSteps.init()`.
///
/// Safe because BDD tests run `.serialized` and step handlers run `@MainActor`.
final class AuxTestContext: @unchecked Sendable {
    nonisolated(unsafe) static var shared = AuxTestContext()

    var state: PlayerState?
    var appControl: MockAppControl?

    func reset() {
        state = nil
        appControl = nil
    }

    func ensureState() -> PlayerState {
        guard let state else {
            fatalError("PlayerState not initialized — add a Given step that creates a library")
        }
        return state
    }

    func ensureApp() -> MockAppControl {
        if appControl == nil {
            appControl = MockAppControl()
        }
        return appControl!
    }
}

enum AuxStepError: Error, CustomStringConvertible {
    case setup(String)
    case assertion(String)

    var description: String {
        switch self {
        case let .setup(msg): "Setup error: \(msg)"
        case let .assertion(msg): "Assertion failed: \(msg)"
        }
    }
}
