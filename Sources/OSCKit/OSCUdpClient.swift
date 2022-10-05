//
//  OSCUdpClient.swift
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
import NetUtils
import CoreOSC

/// An object that sends OSCPackets via UDP.
public class OSCUdpClient: NSObject {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpClient(\
        interface: \(String(describing: interface)), \
        host: \(host), \
        port: \(port))
        """
    }

    /// A configuration object representing the current configurable state of the client.
    public var configuration: OSCUdpClientConfiguration {
        OSCUdpClientConfiguration(interface: interface,
                                  host: host,
                                  port: port)
    }

    /// The clients UDP socket that all OSCPackets are sent from.
    private let socket: GCDAsyncUdpSocket = GCDAsyncUdpSocket()

    /// The timeout for the send operartion.
    /// If the timeout value is negative, the send operation will not use a timeout.
    public var timeout: TimeInterval = 3

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the client will uses the default interface.
    public var interface: String?

    /// The destination the client should send UDP packets to.
    /// May be specified as a domain name (e.g. "google.com") or an IP address string (e.g. "192.168.1.16").
    /// You may also use the convenience strings of "loopback" or "localhost".
    public var host: String

    /// The port of the host the client should send packets to.
    public var port: UInt16
    
    /// A dictionary of `OSCPackets` keyed by the sequenced `tag` number.
    ///
    /// This allows for a reference to a sent packet when the
    /// GCDAsyncUDPSocketDelegate method udpSocket(_:didSendDataWithTag:) is called.
    private var sendingPackets: [Int: OSCSentPacket] = [:]

    /// A sequential tag that is increased and associated with each packet sent.
    ///
    /// The tag will wrap around to 0 if the maximum amount has been reached.
    /// This allows for a reference to a sent packet when the
    /// GCDAsyncUDPSocketDelegate method udpSocket(_:didSendDataWithTag:) is called.
    private var tag: Int = 0
    
    /// A key associated with the `queue` to enable a check that the
    /// execution of a method is carried out on the correct context.
    private let queueKey : DispatchSpecificKey<Int>
    
    /// A random UInt32 value paired with the `queueKey` associated with the `queue`
    /// to enable a check that the execution of a method is carried out on the correct context.
    private let queueKeyValue: Int

    /// The dispatch queue that the client executes all delegate callbacks on.
    private let queue: DispatchQueue

    /// The clients real delegate presented as a facade by `delegate` for thread safety.
    private weak var _delegate: OSCUdpClientDelegate?
    
    /// The clients delegate.
    ///
    /// The delegate must conform to the `OSCUdpClientDelegate` protocol.
    public var delegate: OSCUdpClientDelegate? {
        get {
            if DispatchQueue.getSpecific(key: queueKey) == queueKeyValue {
                return _delegate
            } else {
                return queue.sync { _delegate }
            }
        }
        set {
            if DispatchQueue.getSpecific(key: queueKey) == queueKeyValue {
                _delegate = newValue
            } else {
                queue.sync { _delegate = newValue }
            }
        }
    }

    /// An OSC UDP Client.
    /// - Parameters:
    ///   - configuration: A configuration object that defines the behavior of a UDP client.
    ///   - delegate: The clients delegate.
    ///   - queue: The dispatch queue that the client executes all delegate callbacks on.
    public init(configuration: OSCUdpClientConfiguration,
                delegate: OSCUdpClientDelegate? = nil,
                queue: DispatchQueue = .main) {
        if configuration.interface?.isEmpty == false {
            self.interface = configuration.interface
        } else {
            self.interface = nil
        }
        self.host = configuration.host
        self.port = configuration.port
        self._delegate = delegate
        self.queue = queue
        self.queueKey = DispatchSpecificKey<Int>()
        self.queueKeyValue = Int(arc4random())
        self.queue.setSpecific(key: queueKey, value: queueKeyValue)
        super.init()
        socket.setDelegate(self, delegateQueue: queue)
    }

    /// An OSC UDP Client.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - host: The destination the client should send UDP packets to.
    ///   - port: The port of the host the client should send packets to.
    ///   - delegate: The clients delegate.
    ///   - queue: The dispatch queue that the client executes all delegate callbacks on.
    public convenience init(interface: String? = nil,
                            host: String,
                            port: UInt16,
                            delegate: OSCUdpClientDelegate? = nil,
                            queue: DispatchQueue = .main) {
        let configuration = OSCUdpClientConfiguration(interface: interface,
                                                      host: host,
                                                      port: port)
        self.init(configuration: configuration,
                  delegate: delegate,
                  queue: queue)
    }

    deinit {
        queue.setSpecific(key: queueKey, value: nil)
        socket.synchronouslySetDelegate(nil)
    }

    /// Send an OSCPacket from the client.
    /// - Parameter packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    /// - Throws: An error if either the broadcast flag could not be set or the interface could not be bound to.
    ///
    /// The broadcast flag will automatically be set if an interface has been set for the client and the host
    /// is either a directed or limited broadcast address.
    /// If an interface has not been set for the client the default OS interface will be used.
    public func send(_ packet: OSCPacket) throws {
        try send(packet: packet, with: packet.data())
    }

    /// Send the raw data of an `OSCPacket` from the client.
    /// - Parameter data: Data from an `OSCMessage` or `OSCBundle`.
    /// - Throws: An error if a packet can't be parsed from the data, the broadcast flag could not
    ///           be set or the interface could not be bound to.
    ///
    /// The broadcast flag will automatically be set if an interface has been set for the client and the host
    /// is either a directed or limited broadcast address.
    /// If an interface has not been set for the client the default OS interface will be used.
    public func send(_ data: Data) throws {
        let packet = try OSCParser.packet(from: data)
        try send(packet: packet, with: data)
    }
   
    /// Send an OSCPacket and its associated data from the client.
    /// - Parameter packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    /// - Parameter data: Data from the given packet.
    /// - Throws: An error if a packet can't be parsed from the data, the broadcast flag could not
    ///           be set or the interface could not be bound to.
    ///
    /// `data` is an input property as its a computed property of an `OSCPacket`.
    /// Therefore by passing it into this function allows for us to not calculate it
    /// once more when send(_:Data) is called.
    ///
    /// The broadcast flag will automatically be set if an interface has been set for the client and the host
    /// is either a directed or limited broadcast address.
    /// If an interface has not been set for the client the default OS interface will be used.
    private func send(packet: OSCPacket, with data: Data) throws {
        if let interface = interface {
            let enableBroadcast = Interface.allInterfaces().contains(where: {
                $0.name == interface && ($0.broadcastAddress == host || "255.255.255.255" == host )
            })
            try socket.enableBroadcast(enableBroadcast)
            // Port 0 means that the OS should choose a random ephemeral port for this socket.
            try socket.bind(toPort: 0, interface: interface)
        }
        let queueCheck: Bool = DispatchQueue.getSpecific(key: queueKey) == queueKeyValue
        if queueCheck {
            sendingPackets[tag] = OSCSentPacket(host: socket.localHost(),
                                                port: socket.localPort(),
                                                packet: packet)
        } else {
            queue.sync {
                sendingPackets[tag] = OSCSentPacket(host: socket.localHost(),
                                                    port: socket.localPort(),
                                                    packet: packet)
            }
        }
        socket.send(data,
                    toHost: host,
                    port: port,
                    withTimeout: timeout,
                    tag: tag)
        socket.closeAfterSending()
        if queueCheck {
            tag &+= 1
        } else {
            queue.sync {
                tag &+= 1
            }
        }
    }

}

// MARK: - GCDAsyncUDPSocketDelegate
extension OSCUdpClient: GCDAsyncUdpSocketDelegate {

    public func udpSocket(_ sock: GCDAsyncUdpSocket,
                          didSendDataWithTag tag: Int) {
        guard let sentPacket = sendingPackets[tag] else { return }
        sendingPackets[tag] = nil
        _delegate?.client(self,
                         didSendPacket: sentPacket.packet,
                         fromHost: sentPacket.host,
                         port: sentPacket.port)
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket,
                          didNotSendDataWithTag tag: Int,
                          dueToError error: Error?) {
        guard let sentPacket = sendingPackets[tag] else { return }
        sendingPackets[tag] = nil
        _delegate?.client(self,
                         didNotSendPacket: sentPacket.packet,
                         fromHost: sentPacket.host,
                         port: sentPacket.port,
                         error: error)
    }

    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket,
                                  withError error: Error?) {
        guard let error = error else { return }
        sendingPackets.removeAll()
        _delegate?.client(self, socketDidCloseWithError: error)
    }

}
