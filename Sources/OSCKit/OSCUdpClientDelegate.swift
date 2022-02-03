//
//  OSCUdpClientDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 09/07/2021.
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

public protocol OSCUdpClientDelegate: AnyObject {

    /// Tells the delegate that the client sent an `OSCPacket`.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - packet: The `OSCPacket` that was sent.
    ///   - host: The host the packet was sent from.
    ///   - port: The port the packet was sent from.
    func client(_ client: OSCUdpClient,
                didSendPacket packet: OSCPacket,
                fromHost host: String?,
                port: UInt16?)

    /// Tells the delegate that the client did not send an `OSCPacket` after attempting to send one.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - packet: The `OSCPacket` that was attempted to be sent.
    ///   - host: The host the packet was attempted to be sent from.
    ///   - port: The port the packet was attempted to be sent from.
    ///   - error: The error for why the `OSCPacket` was not sent.
    func client(_ client: OSCUdpClient,
                didNotSendPacket packet: OSCPacket,
                fromHost host: String?,
                port: UInt16?,
                error: Error?)

    /// Tells the delegate that the clients socket cloed with an error.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - error: The error the clients socket closed with.
    func client(_ client: OSCUdpClient,
                socketDidCloseWithError error: Error)

}
