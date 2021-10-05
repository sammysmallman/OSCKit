//
//  OSCUdpClientDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 09/07/2021.
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
