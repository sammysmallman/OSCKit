import XCTest
@testable import OSCKit

final class OSCAddressSpaceTests: XCTestCase {
    
    func testPatternMatching() {

        var addressMethodA = false
        var addressMethodB = false
        
        let addressSpace = OSCAddressSpace()
        let abc = OSCAddressMethod(with: "/a/b/c", andCompletionHandler: { _ in })
        addressSpace.methods.insert(abc)
        let ab_d__ = OSCAddressMethod(with: "/a/b/*/d/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab_d__)
        let ab_de__ = OSCAddressMethod(with: "/a/b/*/d/e/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab_de__)
        let ab_de = OSCAddressMethod(with: "/a/b/*/d/e", andCompletionHandler: { _ in addressMethodA = true }) // <--- Address Method A
        addressSpace.methods.insert(ab_de)
        let ab__ef__ = OSCAddressMethod(with: "/a/b/*/*/e/f/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__ef__)
        let ab__exg__ = OSCAddressMethod(with: "/a/b/*/*/e/x/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__exg__)
        let ab__eyg__ = OSCAddressMethod(with: "/a/b/*/*/e/y/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__eyg__)
        let ab__ezg__ = OSCAddressMethod(with: "/a/b/*/*/e/z/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__ezg__)
        let ab__e = OSCAddressMethod(with: "/a/b/*/*/e", andCompletionHandler: { _ in addressMethodB = true }) // <--- Address Method B
        addressSpace.methods.insert(ab__e)
        let ab___f__ = OSCAddressMethod(with: "/a/b/*/*/*/f/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___f__)
        let ab___xg__ = OSCAddressMethod(with: "/a/b/*/*/*/x/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___xg__)
        let ab___yg__ = OSCAddressMethod(with: "/a/b/*/*/*/y/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___yg__)
        let ab___zg__ = OSCAddressMethod(with: "/a/b/*/*/*/z/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___zg__)
        
        addressSpace.complete(with: OSCMessage(with: "/a/b/x/d/e", arguments: []), priority: .string)
        XCTAssertTrue(addressMethodA)
        
        addressSpace.complete(with: OSCMessage(with: "/a/b/x/d/e", arguments: []), priority: .wildcard)
        XCTAssertTrue(addressMethodB)
        
    }

    static var allTests = [
        ("testPatternMatching", testPatternMatching),
    ]
}
