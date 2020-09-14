import XCTest
@testable import OSCKit

final class OSCAddressMatchTests: XCTestCase {
    
    func testStringtMatching() {
        let method = OSCAddressMethod(with: "/a/b/c/d/e", andCompletionHandler: { message in print(message) })
        let match = method.match(part: "a", atIndex: 0)
        
        XCTAssertEqual(match, .string)
    }
    
    func testWildcardMatching() {
        let method = OSCAddressMethod(with: "/*/b/c/d/e", andCompletionHandler: { message in print(message) })
        let match = method.match(part: "a", atIndex: 0)
        
        XCTAssertEqual(match, .wildcard)
    }
    
    func testDifferentMatching() {
        let method = OSCAddressMethod(with: "/a/b/c/d/e", andCompletionHandler: { message in print(message) })
        let match = method.match(part: "e", atIndex: 0)
        
        XCTAssertEqual(match, .different)
    }
    
}
