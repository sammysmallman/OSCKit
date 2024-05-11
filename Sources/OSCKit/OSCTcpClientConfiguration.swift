//
//  OSCTcpClientConfiguration.swift
//  OSCKit
//
//  Created by Sam Smallman on 25/06/2021.
//  Copyright © 2021 Sam Smallman. https://github.com/SammySmallman
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

/// A configuration object that defines the behavior of a TCP client.
@objc(OSCTcpClientConfiguration) public class OSCTcpClientConfiguration: NSObject, NSSecureCoding, Codable, Identifiable {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCTcpClientConfiguration(\
        id: \(id.uuidString), \
        interface: \(String(describing: interface)), \
        host: \(host), \
        port: \(port), \
        streamFraming: \(streamFraming))
        """
    }
    
    /// A stable identity of this instance.
    public let id: UUID

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
    ///   - id: A stable identity for this instance.
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - host: The host of the server that the client should connect to.
    ///   - port: The port of the host the client should send packets to.
    ///   - streamFraming: The stream framing all OSCPackets will be encoded and decoded with by the client.
    ///   OSC 1.0 uses packet length headers and OSC 1.1 uses the SLIP protocol.
    public init(id: UUID = .init(),
                interface: String? = nil,
                host: String,
                port: UInt16,
                streamFraming: OSCTcpStreamFraming) {
        self.id = id
        self.interface = interface
        self.port = port
        self.host = host
        self.streamFraming = streamFraming
    }

    // MARK: NSSecureCoding

    /// A Boolean value that indicates whether or not the class supports secure coding.
    ///
    /// NSSecureCoding is implemented to allow for this instance to be passed to a XPC Service.
    public static var supportsSecureCoding: Bool = true
    
    /// A key that defines the `id` of an `OSCTcpClientConfiguration`.
    private static let idKey = "idKey"

    /// A key that defines the `interface` of an `OSCTcpClient`.
    private static let interfaceKey = "interfaceKey"

    /// A key that defines the `host` of an `OSCTcpClient`.
    private static let hostKey = "hostKey"

    /// A key that defines the `port` of an `OSCTcpClient`.
    private static let portKey = "portKey"

    /// A key that defines the `streamFraming` of an `OSCTcpClient`.
    private static let streamFramingKey = "streamFramingKey"

    /// A configuration object that defines the behavior of a TCP server from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        guard let interface = coder.decodeObject(of: NSString.self, forKey: Self.interfaceKey) as? String,
              let host = coder.decodeObject(of: NSString.self, forKey: Self.hostKey) as? String,
              let portData = coder.decodeObject(of: NSData.self, forKey: Self.portKey) as? Data,
              let streamFraming = OSCTcpStreamFraming(rawValue: coder.decodeInteger(forKey: Self.streamFramingKey))
        else {
            return nil
        }
        self.id = coder.decodeObject(of: NSUUID.self, forKey: Self.idKey) as? UUID ?? .init()
        self.interface = interface
        self.host = host
        self.port = portData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        self.streamFraming = streamFraming
    }

    /// Encodes this instance using a given archiver.
    public func encode(with coder: NSCoder) {
        coder.encode(id, forKey: Self.idKey)
        coder.encode(interface, forKey: Self.interfaceKey)
        coder.encode(host, forKey: Self.hostKey)
        // Port could potentially be encoded as an NSInteger...
        coder.encode(port.bigEndian.data, forKey: Self.portKey)
        coder.encode(streamFraming.rawValue, forKey: Self.streamFramingKey)
    }

}
