# Testing Philosophy

## Test Layers

aux has two test layers:

### BDD Integration Tests (Primary)

Validate keyboard-driven workflows through state. These are the main test suite and cover the most important user-visible behaviors. Each scenario exercises a realistic sequence of key presses and verifies the resulting state.

- **Framework**: PickleKit (Swift-native Cucumber/BDD)
- **Scope**: `KeyHandler` → `PlayerState` mutations
- **Coverage**: Navigation, playback controls, search, help overlay, visualizer mode

### Unit Tests (Supplementary)

Edge cases in pure logic that don't map cleanly to user workflows. These supplement BDD tests for isolated functions.

- **Framework**: Swift Testing
- **Scope**: Pure functions (time formatting, search filtering, etc.)
- **Coverage**: Edge cases, boundary conditions, error paths

## Principles

### Test Behavior, Not Implementation

Tests should verify what the user observes, not how the code achieves it. If a refactor changes internal structure but preserves behavior, tests should still pass.

### State Machine Testing

The TUI's architecture makes testing straightforward: all behavior flows through `PlayerState`. Key events are the inputs, state properties are the outputs.

Renderers are pure functions — `(PlayerState, Rect, Theme, &Buffer) → Void` — with no side effects or state mutation. Testing state correctness transitively covers the rendering layer: if the state is right, the rendering is right by construction. Rendering assertions would be fragile (tied to exact layout and Unicode characters) and redundant.

For example, the BDD scenario `"Search filters albums by name"` types "Album 1" into the search field and asserts only 1 album is visible. Expressed as plain Swift Testing code, the equivalent test would be:

```swift
// 1. Build test data — 3 albums with fake track URLs (no real audio files)
let albums = (1...3).map { i in
    TestData.makeAlbum(name: "Album \(i)", artist: "Artist \(i)", trackCount: 3)
}

// 2. Initialize state — default AudioPlayer(), no mock needed
let state = PlayerState(albums: albums)

// 3. MockAppControl — the only test double in the suite.
//    KeyHandler.handle() takes `any AppControl` so that pressing 'q' calls
//    app.quit(). In production, Tint's Application conforms and terminates the
//    TUI. MockAppControl records the call without exiting the test process.
let app = MockAppControl()

// 4. Enter search mode and type a query
KeyHandler.handle(key: .char("/"), state: state, app: app)  // activate search
for char in "Album 1" {
    KeyHandler.handle(key: .char(char), state: state, app: app)
}

// 5. Assert on state — filteredAlbumIndices is the same property the renderer reads
#expect(state.filteredAlbumIndices.count == 1)
#expect(state.albums[state.filteredAlbumIndices[0]].name == "Album 1")
```

In the actual BDD suite, this setup/assert flow is spread across step definition structs that share state via `AuxTestContext` — a singleton holding the current `PlayerState` and `MockAppControl`, reset before each scenario. See [BDD.md — Test Infrastructure](BDD.md#test-infrastructure) for the full design.

`SidebarRenderer` reads that exact `filteredAlbumIndices` property to decide which albums to display:

```swift
// SidebarRenderer.swift — filteredAlbumIndices drives the visible list
let filteredIndices = state.filteredAlbumIndices
let items = filteredIndices.map { index -> ListWidget.Item in
    let album = state.albums[index]
    return ListWidget.Item("\(prefix)\(album.displayName)", style: style)
}
```

The test proves 1 album survives the filter. Since the renderer iterates `filteredAlbumIndices` to build the list — nothing else controls which albums appear — we know only "Album 1" is visible. No `Buffer` inspection needed.

See [BDD.md — Why We Don't Test the TUI Rendering Layer](BDD.md#why-we-dont-test-the-tui-rendering-layer) for the full walkthrough with BDD step definitions.

### No Real Audio, Almost No Mocks

BDD tests never open audio files or produce sound. Tests use the **real** `AudioPlayer` (default initializer) rather than a mock. This works because `playTrack()` sets state eagerly — `currentTrack` and `playbackStatus` are assigned before `player.open(url:)` is called. When `open()` fails on fake test URLs, the error is silently caught, but state is already set for assertions.

A default `AudioPlayer()` is harmless — it creates an idle player with no side effects until `open()` is called. In production, the silent catch is a defensive fallback for edge cases (file deleted between scan and play); `LibraryIndex.scan()` pre-validates files via `MetadataReader`.

The only test double is `MockAppControl`, which exists because `Application.quit()` terminates the process — an irreversible side effect. Everything else (`PlayerState`, `AudioPlayer`, `KeyHandler`) is real production code.

See [BDD.md — Why Tests Use a Real AudioPlayer](BDD.md#why-tests-use-a-real-audioplayer-no-mocks) for the full rationale.

### Isolation

Each scenario starts with a fresh `PlayerState`. `AuxTestContext.reset()` is called in `CommonSetupSteps.init()` before every scenario, clearing both `state` and `appControl` to `nil`. The Given step then creates a new `PlayerState` and `MockAppControl` from scratch. No state leaks between scenarios.

### Deterministic

Tests don't depend on timing, real files, or external services. All assertions check synchronous state after synchronous key handler calls.
