//
//  MockTcpClientDelegate.swift
//  OSCKitTests
//
//  Created by Sam Smallman on 19/02/2022.
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
//  along with this software. If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
@testable import OSCKit

internal class MockTcpClientDelegate: OSCTcpClientDelegate {

    internal let didConnectToClosure: ((_ client: OSCTcpClient, _ host: String, _ port: UInt16) -> Void)?
    internal let didDisconnectWithClosure: ((_ client: OSCTcpClient, _ error: Error?) -> Void)?
    internal let didSendPacketClosure: ((_ client: OSCTcpClient, _ packet: OSCPacket) -> Void)?
    internal let didReceivePacketClosure: ((_ client: OSCTcpClient, _ packet: OSCPacket) -> Void)?
    internal let didReadDataClosure: ((_ client: OSCTcpClient, _ data: Data, _ error: Error) -> Void)?
    
    internal init(
        didConnectToClosure: ((OSCTcpClient, String, UInt16) -> Void)? = nil,
        didDisconnectWithClosure: ((OSCTcpClient, Error?) -> Void)? = nil,
        didSendPacketClosure: ((OSCTcpClient, OSCPacket) -> Void)? = nil,
        didReceivePacketClosure: ((OSCTcpClient, OSCPacket) -> Void)? = nil,
        didReadDataClosure: ((OSCTcpClient, Data, Error) -> Void)? = nil
    ) {
        self.didConnectToClosure = didConnectToClosure
        self.didDisconnectWithClosure = didDisconnectWithClosure
        self.didSendPacketClosure = didSendPacketClosure
        self.didReceivePacketClosure = didReceivePacketClosure
        self.didReadDataClosure = didReadDataClosure
    }
    
    internal func client(_ client: OSCTcpClient, didConnectTo host: String, port: UInt16) {
        guard let closure = didConnectToClosure else { return }
        closure(client, host, port)
    }
    
    internal func client(_ client: OSCTcpClient, didDisconnectWith error: Error?) {
        guard let closure = didDisconnectWithClosure else { return }
        closure(client, error)
    }
    
    internal func client(_ client: OSCTcpClient, didSendPacket packet: OSCPacket) {
        guard let closure = didSendPacketClosure else { return }
        closure(client, packet)
    }
    
    internal func client(_ client: OSCTcpClient, didReceivePacket packet: OSCPacket) {
        guard let closure = didReceivePacketClosure else { return }
        closure(client, packet)
    }
    
    internal func client(_ client: OSCTcpClient, didReadData data: Data, with error: Error) {
        guard let closure = didReadDataClosure else { return }
        closure(client, data, error)
    }
    
}
