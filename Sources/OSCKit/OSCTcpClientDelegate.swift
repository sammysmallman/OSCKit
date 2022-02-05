//
//  OSCTcpClientDelegate.swift
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

public protocol OSCTcpClientDelegate: AnyObject {

    /// Tells the delegate that the client connected to a server.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - host: The host of the server that the client connected to.
    ///   - port: The port of the server that the client connected to.
    func client(_ client: OSCTcpClient,
                didConnectTo host: String,
                port: UInt16)

    /// Tells the delegate that the client disconnected from a server.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - error: An optional error the clients socket disconnected with.
    func client(_ client: OSCTcpClient,
                didDisconnectWith error: Error?)

    /// Tells the delegate that the client sent an `OSCPacket`.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - packet: The `OSCPacket` that was sent.
    func client(_ client: OSCTcpClient,
                didSendPacket packet: OSCPacket)

    /// Tells the delegate the clent received an `OSCPacket`.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - packet: The packet that was received.
    func client(_ client: OSCTcpClient,
                didReceivePacket packet: OSCPacket)

    /// Tells the delegate the clent received data but could not parse it as an `OSCPacket`.
    /// - Parameters:
    ///   - client: The client that sent the message.
    ///   - data: The data that was read.
    ///   - error: The error that occured when reading the data.
    func client(_ client: OSCTcpClient,
                didReadData data: Data,
                with error: Error)

}
