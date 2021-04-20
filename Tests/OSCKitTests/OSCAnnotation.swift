import XCTest
@testable import OSCKit

final class OSCAnnotationTests: XCTestCase {
    
    func testMessageToAnnotationSpacesStyle() {
        let message = OSCMessage(with: "/an/address/pattern", arguments: [1, 3.142, "a string with spaces", "string", OSCArgument.oscTrue])
        let annotation = OSCAnnotation.annotation(for: message, with: .spaces, andType: true)
        XCTAssertEqual(annotation, "/an/address/pattern 1(i) 3.142(f) \"a string with spaces\"(s) string(s) true(T)")
    }
    
    func testMessageToAnnotationEqualsCommaStyle() {
        let message = OSCMessage(with: "/an/address/pattern", arguments: [1, 3.142, "a string with spaces", "string", OSCArgument.oscTrue])
        let annotation = OSCAnnotation.annotation(for: message, with: .equalsComma, andType: true)
        XCTAssertEqual(annotation, "/an/address/pattern=1(i),3.142(f),\"a string with spaces\"(s),string(s),true(T)")
    }
    
    func testAnnotationToMessageSpaceStyle() {
        let annotation = "/an/address/pattern 1 3.142 \"a string with spaces\" string true"
        XCTAssertTrue(OSCAnnotation.isValid(annotation: annotation, with: .spaces))
        let message = OSCAnnotation.oscMessage(for: annotation, with: .spaces)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.addressPattern, "/an/address/pattern")
        XCTAssertEqual(message?.arguments.count, 5)
        let argument1 = message?.arguments[0] as? Int32
        XCTAssertEqual(argument1, 1)
        let argument2 = message?.arguments[1] as? NSNumber
        XCTAssertEqual(argument2, 3.142)
        let argument3 = message?.arguments[2] as? String
        XCTAssertEqual(argument3, "a string with spaces")
        let argument4 = message?.arguments[3] as? String
        XCTAssertEqual(argument4, "string")
        let argument5 = message?.arguments[4] as? OSCArgument
        XCTAssertEqual(argument5, .oscTrue)
    }
    
    func testAnnotationToMessageEqualsCommaStyle() {
        let annotation = "/an/address/pattern=1,3.142,\"a string with spaces\",string,true"
        XCTAssertTrue(OSCAnnotation.isValid(annotation: annotation, with: .equalsComma))
        let message = OSCAnnotation.oscMessage(for: annotation, with: .equalsComma)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.addressPattern, "/an/address/pattern")
        XCTAssertEqual(message?.arguments.count, 5)
        let argument1 = message?.arguments[0] as? Int32
        XCTAssertEqual(argument1, 1)
        let argument2 = message?.arguments[1] as? NSNumber
        XCTAssertEqual(argument2, 3.142)
        let argument3 = message?.arguments[2] as? String
        XCTAssertEqual(argument3, "a string with spaces")
        let argument4 = message?.arguments[3] as? String
        XCTAssertEqual(argument4, "string")
        let argument5 = message?.arguments[4] as? OSCArgument
        XCTAssertEqual(argument5, .oscTrue)
    }
    
    func testAnnotationToMessageSpaceStyleSingleStringWithSpacesArgument() {
        let annotation = "/an/address/pattern \"this should be a single string argument\""
        XCTAssertTrue(OSCAnnotation.isValid(annotation: annotation, with: .spaces))
        let message = OSCAnnotation.oscMessage(for: annotation, with: .spaces)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.addressPattern, "/an/address/pattern")
        XCTAssertEqual(message?.arguments.count, 1)
        let argument = message?.arguments[0] as? String
        XCTAssertEqual(argument, "this should be a single string argument")
    }
    
    func testAnnotationToMessageEqualsCommaStyleSingleStringWithSpacesArgument() {
        let annotation = "/an/address/pattern=\"this should be a single string argument\""
        XCTAssertTrue(OSCAnnotation.isValid(annotation: annotation, with: .equalsComma))
        let message = OSCAnnotation.oscMessage(for: annotation, with: .equalsComma)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.addressPattern, "/an/address/pattern")
        XCTAssertEqual(message?.arguments.count, 1)
        let argument = message?.arguments[0] as? String
        XCTAssertEqual(argument, "this should be a single string argument")
    }
    
    static var allTests = [
        ("testMessageToAnnotationSpacesStyle", testMessageToAnnotationSpacesStyle),
        ("testMessageToAnnotationEqualsCommaStyle", testMessageToAnnotationEqualsCommaStyle),
        ("testAnnotationToMessageSpaceStyle", testAnnotationToMessageSpaceStyle),
        ("testAnnotationToMessageEqualsCommaStyle", testAnnotationToMessageEqualsCommaStyle),
        ("testAnnotationToMessageSpaceStyleSingleStringWithSpacesArgument", testAnnotationToMessageSpaceStyleSingleStringWithSpacesArgument),
        ("testAnnotationToMessageEqualsCommaStyleSingleStringWithSpacesArgument", testAnnotationToMessageEqualsCommaStyleSingleStringWithSpacesArgument),
    ]
    
}
