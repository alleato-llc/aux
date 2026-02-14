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
```

## Project Structure

```
Sources/aux/
├── Aux.swift              Entry point — @main ParsableCommand, mode dispatch
├── KeyHandler.swift        Key → state mutation dispatch table
├── PlayerTheme.swift       Tint Theme conformance (purple/lavender palette)
├── Models/
│   ├── Album.swift         Immutable album grouping with computed metadata
│   ├── LibraryIndex.swift  Directory scanner — MetadataReader → [Album]
│   ├── PlayerState.swift   Central mutable state (selection, playback, search, UI)
│   ├── SampleBuffer.swift  Thread-safe circular buffer for audio visualization
│   └── Track.swift         Single track with metadata from LibAVKit
└── Views/
    ├── AppRenderer.swift          Top-level layout coordinator
    ├── SidebarRenderer.swift      Album list (left pane)
    ├── TrackListRenderer.swift    Track table (right pane)
    ├── NowPlayingRenderer.swift   Playback status bar
    ├── HelpOverlayRenderer.swift  Centered keyboard shortcut modal
    ├── OscilloscopeRenderer.swift Braille waveform visualizer
    └── SpectrumRenderer.swift     FFT spectrum visualizer (Accelerate)
```

## Key Conventions

- **Swift 6.2+, macOS 14.4+**
- **Renderers are pure functions**: `(state, area, theme, &buffer) -> Void` — no side effects, no state mutation
- **All state lives in `PlayerState`** — single source of truth, mutated only by `KeyHandler` on the main thread
- **`SampleBuffer` is the only cross-thread type** — `NSLock`-guarded circular buffer bridging audio tap → render thread
- **Dependencies**: LibAVKit (decoding, playback, metadata), Tint (TUI framework), ArgumentParser (CLI)
- **No test target yet** — verify manually with `aux <directory>`

## Architecture

- **Data flow**: Key event → KeyHandler → PlayerState mutation → next render frame reads updated state
- **Rendering**: AppRenderer coordinates layout, delegates to SidebarRenderer, TrackListRenderer, NowPlayingRenderer, and visualizers
- **Visualizers**: OscilloscopeRenderer uses Braille Unicode (4x vertical resolution); SpectrumRenderer uses Accelerate FFT with logarithmic frequency bands
- **Playback**: AudioPlayer (LibAVKit) + AVAudioEngineOutput; `onSamples` tap feeds SampleBuffer; `onStateChange(.completed)` auto-advances tracks

See [docs/architecture.md](docs/architecture.md) for the full design document.
