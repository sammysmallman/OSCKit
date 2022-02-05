//
//  OSCUdpPeerDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 08/09/2021.
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

import Foundation
import CoreOSC

public protocol OSCUdpPeerDelegate: AnyObject {

    /// Tells the delegate the peer received an `OSCPacket`.
    /// - Parameters:
    ///   - peer: The peer that sent the message.
    ///   - packet: The packet that was received.
    ///   - host: The host that sent the packet.
    ///   - port: The port of the host that sent the packet.
    func peer(_ peer: OSCUdpPeer,
              didReceivePacket packet: OSCPacket,
              fromHost host: String,
              port: UInt16)

    /// Tells the delegate the peer received data but could not parse it as an `OSCPacket`.
    /// - Parameters:
    ///   - peer: The peer that sent the message.
    ///   - data: The data that was read.
    ///   - error: The error that occured when reading the data.
    func peer(_ peer: OSCUdpPeer,
              didReadData data: Data,
              with error: Error)
    
    /// Tells the delegate that the peer sent an `OSCPacket`.
    /// - Parameters:
    ///   - peer: The peer that sent the message.
    ///   - packet: The `OSCPacket` that was sent.
    ///   - host: The host the packet was sent from.
    ///   - port: The port the packet was sent from.
    func peer(_ peer: OSCUdpPeer,
              didSendPacket packet: OSCPacket,
              fromHost host: String?,
              port: UInt16?)

    /// Tells the delegate that the peer did not send an `OSCPacket` after attempting to send one.
    /// - Parameters:
    ///   - peer: The peer that sent the message.
    ///   - packet: The `OSCPacket` that was attempted to be sent.
    ///   - host: The host the packet was attempted to be sent from.
    ///   - port: The port the packet was attempted to be sent from.
    ///   - error: The error for why the `OSCPacket` was not sent.
    func peer(_ peer: OSCUdpPeer,
              didNotSendPacket packet: OSCPacket,
              fromHost host: String?,
              port: UInt16?,
              error: Error?)

    /// Tells the delegate that the peers socket closed.
    /// - Parameters:
    ///   - peer: The peer that sent the message.
    ///   - error: An optional error if the peers socket closed with one.
    func peer(_ peer: OSCUdpPeer,
              socketDidCloseWithError error: Error?)

}
