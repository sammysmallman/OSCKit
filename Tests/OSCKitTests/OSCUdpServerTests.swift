//
//  OSCUdpServerTests.swift
//  OSCKitTests
//
//  Created by Sam Smallman on 19/02/2021.
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

class OSCUdpServerTests: XCTestCase {
    
    let server = OSCUdpServer(port: 3001)

    func testServerCanReceivePacket() throws {
        let expectation = expectation(description: "OSC UDP Server Receives Packet")
        
        let message = try OSCMessage(with: "/osc/kit/test")
        let mock = MockUdpServerDelegate(
            didReceivePacketClosure: { server, packet, _, _ in
                guard server == self.server,
                      let packetMessage = packet as? OSCMessage,
                      packetMessage.data() == message.data()
                else { return }
                expectation.fulfill()
            }
        )
        server.delegate = mock
        
        try server.startListening()
        let client = OSCUdpClient(host: server.localHost!, port: 3001)
        try client.send(message)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
}
