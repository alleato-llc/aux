# Architecture

## Overview

aux is a terminal music player with three operational modes:

- **TUI mode** — interactive library browser launched when given a directory
- **File mode** — single-file playback with progress display
- **STDIN mode** — pipe audio from another process with a format hint

The TUI is where the bulk of the architecture lives. It follows a unidirectional data flow: keyboard events mutate a central state object, which renderers read on each frame to produce terminal output.

## Dependencies

| Package | Role |
|---------|------|
| [LibAVKit](https://github.com/aalleato/libav-kit) | Audio decoding, playback, and metadata reading |
| [Tint](https://github.com/aalleato/tint) | Terminal UI framework — event loop, layout, widgets, styling |
| [ArgumentParser](https://github.com/apple/swift-argument-parser) | CLI argument parsing |
| [Accelerate](https://developer.apple.com/documentation/accelerate) | FFT for spectrum visualizer (system framework) |

**LibAVKit types used:** `AudioPlayer`, `AVAudioEngineOutput`, `Decoder`, `MetadataReader`, `AudioMetadata`, `AudioOutputFormat`, `DecoderError`

**Tint types used:** `Application`, `Theme`, `Rect`, `Buffer`, `Cell`, `Style`, `Layout`, `Block`, `ListWidget`, `Table`, `ProgressBar`, `Key`

### FFmpeg boundary

aux does **not** import or interact with FFmpeg directly. All audio operations go through LibAVKit's Swift API, which internally wraps FFmpeg's C libraries (`libavcodec`, `libavformat`, `libavutil`, `libswresample`) via its `CFFmpeg` system library target. The dependency chain is:

```
aux → LibAVKit → CFFmpeg → FFmpeg
```

This means aux has no `import CFFmpeg` statements, no C interop code, and no direct knowledge of FFmpeg data structures. The FFmpeg dependency is a transitive build-time requirement (FFmpeg must be installed for LibAVKit to compile) but is entirely encapsulated behind LibAVKit's public Swift types. If LibAVKit were reimplemented on a different audio backend, aux would require no source changes.

## Module Structure

```
Sources/aux/
├── Aux.swift                  @main entry point, mode dispatch
├── KeyHandler.swift           Key → state mutation dispatch table
├── PlayerTheme.swift          Tint Theme conformance (purple/lavender palette)
├── Models/
│   ├── Album.swift            Immutable album grouping
│   ├── Track.swift            Immutable track with metadata
│   ├── LibraryIndex.swift     Directory scanner → [Album]
│   ├── PlayerState.swift      Mutable UI + playback state
│   └── SampleBuffer.swift     Thread-safe circular buffer
└── Views/
    ├── AppRenderer.swift      Top-level layout coordinator
    ├── SidebarRenderer.swift  Album list (left pane)
    ├── TrackListRenderer.swift Track table (right pane)
    ├── NowPlayingRenderer.swift Playback status bar
    ├── HelpOverlayRenderer.swift Help modal overlay
    ├── OscilloscopeRenderer.swift Braille waveform
    └── SpectrumRenderer.swift FFT-based spectrum bars
```

## Data Flow

### Initialization (TUI mode)

```
Directory path
  │
  ▼
LibraryIndex.scan()
  │  Uses MetadataReader to read each audio file
  ▼
[Album]  (immutable library)
  │
  ▼
PlayerState(albums:, player:)
  │  Holds all mutable state
  │  Wires player.onStateChange → auto-advance on track completion
  │
  ▼
AVAudioEngineOutput.onSamples → SampleBuffer.write()
  │  Audio tap feeds circular buffer for visualizers
  │
  ▼
Application(theme:).run(render:, onKey:)
  │  Tint event loop starts
```

### Render Loop

Each frame, Tint calls the render closure with an area and buffer:

```
AppRenderer.render(state, area, theme, &buffer)
  │
  ├─ Layout: vertical split
  │   ├─ Main content (fill)
  │   │   ├─ SidebarRenderer   (20% width) — filtered album list
  │   │   └─ TrackListRenderer  (80% width) — tracks in selected album
  │   └─ Bottom panel (5 rows)
  │       ├─ Visualizer (40%)
  │       │   ├─ OscilloscopeRenderer  (if mode == .oscilloscope)
  │       │   └─ SpectrumRenderer      (if mode == .spectrum)
  │       └─ NowPlayingRenderer (60%) — status, progress bar, time
  │
  ├─ Search overlay (if state.isSearching) — input bar at bottom
  └─ Help overlay (if state.isShowingHelp) — centered modal
```

Renderers are pure functions. They read from `PlayerState` and write into `Buffer`. No state mutation occurs during rendering.

### Interaction Loop

```
Key event
  │
  ▼
KeyHandler.handle(key, state, app)
  │
  ├─ Help active?  → only ? and Escape handled
  ├─ Search active? → Escape/Enter/Tab/Backspace/char handled
  └─ Normal mode   → navigation, playback, visualizer, search, quit
  │
  ▼
PlayerState mutation
  │
  ▼
Next frame renders updated state
```

### Playback Loop

```
PlayerState.playTrack(track)
  │
  ├─ player.stop()
  ├─ player.open(url:)
  ├─ player.play()
  │
  ▼
AudioPlayer decode loop (background thread)
  │
  ├─ Decoded frames → AVAudioEngineOutput → speakers
  ├─ onSamples callback → SampleBuffer.write()  (for visualizers)
  └─ onStateChange(.completed) → PlayerState.nextTrack()
```

## Models

### Album

Immutable value type. Groups tracks by artist and album name.

- `displayName` — `"Artist - Album"`, used for sidebar labels and search filtering
- `formatDescription` — codec/bit-depth/sample-rate from the first track (e.g. `"FLAC 16-bit/44.1kHz"`)
- `totalDuration` — sum of all track durations

### Track

Immutable value type. Built from a file URL and `AudioMetadata` (LibAVKit). Falls back to filename for title, "Unknown Artist" / "Unknown Album" when metadata is missing.

### LibraryIndex

Static utility. Scans a directory tree for files matching audio extensions (`flac`, `alac`, `wav`, `aiff`, `aif`, `wv`, `mp3`, `m4a`, `aac`, `opus`, `ogg`), reads metadata with `MetadataReader`, groups into albums sorted alphabetically.

### PlayerState

Central mutable state object for the TUI. Holds:

- **Selection**: `selectedAlbumIndex`, `selectedTrackIndex`, `focus` (`.sidebar` / `.trackList`)
- **Search**: `searchQuery`, `isSearching`, `filteredAlbumIndices`
- **Scroll**: `sidebarHScroll`, `trackListHScroll`
- **Playback**: `player` (AudioPlayer), `currentTrack`, `playbackProgress`
- **Visualizer**: `visualizerMode` (`.oscilloscope` / `.spectrum`), `sampleBuffer`
- **UI**: `isShowingHelp`, `musicIconIndex` (animated icon cycling)

Navigation methods (`moveUp`, `moveDown`, `focusLeft`, `focusRight`) respect the current search filter. Playback methods (`playSelected`, `togglePlayPause`, `nextTrack`, `previousTrack`) delegate to `AudioPlayer`. On track completion, `nextTrack()` is called automatically.

### SampleBuffer

Thread-safe circular buffer (`NSLock`-guarded). The audio output tap writes samples at decode rate; visualizer renderers read the latest N samples at frame rate.

## Rendering

### Layout

AppRenderer uses Tint's `Layout` system to divide the terminal area:

```
┌─────────────────────────────────────────┐
│  Sidebar (20%)  │  Track List (fill)    │
│  Album list     │  Table + album info   │
│                 │                       │
├─────────────────┴───────────────────────┤
│  Visualizer (40%)  │  Now Playing (fill)│
│  Scope / Spectrum  │  Status + progress │
└─────────────────────────────────────────┘
```

### SidebarRenderer

Renders the album list as a `ListWidget`. Items show `"Artist - Album"` with a music note prefix when the album contains the currently playing track. Highlight symbol (`"> "`) appears only when the sidebar is focused. Respects horizontal scroll offset and search filter.

### TrackListRenderer

Renders an info line (track count, duration, year, genre, format) followed by a `Table` with columns for track number, title, and duration. The playing track gets an accent style and a `" ▶"` suffix. Highlight is visible only when the track list is focused.

### NowPlayingRenderer

Shows the playing track's title and artist, a `ProgressBar` for playback progress, and an elapsed/total time readout. Falls back to "No track playing" when idle.

### HelpOverlayRenderer

Centered modal with a dark purple background listing all keyboard shortcuts. Rendered on top of existing content when `state.isShowingHelp` is true.

## Visualizers

### Oscilloscope (OscilloscopeRenderer)

Draws a real-time waveform using **Unicode Braille characters**. Each Braille cell encodes a 2x4 dot grid, giving 4x vertical resolution compared to one character per row.

Algorithm:
1. Read samples from `SampleBuffer`
2. Downsample to display width using signed peak per column
3. Auto-normalize (scale so loudest peak fills ~80% of half-height, gain capped at 20x)
4. Map each peak to a vertical level across `height * 4` sub-positions
5. Set Braille dot bits for each column; fill gaps between adjacent columns for smooth lines

### Spectrum (SpectrumRenderer)

Draws a real-time frequency spectrum using FFT via the Accelerate framework.

Algorithm:
1. Read samples, round to power-of-2 length
2. Apply Hanning window (`vDSP_hann_window`)
3. Forward FFT (`vDSP_fft_zrip`) and compute magnitudes (`vDSP_zvabs`)
4. Group bins into bands using **logarithmic distribution** — more bands in low frequencies for perceptual balance
5. Auto-normalize so the loudest band fills full height
6. Draw bars using partial block characters (`▁▂▃▄▅▆▇█`) for 8 sub-levels per row

## Key Handling

`KeyHandler.handle` is a static dispatch function with three priority layers:

1. **Help overlay active** — only `?` and `Escape` pass through
2. **Search mode active** — captures all input for the search query
3. **Normal mode** — full keybinding table (vim-style navigation, playback controls, visualizer toggle, search entry)

All key handlers call methods on `PlayerState` or `Application`. No rendering logic lives in the key handler.

## Theme

`PlayerTheme` conforms to Tint's `Theme` protocol with a purple/lavender color scheme:

| Role | Color |
|------|-------|
| Primary text | `rgb(220, 210, 240)` — pale lavender |
| Secondary text | `rgb(150, 130, 180)` — muted purple |
| Accent | `rgb(180, 120, 255)` bold — bright purple |
| Highlight | white on `rgb(90, 40, 150)` bold — deep purple background |
| Border | `rgb(120, 90, 170)` |
| Status bar | `rgb(220, 210, 240)` on `rgb(40, 20, 60)` |
| Visualizer | `rgb(230, 180, 60)` — gold/amber |
| Error | `rgb(255, 100, 100)` bold — red |

## Threading

- **Main thread**: Tint event loop (rendering + key handling)
- **Audio decode thread**: LibAVKit's internal decode loop runs on a background queue
- **Audio tap**: `AVAudioEngineOutput.onSamples` fires on the audio thread; writes to `SampleBuffer` (NSLock-guarded)
- **Render thread reads** `SampleBuffer` and `PlayerState` — `PlayerState` is `@unchecked Sendable` (mutations happen only on the main thread via key handlers; reads during rendering are on the same thread)
