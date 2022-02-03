//
//  OSCTcpServerConfiguration.swift
//  OSCKit
//
//  Created by Sam Smallman on 25/06/2021.
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

/// A configuration object that defines the behavior of a TCP server.
@objc(OSCTcpServerConfiguration) public class OSCTcpServerConfiguration: NSObject, NSSecureCoding, Codable {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCTcpServerConfiguration(\
        interface: \(String(describing: interface)), \
        port: \(port), \
        streamFraming: \(streamFraming))
        """
    }

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the client will use the default interface.
    public let interface: String?

    /// The port the server accept new connections and listen for packets on.
    public let port: UInt16

    /// The stream framing all OSCPackets will be encoded and decoded with by the server.
    ///
    /// There are two versions of OSC:
    /// - OSC 1.0 uses packet length headers.
    /// - OSC 1.1 uses the [SLIP protocol](http://www.rfc-editor.org/rfc/rfc1055.txt).
    public let streamFraming: OSCTcpStreamFraming

    /// A configuration object that defines the behavior of a TCP server.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - port: The port the server should listen for packets on.
    ///   - streamFraming: The stream framing all OSCPackets will be encoded and decoded with by the server.
    ///                    OSC 1.0 uses packet length headers and OSC 1.1 uses the SLIP protocol.
    public init(interface: String? = nil,
                port: UInt16,
                streamFraming: OSCTcpStreamFraming) {
        self.interface = interface
        self.port = port
        self.streamFraming = streamFraming
    }

    // MARK: NSSecureCoding

    /// A Boolean value that indicates whether or not the class supports secure coding.
    ///
    /// NSSecureCoding is implemented to allow for this instance to be passed to a XPC Service.
    public static var supportsSecureCoding: Bool = true

    /// A key that defines the `interface` of an `OSCTcpServer`.
    private static let interfaceKey = "interfaceKey"

    /// A key that defines the `port` of an `OSCTcpServer`.
    private static let portKey = "portKey"

    /// A key that defines the `streamFraming` of an `OSCTcpServer`.
    private static let streamFramingKey = "streamFramingKey"

    /// A configuration object that defines the behavior of a TCP server from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        guard let portData = coder.decodeObject(of: NSData.self, forKey: Self.portKey) as Data?,
              let streamFraming = OSCTcpStreamFraming(rawValue: coder.decodeInteger(forKey: Self.streamFramingKey))
        else {
            return nil
        }
        self.interface = coder.decodeObject(of: NSString.self, forKey: Self.interfaceKey) as String?
        self.port = portData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        self.streamFraming = streamFraming
    }

    /// Encodes this instance using a given archiver.
    public func encode(with coder: NSCoder) {
        coder.encode(interface, forKey: Self.interfaceKey)
        // Port could potentially be encoded as an NSInteger...
        coder.encode(port.bigEndian.data, forKey: Self.portKey)
        coder.encode(streamFraming.rawValue, forKey: Self.streamFramingKey)
    }

}
