//
//  MockTcpServerDelegate.swift
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

internal class MockTcpServerDelegate: OSCTcpServerDelegate {

    internal let didConnectToClientWithHostClosure: ((_ server: OSCTcpServer, _ host: String, _ port: UInt16) -> Void)?
    internal let didDisconnectFromClientWithHostClosure: ((_ server: OSCTcpServer, _ host: String, _ port: UInt16) -> Void)?
    internal let didReceivePacketClosure: ((_ server: OSCTcpServer, _ packet: OSCPacket, _ host: String, _ port: UInt16) -> Void)?
    internal let didSendPacketClosure: ((_ server: OSCTcpServer, _ packet: OSCPacket, _ host: String, _ port: UInt16) -> Void)?
    internal let socketDidCloseWithErrorClosure: ((_ server: OSCTcpServer, _ error: Error?) -> Void)?
    internal let didReadDataClosure: ((_ server: OSCTcpServer, _ data: Data, _ error: Error) -> Void)?
    
    internal init(
        didConnectToClientWithHostClosure: ((OSCTcpServer, String, UInt16) -> Void)? = nil,
        didDisconnectFromClientWithHostClosure: ((OSCTcpServer, String, UInt16) -> Void)? = nil,
        didReceivePacketClosure: ((OSCTcpServer, OSCPacket, String, UInt16) -> Void)? = nil,
        didSendPacketClosure: ((OSCTcpServer, OSCPacket, String, UInt16) -> Void)? = nil,
        socketDidCloseWithErrorClosure: ((OSCTcpServer, Error?) -> Void)? = nil,
        didReadDataClosure: ((OSCTcpServer, Data, Error) -> Void)? = nil
    ) {
        self.didConnectToClientWithHostClosure = didConnectToClientWithHostClosure
        self.didDisconnectFromClientWithHostClosure = didDisconnectFromClientWithHostClosure
        self.didReceivePacketClosure = didReceivePacketClosure
        self.didSendPacketClosure = didSendPacketClosure
        self.socketDidCloseWithErrorClosure = socketDidCloseWithErrorClosure
        self.didReadDataClosure = didReadDataClosure
    }
    
    internal func server(_ server: OSCTcpServer, didConnectToClientWithHost host: String, port: UInt16) {
        guard let closure = didConnectToClientWithHostClosure else { return }
        closure(server, host, port)
    }
    
    internal func server(_ server: OSCTcpServer, didDisconnectFromClientWithHost host: String, port: UInt16) {
        guard let closure = didDisconnectFromClientWithHostClosure else { return }
        closure(server, host, port)
    }
    
    internal func server(_ server: OSCTcpServer, didReceivePacket packet: OSCPacket, fromHost host: String, port: UInt16) {
        guard let closure = didReceivePacketClosure else { return }
        closure(server, packet, host, port)
    }
    
    internal func server(_ server: OSCTcpServer, didSendPacket packet: OSCPacket, toClientWithHost host: String, port: UInt16) {
        guard let closure = didSendPacketClosure else { return }
        closure(server, packet, host, port)
    }
    
    internal func server(_ server: OSCTcpServer, socketDidCloseWithError error: Error?) {
        guard let closure = socketDidCloseWithErrorClosure else { return }
        closure(server, error)
    }
    
    internal func server(_ server: OSCTcpServer, didReadData data: Data, with error: Error) {
        guard let closure = didReadDataClosure else { return }
        closure(server, data, error)
    }
    
}
