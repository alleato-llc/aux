# Swift Testing

Always use Swift Testing (`import Testing`) instead of XCTest. Never use `import XCTest`, `XCTestCase`, `XCTAssert*`, or `XCTFail`.

## Quick Reference

| XCTest | Swift Testing |
|--------|---------------|
| `import XCTest` | `import Testing` |
| `class FooTests: XCTestCase` | `@Suite struct FooTests` |
| `func testBar()` | `@Test func bar()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertTrue(x)` | `#expect(x)` |
| `XCTAssertNil(x)` | `#expect(x == nil)` |
| `XCTAssertThrowsError(try f())` | `#expect(throws: SomeError.self) { try f() }` |
| `XCTFail("msg")` | `Issue.record("msg")` |
| `setUpWithError()` | `init()` |

## Conventions

- Use `@Suite(.serialized)` when tests must run sequentially (e.g., BDD scenarios sharing state)
- Use `@Test(arguments:)` for parameterized tests
- Use `#expect()` for all assertions
- Use `#require()` when a failure should stop the test immediately (equivalent to `XCTUnwrap`)
