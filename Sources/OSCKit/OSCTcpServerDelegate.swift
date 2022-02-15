//
//  OSCTcpServerDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 10/07/2021.
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
import CoreOSC

public protocol OSCTcpServerDelegate: AnyObject {

    /// Tells the delegate the server accepted a new client connection.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - host: The host of the client that just connected.
    ///   - port: The port of the client that just connected.
    func server(_ server: OSCTcpServer,
                didConnectToClientWithHost host: String,
                port: UInt16)

    /// Tells the delegate the server disconnected from a client.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - host: The host of the client that just connected.
    ///   - port: The port of the client that just connected.
    func server(_ server: OSCTcpServer,
                didDisconnectFromClientWithHost host: String,
                port: UInt16)

    /// Tells the delegate the server received an `OSCPacket`.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - packet: The packet that was received.
    ///   - host: The host that sent the packet.
    ///   - port: The port the host sent the packet to.
    func server(_ server: OSCTcpServer,
                didReceivePacket packet: OSCPacket,
                fromHost host: String,
                port: UInt16)

    /// Tells the delegate that the server sent an `OSCPacket` to a client.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - packet: The `OSCPacket` that was sent.
    ///   - host: The host of the client the packet was sent to.
    ///   - port: The port of the host the packet was sent to.
    func server(_ server: OSCTcpServer,
                didSendPacket packet: OSCPacket,
                toClientWithHost host: String,
                port: UInt16)

    /// Tells the delegate that the servers socket closed.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - error: An optional error if the servers socket closed with one.
    func server(_ server: OSCTcpServer,
                socketDidCloseWithError error: Error?)

    /// Tells the delegate the server received data but could not parse it as an `OSCPacket`.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - data: The data that was read.
    ///   - error: The error that occured when reading the data.
    func server(_ server: OSCTcpServer,
                didReadData data: Data,
                with error: Error)

}
