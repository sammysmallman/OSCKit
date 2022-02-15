//
//  OSCUdpServer.swift
//  OSCKit
//
//  Created by Sam Smallman on 07/07/2021.
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
import CocoaAsyncSocket
import CoreOSC

/// An object that receives OSCPackets via UDP.
public class OSCUdpServer: NSObject {

    enum OSCUdpServerError: Error, CustomStringConvertible {
        case serverSocketIsNotBound
        case multicastGroupNotJoined

        public var description: String {
            switch self {
            case .serverSocketIsNotBound:
                return "The servers socket is not bound to a port. Try startListening() first."
            case .multicastGroupNotJoined:
                return "The server has not currently joined the given multicast group."
            }
        }
    }

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpServer(\
        interface: \(String(describing: interface)), \
        port: \(port), \
        multicastGroups: Set(\(multicastGroups)))
        """
    }

    /// A configuration object representing the current configurable state of the server.
    public var configuration: OSCUdpServerConfiguration {
        OSCUdpServerConfiguration(interface: interface,
                                  port: port,
                                  multicastGroups: multicastGroups)
    }

    /// The servers UDP socket that all OSCPackets are received from.
    private let socket: GCDAsyncUdpSocket

    /// A `Set` of multicast groups that should be joined automatically when the server starts listening.
    public var multicastGroups: Set<String>

    /// A `Set` of multicast groups that have been joined by the server.
    public var joinedMulticastGroups: Set<String> = []

    /// A boolean value that indicates whether the server is listening for OSC packets.
    public var isListening: Bool = false

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the server will listen on all interfaces.
    ///
    /// Setting this property will stop the server listening.
    public var interface: String? {
        didSet {
            stopListening()
        }
    }

    /// The host for the server.
    public var localHost: String? { socket.localHost() }

    /// The port the server should listen for packets on.
    ///
    /// Setting this property will stop the server listening.
    public var port: UInt16 {
        didSet {
            stopListening()
        }
    }

    /// A boolean value that indicates whether the servers socket has been enabled
    /// to allow for multiple processes to simultaneously bind to the same port.
    public var reusePort: Bool = false

    /// The dispatch queue that the server executes all delegate callbacks on.
    private let queue: DispatchQueue

    /// The servers delegate.
    ///
    /// The delegate must conform to the `OSCUdpServerDelegate` protocol.
    public weak var delegate: OSCUdpServerDelegate?

    /// An OSC UDP Server.
    /// - Parameters:
    ///   - configuration: A configuration object that defines the behavior of a UDP server.
    ///   - delegate: The servers delegate.
    ///   - queue: The dispatch queue that the server executes all delegate callbacks on.
    public init(configuration: OSCUdpServerConfiguration,
                delegate: OSCUdpServerDelegate? = nil,
                queue: DispatchQueue = .main) {
        socket = GCDAsyncUdpSocket()
        if configuration.interface?.isEmpty == false {
            interface = configuration.interface
        } else {
            interface = nil
        }
        port = configuration.port
        multicastGroups = configuration.multicastGroups
        self.delegate = delegate
        self.queue = queue
        super.init()
        socket.setDelegate(self, delegateQueue: queue)
    }

    /// An OSC UDP Server.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address
    ///                or nil if the server should listen on all interfaces.
    ///   - port: The port the server should listen for packets on.
    ///   - multicastGroups: A `Set` of  multicast groups that the server should join.
    ///   - delegate: The servers delegate.
    ///   - queue: The dispatch queue that the server executes all delegate callbacks on.
    public convenience init(interface: String? = nil,
                            port: UInt16,
                            multicastGroups: Set<String> = [],
                            delegate: OSCUdpServerDelegate? = nil,
                            queue: DispatchQueue = .main) {
        let configuration = OSCUdpServerConfiguration(interface: interface,
                                                      port: port,
                                                      multicastGroups: multicastGroups)
        self.init(configuration: configuration,
                  delegate: delegate,
                  queue: queue)
    }

    deinit {
        stopListening()
        socket.synchronouslySetDelegate(nil)
    }

    // MARK: Listening

    /// Start the server listening.
    /// - Throws: An error relating to the binding of a socket.
    /// Although this method does automatically attempt to join the multicast groups after successfully
    /// starting to listen, those errors are not handled here.
    ///
    /// The server will bind its socket to a port. If an interface has been set,
    /// it will also bind to that so messages are only received through that interface;
    /// otherwise packets are received on all up and running interfaces.
    ///
    /// The method also attempts to join the multicast groups set on the server.
    /// `joinedmulticastGroups` should be used in all instances to query
    /// which multicast groups the server is currently listening to.
    public func startListening() throws {
        guard isListening == false else { return }
        try socket.bind(toPort: port, interface: interface)
        try socket.beginReceiving()
        isListening = true
        for multicastGroup in multicastGroups {
            do {
                try join(multicastGroup: multicastGroup)
                joinedMulticastGroups.insert(multicastGroup)
            } catch {
                // The error here is purposefully not thrown.
                // The purpose of this function is to set the server listening
                // and the automation of joining multicast groups is a bonus.
                // joinedMulticastGroups can be used after startListening() has
                // been called to work out which groups have been joined or not.
                joinedMulticastGroups.remove(multicastGroup)
            }
        }
    }

    /// Stop the server listening.
    ///
    /// All currently joined multicast groups are left and the servers socket is closed.
    public func stopListening() {
        guard isListening else { return }
        joinedMulticastGroups.forEach { try? leave(multicastGroup: $0) }
        socket.close()
        joinedMulticastGroups.removeAll()
    }

    // MARK: Reuse Port

    /// Sets the reusePort state of the servers socket.
    /// - Parameter flag: true to enable it; otherwise, false to disable it.
    /// - Throws: An error, if one occured in the set socket function.
    ///
    /// By default, only one socket can be bound to a given port at a time.
    /// To enable multiple processes to simultaneously bind to the same port,
    /// you need to enable this functionality. All processes that wish to use the
    /// port simultaneously must all enable reuse port on the socket bound to that port.
    /// This includes other applications attempting to use the same port...
    public func enableReusePort(_ flag: Bool) throws {
        stopListening()
        try socket.enableBroadcast(flag)
        reusePort = flag
    }

    // MARK: Multicasting

    /// Join a multicast group.
    /// - Parameter multicastGroup: A multicast group to be joined.
    /// - Throws: An error if the server is not currently listening
    /// or it was unable to join the multicast group at the socket level.
    ///
    /// A multiverse group should be an IP address in the range 224.0.0.0 through 239.255.255.255.
    public func join(multicastGroup: String) throws {
        if isListening {
            try socket.joinMulticastGroup(multicastGroup, onInterface: interface)
            joinedMulticastGroups.insert(multicastGroup)
        } else {
            throw OSCUdpServerError.serverSocketIsNotBound
        }
    }

    /// Leave a multicast group.
    /// - Parameter multicastGroup: A multicast group to leave.
    /// - Throws: An error if the server is not currently listening,
    /// is not currently joined, or it was unable to leave the multicast group at the socket level.
    ///
    /// A multiverse group should be an IP address in the range 224.0.0.0 through 239.255.255.255.
    public func leave(multicastGroup: String) throws {
        if isListening {
            if joinedMulticastGroups.contains(multicastGroup) {
                try socket.leaveMulticastGroup(multicastGroup, onInterface: interface)
                joinedMulticastGroups.remove(multicastGroup)
            } else {
                throw OSCUdpServerError.multicastGroupNotJoined
            }
        } else {
            throw OSCUdpServerError.serverSocketIsNotBound
        }
    }

}

// MARK: - GCDAsyncUDPSocketDelegate
extension OSCUdpServer: GCDAsyncUdpSocketDelegate {

    public func udpSocket(_ sock: GCDAsyncUdpSocket,
                          didReceive data: Data,
                          fromAddress address: Data,
                          withFilterContext filterContext: Any?) {
        guard let host = GCDAsyncUdpSocket.host(fromAddress: address) else { return }
        do {
            let port = GCDAsyncUdpSocket.port(fromAddress: address)
            let packet = try OSCParser.packet(from: data)
            if let message = OSCKit.message(for: packet) {
                try? OSCUdpClient(host: host, port: port).send(message)
            } else {
                delegate?.server(self,
                                  didReceivePacket: packet,
                                  fromHost: host,
                                  port: port)
            }
        } catch {
            delegate?.server(self,
                             didReadData: data,
                             with: error)
        }
        if !isListening {
            isListening = true
        }
    }

    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket,
                                  withError error: Error?) {
        isListening = false
        if joinedMulticastGroups.isEmpty == false {
            joinedMulticastGroups.removeAll()
        }
        delegate?.server(self, socketDidCloseWithError: error)
    }

}
