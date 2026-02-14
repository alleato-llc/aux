@testable import AuxLib
import Testing

@Suite struct OscilloscopeComputationTests {
    // MARK: - computePeaks

    @Test func computePeaksDownsamples() {
        // 8 samples, 2 columns → each column picks signed peak of 4 samples
        let samples: [Float] = [0.1, -0.5, 0.3, 0.2, 0.4, 0.1, -0.8, 0.2]
        let peaks = OscilloscopeRenderer.computePeaks(samples: samples, columnCount: 2)
        #expect(peaks.count == 2)
        #expect(peaks[0] == -0.5)  // max abs in [0.1, -0.5, 0.3, 0.2]
        #expect(peaks[1] == -0.8)  // max abs in [0.4, 0.1, -0.8, 0.2]
    }

    @Test func computePeaksAllZeros() {
        let samples = [Float](repeating: 0, count: 8)
        let peaks = OscilloscopeRenderer.computePeaks(samples: samples, columnCount: 4)
        #expect(peaks == [0, 0, 0, 0])
    }

    @Test func computePeaksNegativePeak() {
        let samples: [Float] = [0.1, -0.9, 0.3, 0.4]
        let peaks = OscilloscopeRenderer.computePeaks(samples: samples, columnCount: 1)
        #expect(peaks.count == 1)
        #expect(peaks[0] == -0.9)  // Preserves sign of largest absolute value
    }

    // MARK: - computeGain

    @Test func computeGainNormalInput() {
        let peaks: [Float] = [0.2, -0.5, 0.3]
        let gain = OscilloscopeRenderer.computeGain(peaks: peaks)
        // maxAbs = 0.5, gain = 0.8 / 0.5 = 1.6
        #expect(gain == 1.6)
    }

    @Test func computeGainNearSilence() {
        let peaks: [Float] = [0.0001, -0.0001, 0.0005]
        let gain = OscilloscopeRenderer.computeGain(peaks: peaks)
        // maxAbs = 0.0005 < 0.001 → gain = 1.0
        #expect(gain == 1.0)
    }

    @Test func computeGainCapped() {
        let peaks: [Float] = [0.01, -0.005]
        let gain = OscilloscopeRenderer.computeGain(peaks: peaks)
        // maxAbs = 0.01, 0.8 / 0.01 = 80 → capped at 20.0
        #expect(gain == 20.0)
    }

    // MARK: - levelForPeak

    @Test func levelForPeakCenter() {
        // peak 0.0, gain 1.0, totalLevels 20 → midpoint
        let level = OscilloscopeRenderer.levelForPeak(0.0, gain: 1.0, totalLevels: 20)
        // normalized = (1.0 - 0.0) / 2.0 = 0.5 → level = min(19, Int(0.5 * 19)) = 9
        #expect(level == 9)
    }

    @Test func levelForPeakPositiveOne() {
        // peak +1.0, gain 1.0 → level 0 (top)
        let level = OscilloscopeRenderer.levelForPeak(1.0, gain: 1.0, totalLevels: 20)
        #expect(level == 0)
    }

    @Test func levelForPeakNegativeOne() {
        // peak -1.0, gain 1.0 → level totalLevels-1 (bottom)
        let level = OscilloscopeRenderer.levelForPeak(-1.0, gain: 1.0, totalLevels: 20)
        #expect(level == 19)
    }

    @Test func levelForPeakClamps() {
        // peak 2.0, gain 1.0 → clamped to +1.0 → level 0
        let level = OscilloscopeRenderer.levelForPeak(2.0, gain: 1.0, totalLevels: 20)
        #expect(level == 0)
    }
}
