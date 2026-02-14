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
Sources/aux/
├── Aux.swift              Entry point — dispatches to file, STDIN, or TUI mode
├── FilePlayer.swift       File mode playback (AudioPlayer + MetadataReader)
├── StdinPlayer.swift      STDIN mode playback (AudioPlayer with pipe support)
├── ConsoleOutput.swift    Shared console helpers (printHeader, writeProgress, formatTime)
├── KeyHandler.swift        Keyboard event → state mutation mapping
├── PlayerTheme.swift       Color and style definitions (Tint Theme)
├── Models/
│   ├── Album.swift         Album grouping with computed metadata
│   ├── LibraryIndex.swift  Directory scanner — builds [Album] from a path
│   ├── PlayerState.swift   Mutable UI + playback state (single source of truth)
│   ├── SampleBuffer.swift  Thread-safe circular buffer for audio samples
│   └── Track.swift         Single track with metadata from LibAVKit
└── Views/
    ├── AppRenderer.swift          Top-level layout coordinator
    ├── SidebarRenderer.swift      Album list (left pane)
    ├── TrackListRenderer.swift    Track table (right pane)
    ├── NowPlayingRenderer.swift   Playback status bar
    ├── HelpOverlayRenderer.swift  Keyboard shortcut modal
    ├── OscilloscopeRenderer.swift Braille waveform visualizer
    └── SpectrumRenderer.swift     FFT-based spectrum visualizer
```

## Code Style

- **Swift 6.2** with strict concurrency. Mark shared mutable state as `@unchecked Sendable` only when guarded by a lock.
- Renderers are **pure functions**: `(state, area, theme, &buffer) -> Void`. No side effects, no state mutation.
- State mutations happen only in `PlayerState` methods, triggered by `KeyHandler`.
- Keep dependencies minimal. The only external packages are LibAVKit, Tint, and ArgumentParser.

## Making Changes

1. Fork the repo and create a branch from `main`.
2. Make your changes. Keep commits focused — one logical change per commit.
3. Verify the build: `swift build`
4. Test manually: `$(swift build --show-bin-path)/aux ~/Music` (or any directory with audio files).
5. Open a pull request against `main`.

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
