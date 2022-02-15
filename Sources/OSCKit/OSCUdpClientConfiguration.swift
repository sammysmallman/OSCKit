//
//  OSCUdpClientConfiguration.swift
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
//  along with this software. If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

/// A configuration object that defines the behavior of a UDP client.
@objc(OSCUdpClientConfiguration) public class OSCUdpClientConfiguration: NSObject, NSSecureCoding, Codable {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpClientConfiguration(\
        interface: \(String(describing: interface)), \
        host: \(host), \
        port: \(port))
        """
    }

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the client will use the default interface.
    public let interface: String?

    /// The destination the client should send UDP packets to.
    /// May be specified as a domain name (e.g. "google.com") or an IP address string (e.g. "192.168.1.16").
    /// You may also use the convenience strings of "loopback" or "localhost".
    public let host: String

    /// The port of the host the client should send packets to.
    public let port: UInt16

    /// A configuration object that defines the behavior of a UDP client.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - host: The destination the client should send UDP packets to.
    ///   - port: The port of the host the client should send packets to.
    public init(interface: String? = nil, host: String, port: UInt16) {
        self.interface = interface
        self.host = host
        self.port = port
    }

    // MARK: NSSecureCoding

    /// A Boolean value that indicates whether or not the class supports secure coding.
    ///
    /// NSSecureCoding is implemented to allow for this instance to be passed to a XPC Service.
    public static var supportsSecureCoding: Bool = true

    /// A key that defines the `interface` of an `OSCUdpClient`.
    private static let interfaceKey = "interfaceKey"

    /// A key that defines the `host` of an `OSCUdpClient`.
    private static let hostKey = "hostKey"

    /// A key that defines the `port` of an `OSCUdpClient`.
    private static let portKey = "portKey"

    /// A configuration object that defines the behavior of a UDP client from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        guard let host = coder.decodeObject(of: NSString.self, forKey: Self.hostKey) as String?,
              let portData = coder.decodeObject(of: NSData.self, forKey: Self.portKey) as Data?
        else {
            return nil
        }
        self.interface = coder.decodeObject(of: NSString.self, forKey: Self.interfaceKey) as String?
        self.host = host
        self.port = portData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
    }

    /// Encodes this instance using a given archiver.
    public func encode(with coder: NSCoder) {
        coder.encode(interface, forKey: Self.interfaceKey)
        coder.encode(host, forKey: Self.hostKey)
        // Port could potentially be encoded as an NSInteger...
        coder.encode(port.bigEndian.data, forKey: Self.portKey)
    }

}
