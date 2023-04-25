//
//  OSCKitTests.swift
//  OSCKitTests
//
//  Created by Sam Smallman on 03/02/2021.
//  Copyright © 2022 Sam Smallman. https://github.com/SammySmallman
//
// This file is part of OSCKit
//
// OSCKit is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OSCKit is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this software. If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

import XCTest
@testable import OSCKit

class OSCKitTests: XCTestCase {

    func testVersion() {
        XCTAssertEqual(OSCKit.version, "3.2.0")
    }
    
    func testLicense() {
        let license = OSCKit.license
        XCTAssertTrue(license.hasPrefix("Copyright © 2022 Sam Smallman. https://github.com/SammySmallman"))
        XCTAssertTrue(license.hasSuffix("<https://www.gnu.org/licenses/why-not-lgpl.html>.\n"))
    }
    
    func testCoreOSCLicense() {
        let license = CoreOSC.license
        XCTAssertTrue(license.hasPrefix("Copyright © 2022 Sam Smallman. https://github.com/SammySmallman"))
        XCTAssertTrue(license.hasSuffix("<https://www.gnu.org/licenses/why-not-lgpl.html>.\n"))
    }
    
}
