//
//  OSCAddressMatchTests.swift
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
