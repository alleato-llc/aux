import ArgumentParser
import Foundation
import LibAVKit
import Tint

@main
struct Aux: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aux",
        abstract: "Play audio files using LibAVKit.",
        discussion: """
        File mode:  aux song.flac
        STDIN mode: cat song.flac | aux --format flac -
        TUI mode:   aux ~/Music
        """
    )

    @Argument(help: "Audio file path, or \"-\" to read from STDIN.")
    var file: String?

    @Option(help: "Playback volume (0.0–1.0).")
    var volume: Float = 1.0

    @Option(help: "Format hint for STDIN (e.g. flac, mp3, opus). Required when reading from STDIN.")
    var format: String?

    func run() throws {
        // Disable stdout buffering so \r progress updates appear immediately
        setbuf(stdout, nil)

        let isSTDIN = file == "-" || (file == nil && !isatty(STDIN_FILENO).boolValue)

        if isSTDIN {
            guard let format else {
                print("--format is required when reading from STDIN.")
                throw ExitCode.failure
            }
            try runStdinMode(format: format, volume: volume)
        } else if let file {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: file, isDirectory: &isDir), isDir.boolValue {
                runTUIMode(directory: URL(fileURLWithPath: file), volume: volume)
            } else {
                try runFileMode(path: file, volume: volume)
            }
        } else {
            print("No file specified. Use --help for usage.")
            throw ExitCode.failure
        }
    }
}

// MARK: - TUI Mode

private func runTUIMode(directory: URL, volume: Float) {
    print("Scanning library at \(directory.path)...")
    let albums = LibraryIndex.scan(directory: directory)
    guard !albums.isEmpty else {
        print("No audio files found in \(directory.path)")
        return
    }
    print("Found \(albums.count) album(s), \(albums.reduce(0) { $0 + $1.trackCount }) track(s). Launching TUI...")

    let theme = PlayerTheme()
    let output = AVAudioEngineOutput()
    let player = AudioPlayer(output: output)
    player.volume = volume
    let state = PlayerState(albums: albums, player: player)

    output.onSamples = { [weak state] samples in
        state?.sampleBuffer.write(samples)
    }

    let app = Application(theme: theme)

    app.run(render: { area, buffer in
        AppRenderer.render(state: state, area: area, theme: theme, buffer: &buffer)
    }, onKey: { key in
        KeyHandler.handle(key: key, state: state, app: app)
    })
}

private extension Int32 {
    var boolValue: Bool { self != 0 }
}
