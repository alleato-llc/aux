import ArgumentParser
import Foundation
import LibAVKit

public func runStdinMode(format: String, volume: Float) throws {
    let player = AudioPlayer()

    do {
        try player.open(path: "pipe:0", inputFormat: format)
    } catch {
        print("Failed to open STDIN: \(error.localizedDescription)")
        throw ExitCode.failure
    }

    let duration = player.duration
    printHeader(
        title: nil,
        artist: nil,
        album: nil,
        codec: format.uppercased(),
        sampleRate: player.sampleRate,
        channels: player.channels,
        duration: duration
    )

    // Set up signal handling for Ctrl+C
    let sigSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    signal(SIGINT, SIG_IGN)
    sigSource.setEventHandler {
        print("\nStopping playback...")
        player.stop()
        exit(0)
    }
    sigSource.resume()

    player.volume = volume

    player.onStateChange = { state in
        if state == .completed {
            writeProgress(elapsed: duration, duration: duration)
            print("\nPlayback complete.")
            exit(0)
        }
    }

    player.onError = { error in
        print("\nPlayback error: \(error)")
        exit(1)
    }

    // Poll actual playback position on a timer
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: .milliseconds(250))
    timer.setEventHandler {
        writeProgress(elapsed: player.currentTime, duration: duration)
    }
    timer.resume()

    player.play()
    dispatchMain()
}
