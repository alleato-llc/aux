# aux

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-orange.svg)](https://swift.org)
[![macOS 14.4+](https://img.shields.io/badge/macOS-14.4%2B-blue.svg)](https://www.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)

A terminal music player built on [LibAVKit](https://github.com/aalleato/libav-kit) and [Tint](https://github.com/aalleato/tint). Browse your library, play tracks, and watch real-time audio visualizations — all from the terminal.

## Requirements

- macOS 14.4+
- Swift 6.2+
- FFmpeg development libraries (`brew install ffmpeg`)

## Installation

```bash
git clone git@github.com:aalleato/aux.git
cd aux
swift build
```

The binary is at `$(swift build --show-bin-path)/aux`.

## Usage

### TUI mode

Point aux at a directory to launch the interactive browser:

```bash
aux ~/Music
```

The TUI scans for audio files recursively, groups them by album, and presents a two-pane browser with a sidebar (albums) and track list. A visualizer and now-playing bar sit at the bottom.

### File mode

Play a single file with metadata display and progress:

```bash
aux song.flac
aux --volume 0.5 song.mp3
```

### STDIN mode

Pipe audio through a decoder. Requires `--format` since the codec can't be detected from a pipe:

```bash
cat song.opus | aux --format opus -
ffmpeg -i input.wav -f flac - 2>/dev/null | aux --format flac -
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--volume` | 1.0 | Playback volume (0.0-1.0) |
| `--format` | - | Format hint for STDIN (`flac`, `mp3`, `opus`, etc.) |

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `j` / `k` | Move down / up |
| `h` / `l` | Focus sidebar / track list |
| `Tab` | Toggle focus |
| `Enter` | Select album / play track |
| `Space` / `p` | Play / pause |
| `n` / `b` | Next / previous track |
| `/` | Search albums |
| `c` | Clear filter |
| `v` | Cycle visualizer (oscilloscope / spectrum) |
| `Left` / `Right` | Scroll pane horizontally |
| `0` | Reset scroll |
| `?` | Toggle help overlay |
| `q` | Quit |

## Supported Formats

Lossless: FLAC, ALAC, WAV, AIFF, WavPack
Lossy: MP3, AAC, Opus, Vorbis

## Architecture

See [docs/architecture.md](docs/architecture.md) for a detailed design overview covering the rendering pipeline, data flow, models, and visualizer internals.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

Note: This project links against FFmpeg via LibAVKit, which is licensed under LGPL 2.1+ (or GPL depending on configuration). Ensure your FFmpeg build and usage comply with its license terms.
