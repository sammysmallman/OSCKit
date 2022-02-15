//
//  OSCUdpServerDelegate.swift
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
//  along with this software. If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import CoreOSC

public protocol OSCUdpServerDelegate: AnyObject {

    /// Tells the delegate the server received an `OSCPacket`.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - packet: The packet that was received.
    ///   - host: The host that sent the packet.
    ///   - port: The port of the host that sent the packet.
    func server(_ server: OSCUdpServer,
                didReceivePacket packet: OSCPacket,
                fromHost host: String,
                port: UInt16)

    /// Tells the delegate that the servers socket closed.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - error: An optional error if the servers socket closed with one.
    func server(_ server: OSCUdpServer,
                socketDidCloseWithError error: Error?)

    /// Tells the delegate the server received data but could not parse it as an `OSCPacket`.
    /// - Parameters:
    ///   - server: The server that sent the message.
    ///   - data: The data that was read.
    ///   - error: The error that occured when reading the data.
    func server(_ server: OSCUdpServer,
                didReadData data: Data,
                with error: Error)

}
