//
//  OSCUdpClient.swift
//  OSCKit
//
//  Created by Sam Smallman on 07/07/2021.
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

    /// The timeout for the send opeartion.
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

    /// The dispatch queue that the client executes all delegate callbacks on.
    private let queue: DispatchQueue

    /// The clients delegate.
    ///
    /// The delegate must conform to the `OSCUdpClientDelegate` protocol.
    public weak var delegate: OSCUdpClientDelegate?

    /// A dictionary of `OSCPackets` keyed by the sequenced `tag` number.
    ///
    /// This allows for a reference to a sent packet when the
    /// GCDAsynUDPSocketDelegate method udpSocket(_:didSendDataWithTag:) is called.
    private var sendingPackets: [Int: OSCSentPacket] = [:]

    /// A sequential tag that is increased and associated with each packet sent.
    ///
    /// The tag will wrap around to 0 if the maximum amount has been reached.
    /// This allows for a reference to a sent packet when the
    /// GCDAsynUDPSocketDelegate method udpSocket(_:didSendDataWithTag:) is called.
    private var tag: Int = 0

    /// An OSC UDP Client.
    /// - Parameters:
    ///   - configuration: A configuration object that defines the behavior of a UDP client.
    ///   - delegate: The clients delegate.
    ///   - queue: The dispatch queue that the client executes all delegate callbacks on.
    public init(configuration: OSCUdpClientConfiguration,
                delegate: OSCUdpClientDelegate? = nil,
                queue: DispatchQueue = .main) {
        if let configInterface = configuration.interface,
           configInterface.isEmpty == false {
            interface = configInterface
        } else {
            interface = nil
        }
        host = configuration.host
        port = configuration.port
        self.delegate = delegate
        self.queue = queue
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
        sendingPackets[tag] = OSCSentPacket(host: socket.localHost(),
                                            port: socket.localPort(),
                                            packet: packet)
        socket.send(data,
                    toHost: host,
                    port: port,
                    withTimeout: timeout,
                    tag: tag)
        socket.closeAfterSending()
        tag = tag == Int.max ? 0 : tag + 1
    }

}

// MARK: - GCDAsyncUDPSocketDelegate
extension OSCUdpClient: GCDAsyncUdpSocketDelegate {

    public func udpSocket(_ sock: GCDAsyncUdpSocket,
                          didSendDataWithTag tag: Int) {
        guard let sentPacket = sendingPackets[tag] else { return }
        sendingPackets[tag] = nil
        delegate?.client(self,
                         didSendPacket: sentPacket.packet,
                         fromHost: sentPacket.host,
                         port: sentPacket.port)
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket,
                          didNotSendDataWithTag tag: Int,
                          dueToError error: Error?) {
        guard let sentPacket = sendingPackets[tag] else { return }
        sendingPackets[tag] = nil
        delegate?.client(self,
                         didNotSendPacket: sentPacket.packet,
                         fromHost: sentPacket.host,
                         port: sentPacket.port,
                         error: error)
    }

    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket,
                                  withError error: Error?) {
        guard let error = error else { return }
        sendingPackets.removeAll()
        delegate?.client(self, socketDidCloseWithError: error)
    }

}
