# BDD Conventions for aux

## Feature Files

- Write steps as single business concepts, not implementation details
- Given steps describe *what state exists* (e.g., "Given a library with 3 albums")
- When steps describe *what action the user takes* (e.g., "When I press Enter")
- Then steps describe *what the outcome is* (e.g., "Then track 2 is playing")
- Use quoted strings for variable values, bare integers for numeric values
- Group related scenarios with `# --- Section comment ---` dividers

## Step Definitions

- Each step is a `let` stored property with a `StepDefinition.given/when/then()` value
- Use raw string literals for regex: `#"pattern"#`
- Access captures via `match.captures[0]`, `match.captures[1]`, etc.
- Use `#expect()` from Swift Testing for assertions in Then steps
- Comment each step with `/// Given/When/Then <step text>` for discoverability

## Test Architecture (Unified Suite)

aux uses a single unified test suite (`AuxBDDTests`) with shared context:

- **`AuxTestContext`** — singleton holding `PlayerState` and `MockAppControl`
- **`CommonSetupSteps`** — Given steps (library creation, focus, navigation, playback setup)
- **`CommonActionSteps`** — When steps (key presses, typing)
- **Feature-specific verification steps** — Then steps split by domain

## Test Data

- Use `TestData.makeAlbum()` / `TestData.makeLibrary()` to create test data
- Track URLs are fake paths (`/test/Artist/Album/trackN.flac`) — no real audio files
- `PlayerState` is created with a default `AudioPlayer()` that never opens real files
- Tests verify state mutations (`currentTrack`, `playbackStatus`, `selectedTrackIndex`), not audio output

## Runner

- `@Suite(.serialized)` is required — never omit it
- Features are loaded from `Features/` (project root) via `#filePath` navigation
- All step definition types are registered in a single runner

## Key Mapping

The `CommonActionSteps` maps key names from feature files to `Tint.Key` values:
- "Enter" → `.enter`, "Space" → `.char(" ")`, "Escape" → `.escape`
- "Tab" → `.tab`, "Backspace" → `.backspace`
- Single characters (j, k, h, l, n, b, v, /, ?, c) → `.char(x)`
