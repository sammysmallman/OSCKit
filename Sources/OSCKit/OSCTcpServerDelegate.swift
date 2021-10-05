//
//  OSCTcpServerDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 10/07/2021.
//  Copyright © 2020 Sam Smallman. https://github.com/SammySmallman
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
