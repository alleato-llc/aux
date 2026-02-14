# CI Configuration

## Requirements

### FFmpeg

FFmpeg is required for **compilation only**. The `AuxLib` target imports `LibAVKit`, which links against FFmpeg's C libraries. BDD tests exercise state management and key handling — they never open audio files or call FFmpeg at runtime.

```bash
# Install FFmpeg (macOS)
brew install ffmpeg
```

### No GUI Required

aux is a TUI application. There are no XCUITest targets or GUI test requirements. Tests run entirely in headless mode.

### No Database

aux has no persistence layer. Tests use in-memory state only.

## Running Tests

```bash
# Full test suite
swift test

# Parallel execution
swift test --parallel

# Filter to BDD tests only
swift test --filter AuxBDDTests

# Verbose output
swift test --verbose
```

## CI Pipeline Steps

1. Install FFmpeg (`brew install ffmpeg`)
2. Resolve dependencies (`swift package resolve`)
3. Build (`swift build`)
4. Test (`swift test --parallel`)

## Expected Behavior

- All BDD scenarios should pass on every run
- No flaky tests — all assertions are synchronous and deterministic
- No network access required during tests
- No audio hardware access required during tests
