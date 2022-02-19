//
//  MockUdpPeerDelegate.swift
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

internal class MockUdpPeerDelegate: OSCUdpPeerDelegate {
    
    internal let didReceivePacketClosure: ((_ peer: OSCUdpPeer, _ packet: OSCPacket, _ host: String, _ port: UInt16) -> Void)?
    internal let didReadDataClosure: ((_ peer: OSCUdpPeer, _ data: Data, _ error: Error) -> Void)?
    internal let didSendPacketClosure: ((_ peer: OSCUdpPeer, _ packet: OSCPacket, _ host: String?, _ port: UInt16?) -> Void)?
    internal let didNotSendPacketClosure: ((_ peer: OSCUdpPeer, _ packet: OSCPacket, _ host: String?, _ port: UInt16?, _ error: Error?) -> Void)?
    internal let socketDidCloseWithErrorClosure: ((_ peer: OSCUdpPeer, _ error: Error?) -> Void)?
    
    internal init(
        didReceivePacketClosure: ((OSCUdpPeer, OSCPacket, String, UInt16) -> Void)?,
        didReadDataClosure: ((OSCUdpPeer, Data, Error) -> Void)?,
        didSendPacketClosure: ((OSCUdpPeer, OSCPacket, String?, UInt16?) -> Void)?,
        didNotSendPacketClosure: ((OSCUdpPeer, OSCPacket, String?, UInt16?, Error?) -> Void)?,
        socketDidCloseWithErrorClosure: ((OSCUdpPeer, Error?) -> Void)?
    ) {
        self.didReceivePacketClosure = didReceivePacketClosure
        self.didReadDataClosure = didReadDataClosure
        self.didSendPacketClosure = didSendPacketClosure
        self.didNotSendPacketClosure = didNotSendPacketClosure
        self.socketDidCloseWithErrorClosure = socketDidCloseWithErrorClosure
    }
    
    internal func peer(_ peer: OSCUdpPeer, didReceivePacket packet: OSCPacket, fromHost host: String, port: UInt16) {
        guard let closure = didReceivePacketClosure else { return }
        closure(peer, packet, host, port)
    }
    
    internal func peer(_ peer: OSCUdpPeer, didReadData data: Data, with error: Error) {
        guard let closure = didReadDataClosure else { return }
        closure(peer, data, error)
    }
    
    internal func peer(_ peer: OSCUdpPeer, didSendPacket packet: OSCPacket, fromHost host: String?, port: UInt16?) {
        guard let closure = didSendPacketClosure else { return }
        closure(peer, packet, host, port)
    }
    
    internal func peer(_ peer: OSCUdpPeer, didNotSendPacket packet: OSCPacket, fromHost host: String?, port: UInt16?, error: Error?) {
        guard let closure = didNotSendPacketClosure else { return }
        closure(peer, packet, host, port, error)
    }
    
    internal func peer(_ peer: OSCUdpPeer, socketDidCloseWithError error: Error?) {
        guard let closure = socketDidCloseWithErrorClosure else { return }
        closure(peer, error)
    }
    
}
