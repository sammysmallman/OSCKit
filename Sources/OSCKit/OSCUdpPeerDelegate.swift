//
//  OSCUdpPeerDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 08/09/2021.
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
