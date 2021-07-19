//
//  OSCTcpClientConfiguration.swift
//  OSCKit
//
//  Created by Sam Smallman on 25/06/2021.
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

/// A configuration object that defines the behavior of a TCP client.
public struct OSCTcpClientConfiguration: Hashable {

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the client will use the default interface.
    public let interface: String?

    /// The host of the server that the client should connect to.
    /// May be specified as a domain name (e.g. "google.com") or an IP address string (e.g. "192.168.1.16").
    /// You may also use the convenience strings of "loopback" or "localhost".
    public let host: String

    /// The port of the host the client should send packets to.
    public let port: UInt16

    /// The stream framing all OSCPackets will be encoded and decoded with by the client.
    ///
    /// There are two versions of OSC:
    /// - OSC 1.0 uses packet length headers.
    /// - OSC 1.1 uses the [SLIP protocol](http://www.rfc-editor.org/rfc/rfc1055.txt).
    public let streamFraming: OSCTcpStreamFraming

    /// A configuration object that defines the behavior of a TCP client.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - host: The host of the server that the client should connect to.
    ///   - port: The port of the host the client should send packets to.
    ///   - streamFraming: The stream framing all OSCPackets will be encoded and decoded with by the client.
    ///   OSC 1.0 uses packet length headers and OSC 1.1 uses the SLIP protocol.
    public init(interface: String? = nil,
                host: String,
                port: UInt16,
                streamFraming: OSCTcpStreamFraming) {
        self.interface = interface
        self.port = port
        self.host = host
        self.streamFraming = streamFraming
    }

}
