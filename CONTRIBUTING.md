# Contributing to aux

## Prerequisites

- macOS 14.4+
- Swift 6.2+ (Xcode 16+)
- FFmpeg development libraries:

```bash
brew install ffmpeg
```

## Building

```bash
swift build
```

The binary lands in `.build/debug/aux`. Run it with:

```bash
$(swift build --show-bin-path)/aux ~/Music
```

## Project Structure

```
Features/                      Gherkin feature files (project root)
├── library_browsing.feature
├── playback.feature
├── search.feature
├── help_overlay.feature
└── visualizer.feature

Sources/
├── AuxLib/                    Library target — all logic
│   ├── TUIMode.swift          TUI mode entry point
│   ├── FilePlayer.swift       File mode playback (AudioPlayer + MetadataReader)
│   ├── StdinPlayer.swift      STDIN mode playback (AudioPlayer with pipe support)
│   ├── ConsoleOutput.swift    Shared console helpers (printHeader, writeProgress, formatTime)
│   ├── KeyHandler.swift       Keyboard event → state mutation mapping + AppControl protocol
│   ├── PlayerTheme.swift      Color and style definitions (Tint Theme)
│   ├── Models/
│   │   ├── Album.swift        Album grouping with computed metadata
│   │   ├── LibraryIndex.swift Directory scanner — builds [Album] from a path
│   │   ├── PlayerState.swift  Mutable UI + playback state (single source of truth)
│   │   ├── SampleBuffer.swift Thread-safe circular buffer for audio samples
│   │   └── Track.swift        Single track with metadata from LibAVKit
│   └── Views/
│       ├── AppRenderer.swift          Top-level layout coordinator
│       ├── SidebarRenderer.swift      Album list (left pane)
│       ├── TrackListRenderer.swift    Track table (right pane)
│       ├── NowPlayingRenderer.swift   Playback status bar
│       ├── HelpOverlayRenderer.swift  Keyboard shortcut modal
│       ├── OscilloscopeRenderer.swift Braille waveform visualizer
│       └── SpectrumRenderer.swift     FFT-based spectrum visualizer
└── AuxCLI/
    └── Aux.swift              Entry point — @main ParsableCommand, mode dispatch
```

## Code Style

- **Swift 6.2** with strict concurrency. Mark shared mutable state as `@unchecked Sendable` only when guarded by a lock.
- Renderers are **pure functions**: `(state, area, theme, &buffer) -> Void`. No side effects, no state mutation.
- State mutations happen only in `PlayerState` methods, triggered by `KeyHandler`.
- Keep dependencies minimal. The only external packages are LibAVKit, Tint, and ArgumentParser.

## Test Requirements

All user-facing behavior changes must include [Cucumber](https://cucumber.io/docs/gherkin/) scenarios written in Gherkin, powered by [PickleKit](https://github.com/alleato-llc/pickle-kit). Feature files live in `Features/` at the project root.

### When to add scenarios

- **New feature** — Add scenarios covering the happy path and key edge cases.
- **Bug fix** — Add a scenario that reproduces the bug before fixing it.
- **Behavior change** — Update existing scenarios to reflect the new behavior.

### How to write them

Scenarios test the state machine, not rendering. Steps drive `KeyHandler.handle()` and assert on `PlayerState` properties:

```gherkin
Scenario: Search filters albums by name
  Given a library with 3 albums of 3 tracks each
  And I am in search mode
  When I type "Album 1"
  Then 1 album is visible
```

- **Given** steps describe state setup (library, focus, playback)
- **When** steps describe user actions (key presses, typing)
- **Then** steps assert on `PlayerState` properties

If your scenario needs new step definitions, add them to the appropriate file in `Tests/auxTests/Steps/`. See [docs/testing/BDD.md](docs/testing/BDD.md) for the full guide and [.claude/rules/bdd-conventions.md](.claude/rules/bdd-conventions.md) for conventions.

### Running tests

```bash
swift test                        # all tests
swift test --filter AuxBDDTests   # BDD scenarios only
PICKLE_REPORT=1 swift test        # generate HTML report
```

All scenarios must pass before a PR is merged.

## Making Changes

1. Fork the repo and create a branch from `main`.
2. Make your changes. Keep commits focused — one logical change per commit.
3. Verify the build: `swift build`
4. Add or update Cucumber scenarios for any behavior changes.
5. Verify tests pass: `swift test`
6. Open a pull request against `main`.

## Pull Request Guidelines

- Keep the PR title short and descriptive (under 70 characters).
- Describe what changed and why in the PR body.
- If you're adding a new feature, update the README and architecture docs as needed.
- If you're fixing a bug, describe the root cause and how the fix addresses it.

## Reporting Issues

Open an issue on GitHub with:

- Steps to reproduce
- Expected vs. actual behavior
- macOS version, Swift version, FFmpeg version (`ffmpeg -version`)
