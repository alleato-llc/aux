import AuxLib
import Testing

@Suite struct SampleBufferTests {
    @Test func readFromFreshBuffer() {
        let buffer = SampleBuffer(capacity: 8)
        let result = buffer.read(count: 8)
        #expect(result == [Float](repeating: 0, count: 8))
    }

    @Test func writeFewerThanCapacity() {
        let buffer = SampleBuffer(capacity: 8)
        buffer.write([1, 2, 3])
        let result = buffer.read(count: 3)
        #expect(result == [1, 2, 3])
    }

    @Test func writeExactlyCapacity() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2, 3, 4])
        let result = buffer.read(count: 4)
        #expect(result == [1, 2, 3, 4])
    }

    @Test func writeMoreThanCapacityWraps() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2, 3, 4, 5, 6])
        let result = buffer.read(count: 4)
        #expect(result == [3, 4, 5, 6])
    }

    @Test func multipleWritesPreserveOrder() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2])
        buffer.write([3, 4])
        let result = buffer.read(count: 4)
        #expect(result == [1, 2, 3, 4])
    }

    @Test func readCountZero() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2, 3])
        let result = buffer.read(count: 0)
        #expect(result == [])
    }

    @Test func readExceedingCapacityClamped() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2, 3, 4])
        let result = buffer.read(count: 100)
        #expect(result.count == 4)
        #expect(result == [1, 2, 3, 4])
    }

    @Test func emptyWriteNoChange() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2])
        buffer.write([])
        let result = buffer.read(count: 4)
        // Most recent 4: 2 zeros (initial) + [1, 2]
        #expect(result == [0, 0, 1, 2])
    }

    @Test func wrapAroundMultipleTimes() {
        let buffer = SampleBuffer(capacity: 4)
        buffer.write([1, 2, 3, 4, 5])  // wraps once: [5, 2, 3, 4] → most recent 4: [2,3,4,5]
        buffer.write([6, 7, 8, 9, 10]) // wraps again
        let result = buffer.read(count: 4)
        #expect(result == [7, 8, 9, 10])
    }
}
