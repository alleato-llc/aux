import Tint

public struct OscilloscopeRenderer {
    // Braille left-column dot bits for sub-positions 0–3 (top to bottom within a cell)
    private static let brailleDotBits: [UInt32] = [0x01, 0x02, 0x04, 0x40]
    private static let brailleBase: UInt32 = 0x2800

    /// Downsample raw samples to one signed peak per column.
    /// Takes the value with the largest absolute magnitude in each block.
    static func computePeaks(samples: [Float], columnCount: Int) -> [Float] {
        let blockSize = max(1, samples.count / columnCount)
        var peaks = [Float]()
        peaks.reserveCapacity(columnCount)

        for col in 0..<columnCount {
            let start = col * blockSize
            let end = min(start + blockSize, samples.count)
            guard start < end else {
                peaks.append(0)
                continue
            }
            var peak: Float = 0
            for i in start..<end {
                if abs(samples[i]) > abs(peak) {
                    peak = samples[i]
                }
            }
            peaks.append(peak)
        }
        return peaks
    }

    /// Compute auto-normalization gain from peaks.
    /// Scales so the loudest peak fills ~80% of half-height. Capped at 20x.
    static func computeGain(peaks: [Float]) -> Float {
        let maxAbs = peaks.max(by: { abs($0) < abs($1) }).map { abs($0) } ?? 0
        return maxAbs > 0.001 ? min(0.8 / maxAbs, 20.0) : 1.0
    }

    /// Map a peak value to a vertical braille level.
    /// +1.0 → level 0 (top), -1.0 → totalLevels-1 (bottom), 0.0 → midpoint.
    static func levelForPeak(_ peak: Float, gain: Float, totalLevels: Int) -> Int {
        let scaled = max(-1.0, min(1.0, peak * gain))
        let normalized = (1.0 - scaled) / 2.0
        return min(totalLevels - 1, Int(normalized * Float(totalLevels - 1)))
    }

    public static func render(
        sampleBuffer: SampleBuffer,
        area: Rect,
        theme: PlayerTheme,
        buffer: inout Buffer
    ) {
        guard !area.isEmpty else { return }

        let block = Block(
            title: "Scope",
            titleStyle: theme.title,
            borderStyle: .rounded,
            style: theme.border
        )
        block.render(area: area, buffer: &buffer)

        let inner = area.inner
        guard !inner.isEmpty, inner.height >= 1, inner.width >= 2 else { return }

        let allSamples = sampleBuffer.read(count: sampleBuffer.capacity)
        let peaks = computePeaks(samples: allSamples, columnCount: inner.width)
        let gain = computeGain(peaks: peaks)

        let waveStyle = theme.visualizer
        let totalLevels = inner.height * 4

        // Draw waveform with braille dots
        var prevLevel: Int? = nil
        for (col, peak) in peaks.enumerated() {
            let x = inner.x + col
            guard x < inner.right else { break }

            let level = levelForPeak(peak, gain: gain, totalLevels: totalLevels)

            // Collect all levels for this column (main point + gap fill)
            var levels = [level]
            if let pl = prevLevel, abs(pl - level) > 1 {
                let lo = min(pl, level) + 1
                let hi = max(pl, level)
                for fillLevel in lo..<hi {
                    levels.append(fillLevel)
                }
            }

            // Group by row and OR dot bits for multi-dot cells
            var rowBits: [Int: UInt32] = [:]
            for lvl in levels {
                let row = lvl / 4
                let sub = lvl % 4
                rowBits[row, default: 0] |= brailleDotBits[sub]
            }

            // Write braille characters
            for (row, bits) in rowBits {
                let y = inner.y + row
                guard y < inner.bottom else { continue }
                let value = brailleBase | bits
                if let scalar = Unicode.Scalar(value) {
                    buffer[x, y] = Cell(character: Character(scalar), style: waveStyle)
                }
            }

            prevLevel = level
        }
    }
}
