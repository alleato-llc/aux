# CLAUDE.md — aux

## What This Is

A terminal music player (TUI) built on LibAVKit and Tint. Supports three modes: interactive library browser (directory), single-file playback, and STDIN piping.

## Build & Test

```bash
# Prerequisites
brew install ffmpeg

# Build
swift build

# Run
$(swift build --show-bin-path)/aux ~/Music

# Test
swift test
swift test --filter AuxBDDTests
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
│   ├── KeyHandler.swift       Key → state mutation dispatch table + AppControl protocol
│   ├── PlayerTheme.swift      Tint Theme conformance (purple/lavender palette)
│   ├── Models/
│   │   ├── Album.swift        Immutable album grouping with computed metadata
│   │   ├── LibraryIndex.swift Directory scanner — MetadataReader → [Album]
│   │   ├── PlayerState.swift  Central mutable state (selection, playback, search, UI)
│   │   ├── SampleBuffer.swift Thread-safe circular buffer for audio visualization
│   │   └── Track.swift        Single track with metadata from LibAVKit
│   └── Views/
│       ├── AppRenderer.swift          Top-level layout coordinator
│       ├── SidebarRenderer.swift      Album list (left pane)
│       ├── TrackListRenderer.swift    Track table (right pane)
│       ├── NowPlayingRenderer.swift   Playback status bar
│       ├── HelpOverlayRenderer.swift  Centered keyboard shortcut modal
│       ├── OscilloscopeRenderer.swift Braille waveform visualizer
│       └── SpectrumRenderer.swift     FFT spectrum visualizer (Accelerate)
└── AuxCLI/
    └── Aux.swift              Entry point — @main ParsableCommand, mode dispatch

Tests/auxTests/
├── Steps/                     Step definitions
│   ├── AuxTestContext.swift
│   ├── CommonSetupSteps.swift
│   ├── CommonActionSteps.swift
│   ├── BrowsingVerificationSteps.swift
│   ├── PlaybackVerificationSteps.swift
│   ├── SearchVerificationSteps.swift
│   ├── HelpVerificationSteps.swift
│   └── VisualizerVerificationSteps.swift
├── TestData.swift
└── AuxBDDTests.swift
```

## Key Conventions

- **Swift 6.2+, macOS 14.4+**
- **Renderers are pure functions**: `(state, area, theme, &buffer) -> Void` — no side effects, no state mutation
- **All state lives in `PlayerState`** — single source of truth, mutated only by `KeyHandler` on the main thread
- **`SampleBuffer` is the only cross-thread type** — `NSLock`-guarded circular buffer bridging audio tap → render thread
- **Dependencies**: LibAVKit (decoding, playback, metadata), Tint (TUI framework), ArgumentParser (CLI), PickleKit (BDD testing)
- **BDD tests** exercise the state machine via `KeyHandler.handle()` — see [docs/testing/BDD.md](docs/testing/BDD.md)

## Architecture

- **Data flow**: Key event → KeyHandler → PlayerState mutation → next render frame reads updated state
- **Rendering**: AppRenderer coordinates layout, delegates to SidebarRenderer, TrackListRenderer, NowPlayingRenderer, and visualizers
- **Visualizers**: OscilloscopeRenderer uses Braille Unicode (4x vertical resolution); SpectrumRenderer uses Accelerate FFT with logarithmic frequency bands
- **Playback**: AudioPlayer (LibAVKit) + AVAudioEngineOutput; `onSamples` tap feeds SampleBuffer; `onStateChange(.completed)` auto-advances tracks
- **Testability**: `AppControl` protocol abstracts `Application.quit()` for test doubles; `PlaybackStatus` enum tracks user-requested playback state for BDD assertions

## Documentation

| Document | Purpose |
|----------|---------|
| [docs/architecture.md](docs/architecture.md) | Full design document |
| [docs/testing/BDD.md](docs/testing/BDD.md) | BDD testing guide |
| [docs/testing/PHILOSOPHY.md](docs/testing/PHILOSOPHY.md) | Testing philosophy and layers |
| [docs/testing/CONVENTIONS.md](docs/testing/CONVENTIONS.md) | Testing conventions |
| [docs/testing/CI.md](docs/testing/CI.md) | CI configuration |
| [.claude/rules/bdd-conventions.md](.claude/rules/bdd-conventions.md) | BDD conventions for AI development |
