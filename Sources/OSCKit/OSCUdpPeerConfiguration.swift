//
//  OSCUdpPeerConfiguration.swift
//  OSCKit
//
//  Created by Sam Smallman on 08/09/2021.
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

/// A configuration object that defines the behavior of a UDP peer.
@objc(OSCUdpPeerConfiguration) public class OSCUdpPeerConfiguration: NSObject, NSSecureCoding, Codable {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpPeerConfiguration(\
        interface: \(String(describing: interface)), \
        port: \(port), \
        host: \(host), \
        hostPort: \(hostPort))
        """
    }

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the peer will use the default interface.
    public let interface: String?
    
    /// The port the peer should listen for packets on.
    public let port: UInt16

    /// The destination the peer should send UDP packets to.
    /// May be specified as a domain name (e.g. "google.com") or an IP address string (e.g. "192.168.1.16").
    /// You may also use the convenience strings of "loopback" or "localhost".
    public let host: String
    
    /// The port of the host the peer should send packets to.
    public let hostPort: UInt16
    
    /// A configuration object that defines the behavior of a UDP peer.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - port: The port the peer should listen for packets on.
    ///   - host: The destination the peer should send UDP packets to.
    ///   - hostPort: The port of the host the peer should send packets to.
    public init(interface: String? = nil, port: UInt16, host: String, hostPort: UInt16) {
        self.interface = interface
        self.port = port
        self.host = host
        self.hostPort = hostPort
    }

    // MARK: NSSecureCoding

    /// A Boolean value that indicates whether or not the class supports secure coding.
    ///
    /// NSSecureCoding is implemented to allow for this instance to be passed to a XPC Service.
    public static var supportsSecureCoding: Bool = true

    /// A key that defines the `interface` of an `OSCUdpPeer`.
    private static let interfaceKey = "interfaceKey"
    
    /// A key that defines the `port` of an `OSCUdpPeer`.
    private static let portKey = "portKey"

    /// A key that defines the `host` of an `OSCUdpPeer`.
    private static let hostKey = "hostKey"

    /// A key that defines the `hostPort` of an `OSCUdpPeer`.
    private static let hostPortKey = "hostPortKey"

    /// A configuration object that defines the behavior of a UDP peer from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        guard let portData = coder.decodeObject(of: NSData.self, forKey: Self.portKey) as Data?,
              let host = coder.decodeObject(of: NSString.self, forKey: Self.hostKey) as String?,
              let hostPortData = coder.decodeObject(of: NSData.self, forKey: Self.hostPortKey) as Data?
        else {
            return nil
        }
        self.interface = coder.decodeObject(of: NSString.self, forKey: Self.interfaceKey) as String?
        self.port = portData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        self.host = host
        self.hostPort = hostPortData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
    }

    /// Encodes this instance using a given archiver.
    public func encode(with coder: NSCoder) {
        coder.encode(interface, forKey: Self.interfaceKey)
        // Port could potentially be encoded as an NSInteger...
        coder.encode(port.bigEndian.data, forKey: Self.portKey)
        coder.encode(host, forKey: Self.hostKey)
        coder.encode(hostPort.bigEndian.data, forKey: Self.hostPortKey)
    }

}
