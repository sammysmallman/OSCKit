//
//  OSCUdpServerConfiguration.swift
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

/// A configuration object that defines the behavior of a UDP server.
@objc(OSCUdpServerConfiguration) public class OSCUdpServerConfiguration: NSObject, NSSecureCoding, Codable, Identifiable {
    
    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpServerConfiguration(\
        id: \(id.uuidString), \
        interface: \(String(describing: interface)), \
        port: \(port), \
        multicastGroups: Set(\(multicastGroups)))
        """
    }
    
    /// A stable identity of this instance.
    public let id: UUID

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the server will listen on all interfaces.
    public let interface: String?

    /// The port the server should listen for packets on.
    public let port: UInt16

    /// A `Set` of  multicast groups that the server should join.
    /// A multiverse group should be an IP address in the range 224.0.0.0 through 239.255.255.255.
    public let multicastGroups: Set<String>

    /// A configuration object that defines the behavior of a UDP server.
    /// - Parameters:
    ///   - id: A stable identity for this instance.
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address
    ///   or nil if the server should listen on all interfaces.
    ///   - port: The port the server should listen for packets on.
    ///   - multicastGroups: A `Set` of  multicast groups that the server should join.
    public init(id: UUID = .init(),
                interface: String?,
                port: UInt16,
                multicastGroups: Set<String> = []) {
        self.id = id
        self.interface = interface
        self.port = port
        self.multicastGroups = multicastGroups
    }

    // MARK: NSSecureCoding

    /// A Boolean value that indicates whether or not the class supports secure coding.
    ///
    /// NSSecureCoding is implemented to allow for this instance to be passed to a XPC Service.
    public static var supportsSecureCoding: Bool = true

    /// A key that defines the `id` of an `OSCUdpServerConfiguration`.
    private static let idKey = "idKey"
    
    /// A key that defines the `interface` of an `OSCUdpServer`.
    private static let interfaceKey = "interfaceKey"

    /// A key that defines the `port` of an `OSCUdpServer`.
    private static let portKey = "portKey"

    /// A key that defines the `multicastGroups` of an `OSCUdpServer`.
    private static let multicastGroupsKey = "multicastGroupsKey"

    /// A configuration object that defines the behavior of a UDP server from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        guard let interface = coder.decodeObject(of: NSString.self, forKey: Self.interfaceKey) as? String,
              let portData = coder.decodeObject(of: NSData.self, forKey: Self.portKey) as? Data,
              let multicastGroups = coder.decodeObject(forKey: Self.multicastGroupsKey) as? Set<String>
        else {
            return nil
        }
        self.id = coder.decodeObject(of: NSUUID.self, forKey: Self.idKey) as? UUID ?? .init()
        self.interface = interface
        self.port = portData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        self.multicastGroups = multicastGroups
    }

    /// Encodes this instance using a given archiver.
    public func encode(with coder: NSCoder) {
        coder.encode(id, forKey: Self.idKey)
        coder.encode(interface, forKey: Self.interfaceKey)
        // Port could potentially be encoded as an NSInteger...
        coder.encode(port.bigEndian.data, forKey: Self.portKey)
        coder.encode(multicastGroups, forKey: Self.multicastGroupsKey)
    }

}
