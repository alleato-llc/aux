@testable import AuxLib
import Testing

@Suite struct SpectrumComputationTests {
    @Test func logBandsEmptyMagnitudes() {
        let result = SpectrumRenderer.logBands(magnitudes: [], bandCount: 4)
        #expect(result == [Float](repeating: 0, count: 4))
    }

    @Test func logBandsZeroBandCount() {
        let result = SpectrumRenderer.logBands(magnitudes: [1, 2, 3], bandCount: 0)
        #expect(result == [])
    }

    @Test func logBandsSingleBand() {
        let magnitudes: [Float] = [1.0, 2.0, 3.0, 4.0]
        let result = SpectrumRenderer.logBands(magnitudes: magnitudes, bandCount: 1)
        #expect(result.count == 1)
        // Single band covers all bins → average of all
        let expected: Float = (1.0 + 2.0 + 3.0 + 4.0) / 4.0
        #expect(abs(result[0] - expected) < 0.01)
    }

    @Test func logBandsOutputCount() {
        let magnitudes = [Float](repeating: 1.0, count: 64)
        let result = SpectrumRenderer.logBands(magnitudes: magnitudes, bandCount: 10)
        #expect(result.count == 10)
    }

    @Test func logBandsKnownInput() {
        // Energy concentrated in bin 0
        var magnitudes = [Float](repeating: 0, count: 32)
        magnitudes[0] = 10.0
        let result = SpectrumRenderer.logBands(magnitudes: magnitudes, bandCount: 4)
        // First band should capture the energy from bin 0
        #expect(result[0] > 0)
    }

    @Test func logBandsUniformInput() {
        let magnitudes = [Float](repeating: 1.0, count: 64)
        let result = SpectrumRenderer.logBands(magnitudes: magnitudes, bandCount: 8)
        // All bands should be approximately 1.0 since all magnitudes are equal
        for band in result {
            #expect(abs(band - 1.0) < 0.01)
        }
    }
}
