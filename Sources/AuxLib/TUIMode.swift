import Foundation
import LibAVKit
import Tint

public func runTUIMode(directory: URL, volume: Float) {
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
