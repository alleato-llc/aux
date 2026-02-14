import Foundation

/// Thread-safe circular buffer that stores the latest audio samples.
/// The audio tap writes into it; the oscilloscope reads during render.
public final class SampleBuffer: @unchecked Sendable {
    private var samples: [Float]
    private var writeIndex: Int = 0
    private let lock = NSLock()
    public let capacity: Int

    public init(capacity: Int = 2048) {
        self.capacity = capacity
        self.samples = [Float](repeating: 0, count: capacity)
    }

    /// Called from the audio tap thread.
    public func write(_ newSamples: [Float]) {
        lock.lock()
        defer { lock.unlock() }
        for sample in newSamples {
            samples[writeIndex] = sample
            writeIndex = (writeIndex + 1) % capacity
        }
    }

    /// Returns the most recent `count` samples in chronological order.
    public func read(count: Int) -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        let n = min(count, capacity)
        var result = [Float](repeating: 0, count: n)
        var readIndex = (writeIndex - n + capacity) % capacity
        for i in 0..<n {
            result[i] = samples[readIndex]
            readIndex = (readIndex + 1) % capacity
        }
        return result
    }
}
