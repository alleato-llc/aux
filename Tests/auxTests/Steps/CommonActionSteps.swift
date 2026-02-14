import AuxLib
import PickleKit
import Tint

/// When steps for aux BDD scenarios.
struct CommonActionSteps: StepDefinitions {
    init() {}

    /// When I press <key>
    let whenPressKey = StepDefinition.when(
        #"I press (.+)"#
    ) { match in
        let ctx = AuxTestContext.shared
        let state = ctx.ensureState()
        let app = ctx.ensureApp()
        let keyName = match.captures[0]
        let key = mapKey(keyName)
        KeyHandler.handle(key: key, state: state, app: app)
    }

    /// When I type "text"
    let whenType = StepDefinition.when(
        #"I type "([^"]*)""#
    ) { match in
        let ctx = AuxTestContext.shared
        let state = ctx.ensureState()
        let app = ctx.ensureApp()
        let text = match.captures[0]
        for char in text {
            let key: Key = .char(char)
            KeyHandler.handle(key: key, state: state, app: app)
        }
    }
}

private func mapKey(_ name: String) -> Key {
    switch name {
    case "Enter": return .enter
    case "Space": return .char(" ")
    case "Escape": return .escape
    case "Tab": return .tab
    case "Backspace": return .backspace
    case "Up": return .up
    case "Down": return .down
    case "Left": return .left
    case "Right": return .right
    default:
        // Single character keys (j, k, h, l, n, b, v, /, ?, c, q, etc.)
        if name.count == 1, let char = name.first {
            return .char(char)
        }
        fatalError("Unknown key name: \(name)")
    }
}
