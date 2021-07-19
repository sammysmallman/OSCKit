import XCTest
@testable import OSCKit

final class OSCKitTests: XCTestCase {

    func testArguments() {

        let message = OSCMessage(with: "/osc/kit", arguments: [1,
                                                               3.142,
                                                               "hello world!",
                                                               Data(count: 2),
                                                               OSCArgument.oscTrue,
                                                               OSCArgument.oscFalse,
                                                               OSCArgument.oscNil,
                                                               OSCArgument.oscImpulse])

        XCTAssertEqual(message.arguments.count, 8)
        XCTAssertEqual(message.argumentTypes.count, 8)
        XCTAssertEqual(message.typeTagString, ",ifsbTFNI")

        XCTAssertEqual(message.argumentTypes[0], OSCArgument.oscInt)
        XCTAssertEqual(message.argumentTypes[1], OSCArgument.oscFloat)
        XCTAssertEqual(message.argumentTypes[2], OSCArgument.oscString)
        XCTAssertEqual(message.argumentTypes[3], OSCArgument.oscBlob)
        XCTAssertEqual(message.argumentTypes[4], OSCArgument.oscTrue)
        XCTAssertEqual(message.argumentTypes[5], OSCArgument.oscFalse)
        XCTAssertEqual(message.argumentTypes[6], OSCArgument.oscNil)
        XCTAssertEqual(message.argumentTypes[7], OSCArgument.oscImpulse)

    }

    static var allTests = [
        ("testArguments", testArguments)
    ]
}
