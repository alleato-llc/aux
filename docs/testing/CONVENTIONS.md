# Testing Conventions

## BDD Conventions

### One Scenario Per Interaction

Each scenario tests one user interaction and its outcome. Avoid combining multiple independent behaviors in a single scenario.

### Data-Driven Testing

Use `Scenario Outline` with `Examples` tables when testing the same workflow across varying inputs (3+ rows). Keep separate `Scenario` blocks when the logic differs structurally.

### Helper Assertions with sourceLocation

When writing helper functions for complex assertions, pass `sourceLocation` so test failures point to the call site:

```swift
func expectTrackPlaying(
    _ trackNumber: Int, state: PlayerState,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(state.currentTrack?.trackNumber == trackNumber,
        "Expected track \(trackNumber)", sourceLocation: sourceLocation)
}
```

### Test Isolation

- Reset all shared state before each scenario (`AuxTestContext.reset()`)
- Never depend on scenario execution order
- Each scenario creates its own library and state

### Fakes Over Mocks

- `MockAppControl` is a simple fake that records calls
- `TestData` factory creates real `Track`/`Album` values with synthetic data
- No mocking frameworks — keep test doubles simple and explicit

### Deterministic Async

BDD step closures support `async`/`await`, but aux's key handler is synchronous. All state mutations happen immediately, so assertions run right after the action with no waiting.

## Naming Conventions

### Feature Files

- Lowercase with underscores: `library_browsing.feature`
- One feature per domain concept

### Step Definition Files

- PascalCase with role suffix: `CommonSetupSteps`, `PlaybackVerificationSteps`
- Grouped by responsibility: setup, action, verification

### Test Data

- Factory methods on `TestData` enum: `makeTrack()`, `makeAlbum()`, `makeLibrary()`
- Default values for optional parameters (year, genre, codec)
