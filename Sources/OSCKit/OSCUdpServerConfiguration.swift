//
//  OSCUdpServerConfiguration.swift
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

/// A configuration object that defines the behavior of a UDP server.
@objc(OSCUdpServerConfiguration) public class OSCUdpServerConfiguration: NSObject, NSSecureCoding, Codable {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpServerConfiguration(\
        interface: \(String(describing: interface)), \
        port: \(port), \
        multicastGroups: Set(\(multicastGroups)))
        """
    }

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
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address
    ///   or nil if the server should listen on all interfaces.
    ///   - port: The port the server should listen for packets on.
    ///   - multicastGroups: A `Set` of  multicast groups that the server should join.
    public init(interface: String?,
                port: UInt16,
                multicastGroups: Set<String> = []) {
        self.interface = interface
        self.port = port
        self.multicastGroups = multicastGroups
    }

    // MARK: NSSecureCoding

    /// A Boolean value that indicates whether or not the class supports secure coding.
    ///
    /// NSSecureCoding is implemented to allow for this instance to be passed to a XPC Service.
    public static var supportsSecureCoding: Bool = true

    /// A key that defines the `interface` of an `OSCUdpServer`.
    private static let interfaceKey = "interfaceKey"

    /// A key that defines the `port` of an `OSCUdpServer`.
    private static let portKey = "portKey"

    /// A key that defines the `multicastGroups` of an `OSCUdpServer`.
    private static let multicastGroupsKey = "multicastGroupssKey"

    /// A configuration object that defines the behavior of a UDP server from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        guard let portData = coder.decodeObject(of: NSData.self, forKey: Self.portKey) as Data?,
              let multicastGroups = coder.decodeObject(forKey: Self.multicastGroupsKey) as? Set<String>
        else {
            return nil
        }
        self.interface = coder.decodeObject(of: NSString.self, forKey: Self.interfaceKey) as String?
        self.port = portData.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
        self.multicastGroups = multicastGroups
    }

    /// Encodes this instance using a given archiver.
    public func encode(with coder: NSCoder) {
        coder.encode(interface, forKey: Self.interfaceKey)
        // Port could potentially be encoded as an NSInteger...
        coder.encode(port.bigEndian.data, forKey: Self.portKey)
        coder.encode(multicastGroups, forKey: Self.multicastGroupsKey)
    }

}
