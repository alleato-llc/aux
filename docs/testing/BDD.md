# BDD Testing in aux

## Overview

aux uses [PickleKit](https://github.com/alleato-llc/pickle-kit) for behavior-driven development testing. Since aux is a TUI application (not SwiftUI), we can't use XCUITest. Instead, BDD tests exercise the **state machine + key handler** layer — `PlayerState` mutations driven through `KeyHandler.handle()`.

The renderers are pure functions of state, so testing state correctness effectively tests UI behavior.

## Architecture

### What We Test

- **Navigation**: Album/track selection, focus switching, scroll
- **Playback**: Track selection, play/pause, next/previous
- **Search**: Enter/exit search mode, query filtering, clear
- **Help overlay**: Show/hide, key capture
- **Visualizer**: Mode cycling

### What We Don't Test

- Audio decoding/playback (LibAVKit internals)
- Terminal rendering (Tint internals)
- File system scanning (requires real audio files)

### Test Strategy

Tests drive `KeyHandler.handle()` with `Tint.Key` values and assert on `PlayerState` properties:

```
Feature file step → CommonActionSteps → KeyHandler.handle(key, state, mockApp) → assert PlayerState
```

No real audio files are opened. `PlayerState` is created with fake `Track`/`Album` data and a default `AudioPlayer()`. The `currentTrack` and `playbackStatus` properties track what the user requested; actual audio player state is irrelevant for BDD tests.

### Test Infrastructure

#### `AppControl` and `MockAppControl`

`KeyHandler.handle()` takes an `any AppControl` parameter — a protocol with a single method:

```swift
// KeyHandler.swift
public protocol AppControl {
    func quit()
}

extension Application: AppControl {}
```

In production, `Application` (from Tint) conforms to `AppControl` and terminates the TUI. In tests, `MockAppControl` records whether `quit()` was called without actually exiting:

```swift
// AuxTestContext.swift
final class MockAppControl: AppControl {
    var didQuit = false
    func quit() { didQuit = true }
}
```

This is the **only test double** in the suite. Everything else — `PlayerState`, `AudioPlayer`, `KeyHandler` — uses real production code. The protocol boundary exists solely because `Application.quit()` is a side effect that can't be undone in a test process.

#### `AuxTestContext`

BDD step definitions are separate structs (`CommonSetupSteps`, `CommonActionSteps`, `BrowsingVerificationSteps`, etc.) that each run independently. They need a way to share state within a scenario — the Given step creates a `PlayerState`, the When step mutates it, and the Then step asserts on it.

`AuxTestContext` is a singleton that bridges this gap:

```swift
// AuxTestContext.swift
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
```

**Design intent:**

- **Shared singleton** — Step definitions are instantiated by PickleKit, not by the test. A singleton lets Given, When, and Then steps across different structs access the same `PlayerState` without dependency injection.
- **Reset per scenario** — `CommonSetupSteps.init()` calls `ctx.reset()`, clearing state before each scenario. This guarantees isolation: no state leaks between scenarios.
- **`ensureState()` / `ensureApp()`** — Guard methods that fail fast with a clear message if a scenario is missing a Given step. This catches misconfigured feature files at test time instead of producing cryptic nil crashes.
- **`@unchecked Sendable`** — Safe because the test suite runs with `@Suite(.serialized)` and all step handlers execute on the main actor. The annotation satisfies Swift 6 concurrency checking without requiring actor isolation.

## Design Decisions

### Why We Don't Test the TUI Rendering Layer

Terminal UI frameworks like Tint don't have a UI testing harness equivalent to XCUITest. But even if they did, we wouldn't use it. The renderers are **pure functions** with the signature:

```swift
static func render(state: PlayerState, area: Rect, theme: PlayerTheme, buffer: inout Buffer)
```

They read from `PlayerState`, write into a `Buffer`, and have no side effects. This means:

- If the state is correct, the rendering is correct by construction
- Testing state mutations (via BDD) transitively covers the rendering layer
- Rendering assertions would be fragile — tied to exact layout, padding, and Unicode characters that change during UI polish

The BDD suite tests the **state machine that drives rendering**, not the rendering itself. Every Then step asserts on `PlayerState` properties (`selectedAlbumIndex`, `currentTrack`, `playbackStatus`, `isSearching`, `isShowingHelp`, `visualizerMode`, etc.) — never on terminal buffer contents.

#### Example: Search filtering drives the sidebar

This walkthrough traces a single BDD scenario from test data setup through state mutation to rendering, showing why testing state is sufficient.

**The feature scenario:**

```gherkin
Scenario: Search filters albums by name
  Given a library with 3 albums of 3 tracks each
  And I am in search mode
  When I type "Album 1"
  Then 1 album is visible
```

**Step 1 — Test data setup.** The Given step creates fake albums via `TestData`:

```swift
// TestData.swift
static func makeLibrary(albumCount: Int, tracksPerAlbum: Int) -> [Album] {
    (1...albumCount).map { i in
        makeAlbum(name: "Album \(i)", artist: "Artist \(i)", trackCount: tracksPerAlbum)
    }
}
```

This produces 3 albums named "Album 1", "Album 2", "Album 3" — each with fake track URLs like `/test/Artist 1/Album 1/track1.flac`. The Given step feeds these into a fresh `PlayerState`:

```swift
// CommonSetupSteps.swift
let givenLibraryAlbumsAndTracks = StepDefinition.given(
    #"a library with (\d+) albums? of (\d+) tracks? each"#
) { match in
    let albums = TestData.makeLibrary(albumCount: 3, tracksPerAlbum: 3)
    ctx.state = PlayerState(albums: albums)  // default AudioPlayer(), no real files
    ctx.appControl = MockAppControl()
}
```

**Step 2 — State mutation.** The When step types "Album 1" character by character via `KeyHandler`:

```swift
// CommonActionSteps.swift
let whenType = StepDefinition.when(#"I type "([^"]*)""#) { match in
    for char in match.captures[0] {
        KeyHandler.handle(key: .char(char), state: state, app: app)
    }
}
```

Each character appends to `state.searchQuery` (because search mode is active).

**Step 3 — Computed property.** `filteredAlbumIndices` derives the visible set from `searchQuery`:

```swift
// PlayerState.swift
public var filteredAlbumIndices: [Int] {
    guard !searchQuery.isEmpty else {
        return Array(0..<albums.count)    // no query → all albums
    }
    let query = searchQuery.lowercased()
    return albums.indices.filter {
        albums[$0].displayName.lowercased().contains(query)
    }
}
```

After typing "Album 1", this returns `[0]` — only the first album matches.

**Step 4 — Assertion.** The Then step checks the count:

```swift
// SearchVerificationSteps.swift
let thenAlbumsVisible = StepDefinition.then(
    #"(\d+) albums? (?:is|are) visible"#
) { match in
    let state = AuxTestContext.shared.ensureState()
    let expected = Int(match.captures[0])!
    #expect(state.filteredAlbumIndices.count == expected)
}
```

**Step 5 — Why this covers rendering.** `SidebarRenderer` reads the exact same computed property to build its list:

```swift
// SidebarRenderer.swift
let filteredIndices = state.filteredAlbumIndices  // ← same property the test asserts
let items = filteredIndices.map { index -> ListWidget.Item in
    let album = state.albums[index]
    // ...
    return ListWidget.Item("\(prefix)\(album.displayName)", style: style)
}

let selectedPos = filteredIndices.firstIndex(of: state.selectedAlbumIndex)
let list = ListWidget(
    items: items,
    selected: isFocused ? selectedPos : nil,
    highlightSymbol: "> ",
)
```

The renderer shows exactly the albums in `filteredAlbumIndices` and highlights whichever one matches `selectedAlbumIndex`. The BDD test proves `filteredAlbumIndices` contains 1 element after the search. Since the renderer reads that same property — nothing else controls which albums appear — we know only "Album 1" is visible in the sidebar. No `Buffer` inspection needed.

### Why Tests Use a Real AudioPlayer (No Mocks)

Tests construct `PlayerState` with the default `AudioPlayer()` initializer — a real player instance, not a mock. This works because of how `playTrack()` is structured:

```swift
public func playTrack(_ track: Track) {
    player.stop()
    currentTrack = track       // ← state set eagerly
    playbackStatus = .playing  // ← state set eagerly
    do {
        try player.open(url: track.url)  // ← fails on fake URLs
        player.play()
    } catch {
        // Silently skip unplayable tracks
    }
}
```

State mutations (`currentTrack`, `playbackStatus`) happen **before** the player attempts to open the file. Test data uses fake paths like `/test/Artist/Album/track1.flac` (from `TestData.swift`), so `player.open(url:)` throws and is silently caught. The state is already set, which is all BDD assertions check.

**Why not mock?** A default `AudioPlayer()` is harmless — it creates an idle player that doesn't touch audio hardware until `open()` is called. No mocking infrastructure is needed because:

- The real player is safe to instantiate (no side effects until `open()`)
- Fake URLs fail fast at `open()` (no I/O, no decoding)
- State mutations are decoupled from playback success

**In production**, the silent catch is a defensive fallback. `LibraryIndex.scan()` only includes files that `MetadataReader` successfully reads, so by the time a track appears in the library it was already readable. The catch handles edge cases like a file deleted between scan and play.

## File Structure

```
Features/                      Gherkin feature files (project root)
├── library_browsing.feature
├── playback.feature
├── search.feature
├── help_overlay.feature
└── visualizer.feature

Tests/auxTests/
├── Steps/                              BDD step definitions
│   ├── AuxTestContext.swift
│   ├── CommonSetupSteps.swift
│   ├── CommonActionSteps.swift
│   ├── BrowsingVerificationSteps.swift
│   ├── PlaybackVerificationSteps.swift
│   ├── SearchVerificationSteps.swift
│   ├── HelpVerificationSteps.swift
│   └── VisualizerVerificationSteps.swift
├── Support/                            Test helpers
│   ├── TemporaryDirectory.swift
│   └── FixtureGenerator.swift
├── TestData.swift                      Fake test data factories
├── AuxBDDTests.swift                   BDD test runner
├── SampleBufferTests.swift             Unit tests
├── FormatTimeTests.swift
├── AlbumTests.swift
├── TrackTests.swift
├── KeyHandlerTests.swift
├── PlayerStateEdgeCaseTests.swift
├── PlayerStatePlaybackTests.swift
├── OscilloscopeComputationTests.swift
├── SpectrumComputationTests.swift
├── LibraryIndexTests.swift
├── LibraryScanTests.swift              Integration tests
└── PlaybackIntegrationTests.swift
```

## Running Tests

```bash
# Run all tests
swift test

# Run only BDD tests
swift test --filter AuxBDDTests

# Run with parallel execution
swift test --parallel
```

## Adding New Scenarios

1. Add the scenario to an existing `.feature` file (or create a new one)
2. If new Given/When steps are needed, add them to `CommonSetupSteps` or `CommonActionSteps`
3. If new Then steps are needed, add them to the appropriate verification file or create a new one
4. Register any new step definition types in `AuxBDDTests.swift`

## HTML Reports

PickleKit includes a built-in HTML report generator controlled by environment variables:

| Variable | Purpose | Default |
|----------|---------|---------|
| `PICKLE_REPORT` | Enable report generation (set to `1`) | disabled |
| `PICKLE_REPORT_PATH` | Output file path | `pickle-report.html` |

### Usage

```bash
# Generate report at default path (pickle-report.html)
PICKLE_REPORT=1 swift test

# Generate report at custom path
PICKLE_REPORT=1 PICKLE_REPORT_PATH=reports/bdd.html swift test
```

The report is a self-contained HTML file with:
- Summary cards (total scenarios, pass/fail counts)
- Feature/scenario/step results with pass/fail filtering
- Expand/collapse for scenario details
- Timing data per step and scenario

> `pickle-report.html` is in `.gitignore` — do not commit generated reports.

## Conventions

See [.claude/rules/bdd-conventions.md](../../.claude/rules/bdd-conventions.md) for the full BDD conventions guide.
