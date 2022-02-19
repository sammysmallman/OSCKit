//
//  MockUdpServerDelegate.swift
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

internal class MockUdpServerDelegate: OSCUdpServerDelegate {

    internal let didReceivePacketClosure: ((_ server: OSCUdpServer, _ packet: OSCPacket, _ host: String, _ port: UInt16) -> Void)?
    internal let socketDidCloseWithErrorClosure: ((_ server: OSCUdpServer, _ error: Error?) -> Void)?
    internal let didReadDataClosure: ((_ server: OSCUdpServer, _ data: Data, _ error: Error) -> Void)?
    
    internal init(
        didReceivePacketClosure: ((OSCUdpServer, OSCPacket, String, UInt16) -> Void)? = nil,
        socketDidCloseWithErrorClosure: ((OSCUdpServer, Error?) -> Void)? = nil,
        didReadDataClosure: ((OSCUdpServer, Data, Error) -> Void)? = nil
    ) {
        self.didReceivePacketClosure = didReceivePacketClosure
        self.socketDidCloseWithErrorClosure = socketDidCloseWithErrorClosure
        self.didReadDataClosure = didReadDataClosure
    }
    
    internal func server(_ server: OSCUdpServer, didReceivePacket packet: OSCPacket, fromHost host: String, port: UInt16) {
        guard let closure = didReceivePacketClosure else { return }
        closure(server, packet, host, port)
    }
    
    internal func server(_ server: OSCUdpServer, socketDidCloseWithError error: Error?) {
        guard let closure = socketDidCloseWithErrorClosure else { return }
        closure(server, error)
    }
    
    internal func server(_ server: OSCUdpServer, didReadData data: Data, with error: Error) {
        guard let closure = didReadDataClosure else { return }
        closure(server, data, error)
    }
    
}
