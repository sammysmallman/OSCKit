import XCTest
@testable import OSCKit

final class OSCKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OSCKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
