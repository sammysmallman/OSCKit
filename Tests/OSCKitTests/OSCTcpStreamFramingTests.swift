//
//  OSCTcpStreamFramingTests.swift
//  OSCKitTests
//
//  Created by Sam Smallman on 09/08/2021.
//  Copyright © 2022 Sam Smallman. https://github.com/SammySmallman
//
//  This file is part of OSCKit
//
//  OSCKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OSCKit is distributed in the hope that it will be useful
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import XCTest
@testable import OSCKit

final class OSCTcpStreamFramingTests: XCTestCase {
    
    func testSLIP() {
        let slip: Int = 0
        let streamFraming = OSCTcpStreamFraming(rawValue: slip)
        
        XCTAssertNotNil(streamFraming)
        XCTAssertEqual(streamFraming, OSCTcpStreamFraming.SLIP)
    }
    
    
    func testPLH() {
        let plh: Int = 1
        let streamFraming = OSCTcpStreamFraming(rawValue: plh)
        
        XCTAssertNotNil(streamFraming)
        XCTAssertEqual(streamFraming, OSCTcpStreamFraming.PLH)
    }

}
