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
public struct OSCUdpServerConfiguration: Hashable {

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
    
}
