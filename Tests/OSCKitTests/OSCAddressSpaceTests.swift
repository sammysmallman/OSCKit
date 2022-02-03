//
//  OSCAddressSpaceTests.swift
//  OSCKitTests
//
//  Created by Sam Smallman on 03/02/2021.
//  Copyright © 2022 Sam Smallman. https://github.com/SammySmallman
//
// This file is part of CoreOSC
//
// CoreOSC is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// CoreOSC is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import XCTest
@testable import OSCKit

final class OSCAddressSpaceTests: XCTestCase {
    
    var addressMethodA: Bool = false
    var addressMethodB: Bool = false
    
    override func setUp() {
        addressMethodA = false
        addressMethodB = false
    }
    // A = "/a/b/*/d/e" B = "/a/b/*/*/e"
    
    func testPatternMatching1() {
        let addressSpace = space()
        let _ = addressSpace.complete(with: OSCMessage(with: "/a/b/x/d/e", arguments: []), priority: .string)
        XCTAssertTrue(addressMethodA)
        let _ = addressSpace.complete(with: OSCMessage(with: "/a/b/x/d/e", arguments: []), priority: .wildcard)
        XCTAssertTrue(addressMethodB)
    }
    
    func testPatternMatching2() {
        let addressSpace = space()
        let _ = addressSpace.complete(with: OSCMessage(with: "/a/b/x/y/e", arguments: []), priority: .string)
        XCTAssertTrue(addressMethodB)
        let _ = addressSpace.complete(with: OSCMessage(with: "/a/b/x/y/e", arguments: []), priority: .wildcard)
        XCTAssertTrue(addressMethodB)
    }
    
    private func space() -> OSCAddressSpace {
        let addressSpace = OSCAddressSpace()
        let abc = OSCAddressMethod(with: "/a/b/c", andCompletionHandler: { _ in })
        addressSpace.methods.insert(abc)
        let ab_d__ = OSCAddressMethod(with: "/a/b/*/d/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab_d__)
        let ab_de__ = OSCAddressMethod(with: "/a/b/*/d/e/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab_de__)
        let ab_de = OSCAddressMethod(with: "/a/b/*/d/e", andCompletionHandler: { _ in self.addressMethodA = true }) // <--- Address Method A
        addressSpace.methods.insert(ab_de)
        let ab__ef__ = OSCAddressMethod(with: "/a/b/*/*/e/f/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__ef__)
        let ab__exg__ = OSCAddressMethod(with: "/a/b/*/*/e/x/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__exg__)
        let ab__eyg__ = OSCAddressMethod(with: "/a/b/*/*/e/y/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__eyg__)
        let ab__ezg__ = OSCAddressMethod(with: "/a/b/*/*/e/z/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab__ezg__)
        let ab__e = OSCAddressMethod(with: "/a/b/*/*/e", andCompletionHandler: { _ in self.addressMethodB = true }) // <--- Address Method B
        addressSpace.methods.insert(ab__e)
        let ab___f__ = OSCAddressMethod(with: "/a/b/*/*/*/f/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___f__)
        let ab___xg__ = OSCAddressMethod(with: "/a/b/*/*/*/x/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___xg__)
        let ab___yg__ = OSCAddressMethod(with: "/a/b/*/*/*/y/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___yg__)
        let ab___zg__ = OSCAddressMethod(with: "/a/b/*/*/*/z/g/*/*", andCompletionHandler: { _ in  })
        addressSpace.methods.insert(ab___zg__)
        return addressSpace
    }

    static var allTests = [
        ("testPatternMatching1", testPatternMatching1),
        ("testPatternMatching2", testPatternMatching2),
    ]
}
