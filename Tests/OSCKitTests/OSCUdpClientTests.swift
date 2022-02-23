//
//  OSCUdpClientTests.swift
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

class OSCUdpClientTests: XCTestCase {
    
    func testClientCanSendPacket() throws {
        let testClient = OSCUdpClient(host: "192.168.1.101", port: 3001)
        
        let expectation = expectation(description: "OSC UDP Client Sends Packet")
        
        let message = try OSCMessage(with: "/osc/kit/test")
        
        let mock = MockUdpClientDelegate(
            didSendPacketClosure: { client, packet, host, port in
                guard client == testClient,
                      let packetMessage = packet as? OSCMessage,
                      packetMessage.data() == message.data()
                else { return }
                expectation.fulfill()
            }
        )
        testClient.delegate = mock
        
        try testClient.send(message)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testClientCanSendPacketWithDispatchQueue() throws {
        let queue = DispatchQueue(label: #function)
        let testClient = OSCUdpClient(host: "192.168.1.101", port: 3001, queue: queue)
        
        let expectation = expectation(description: "OSC UDP Client Sends Packet")
        
        let message = try OSCMessage(with: "/osc/kit/test")
        
        let mock = MockUdpClientDelegate(
            didSendPacketClosure: { client, packet, host, port in
                guard client == testClient,
                      let packetMessage = packet as? OSCMessage,
                      packetMessage.data() == message.data()
                else { return }
                expectation.fulfill()
            }
        )
        testClient.delegate = mock
        
        try testClient.send(message)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testConcurrency() throws {
        
        let queue = DispatchQueue(label: #function)
        
        let client = OSCUdpClient(host: "192.168.1.101", port: 3001, queue: queue)
        
        let message = try! OSCMessage(with: "/osc/kit/test")
        DispatchQueue.concurrentPerform(iterations: 1_000_000, execute: { _ in
            do {
                try client.send(message)
            } catch {
                fatalError()
            }
        })
    }
    
}
