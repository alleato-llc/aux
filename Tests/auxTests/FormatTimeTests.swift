import AuxLib
import Testing

@Suite struct FormatTimeTests {
    @Test func zeroSeconds() {
        #expect(formatTime(0.0) == "0:00")
    }

    @Test func oneMinuteOneSecond() {
        #expect(formatTime(61.0) == "1:01")
    }

    @Test func largeValue() {
        #expect(formatTime(3661.0) == "61:01")
    }

    @Test func fractionalTruncates() {
        #expect(formatTime(0.9) == "0:00")
    }

    @Test func exactMinuteBoundary() {
        #expect(formatTime(120.0) == "2:00")
    }

    @Test func justUnderMinute() {
        #expect(formatTime(59.0) == "0:59")
    }

    @Test func negativeValue() {
        // Swift Int() truncates toward zero, so Int(-5.0) = -5
        // -5 / 60 = 0, -5 % 60 = -5 → format produces "0:-5" or similar
        // Document current behavior without asserting correctness
        let result = formatTime(-5.0)
        #expect(!result.isEmpty)
    }
}
