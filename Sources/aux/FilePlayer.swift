import ArgumentParser
import Foundation
import LibAVKit

func runFileMode(path: String, volume: Float) throws {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
        print("File not found: \(path)")
        throw ExitCode.failure
    }

    let player = AudioPlayer()

    // Set up signal handling for Ctrl+C
    let sigSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    signal(SIGINT, SIG_IGN)
    sigSource.setEventHandler {
        print("\nStopping playback...")
        player.stop()
        Aux.exit()
    }
    sigSource.resume()

    do {
        try player.open(url: url)
    } catch {
        print("Failed to open file: \(error.localizedDescription)")
        throw ExitCode.failure
    }

    // Read metadata separately for header display
    let metadata = (try? MetadataReader().read(url: url)) ?? .empty

    player.volume = volume
    let duration = player.duration
    printHeader(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        codec: metadata.codec,
        sampleRate: player.sampleRate,
        channels: player.channels,
        duration: duration
    )

    player.onStateChange = { state in
        if state == .completed {
            writeProgress(elapsed: duration, duration: duration)
            print("\nPlayback complete.")
            Aux.exit()
        }
    }

    player.onError = { error in
        print("\nPlayback error: \(error)")
        Aux.exit(withError: ExitCode.failure)
    }

    // Poll actual playback position on a timer instead of using onProgress,
    // which fires during the decode loop (much faster than real-time).
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: .milliseconds(250))
    timer.setEventHandler {
        writeProgress(elapsed: player.currentTime, duration: duration)
    }
    timer.resume()

    player.play()
    dispatchMain()
}
