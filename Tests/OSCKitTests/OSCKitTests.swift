//
//  OSCKitTests.swift
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
    
    func testVersion() {
        XCTAssertEqual(OSCKit.version, "2.2.0")
    }
    
    func testLicense() {
        let license = OSCKit.license
        XCTAssertTrue(license.hasPrefix("Copyright © 2022 Sam Smallman. https://github.com/SammySmallman"))
        XCTAssertTrue(license.hasSuffix("<https://www.gnu.org/licenses/why-not-lgpl.html>.\n"))
    }

    static var allTests = [
        ("testArguments", testArguments),
        ("testVersion", testVersion),
        ("testLicense", testLicense)
    ]
}
