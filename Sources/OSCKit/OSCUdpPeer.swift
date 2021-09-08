//
//  OSCUdpPeer.swift
//  OSCKit
//
//  Created by Sam Smallman on 08/09/2021.
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
import CoreOSC

/// An object that receives and sends OSCPackets via UDP using the same socket.
public class OSCUdpPeer: NSObject {

    enum OSCUdpPeerError: Error, CustomStringConvertible {
        case peerSocketIsNotBound

        public var description: String {
            switch self {
            case .peerSocketIsNotBound:
                return "The peers socket is not bound to a port. Try startRunning() first."
            }
        }
    }

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUdpPeer(\
        interface: \(String(describing: interface)), \
        host: \(host), \
        port: \(port)))
        """
    }

    /// The peers UDP socket that all OSCPackets are received and sent from.
    private let socket: GCDAsyncUdpSocket

    /// A boolean value that indicates whether the peer is running i.e. whether it can receive and send OSCPackets.
    public private(set) var isRunning: Bool = false

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the peer will receive on all interfaces and the interface will be infered by the host
    /// when sending packets.
    ///
    /// Setting this property will stop the peer from sending and receiving packets.
    public var interface: String? {
        didSet {
            stopRunning()
        }
    }
    
    /// The destination the peer should send UDP packets to.
    /// May be specified as a domain name (e.g. "google.com") or an IP address string (e.g. "192.168.1.16").
    /// You may also use the convenience strings of "loopback" or "localhost".
    public var host: String

    /// The host for the peer.
    public var localHost: String? { socket.localHost() }

    /// The port for both the host the peer should send packets to and for the peer itself to receive packets on.
    ///
    /// Setting this property will stop the peer running.
    public var port: UInt16 {
        didSet {
            stopRunning()
        }
    }

    /// A boolean value that indicates whether the peers socket has been enabled
    /// to allow for multiple processes to simultaneously bind to the same port.
    public private(set) var reusePort: Bool = false
    
    /// The timeout for the send opeartion.
    /// If the timeout value is negative, the send operation will not use a timeout.
    public var timeout: TimeInterval = 3
    
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

    /// The dispatch queue that the peer executes all delegate callbacks on.
    private let queue: DispatchQueue

    /// The peers delegate.
    ///
    /// The delegate must conform to the `OSCUdpPeerDelegate` protocol.
    public weak var delegate: OSCUdpPeerDelegate?

    /// An OSC UDP Peer.
    /// - Parameters:
    ///   - configuration: A configuration object that defines the behavior of a UDP peer.
    ///   - delegate: The peers delegate.
    ///   - queue: The dispatch queue that the peer executes all delegate callbacks on.
    public init(configuration: OSCUdpPeerConfiguration,
                delegate: OSCUdpPeerDelegate? = nil,
                queue: DispatchQueue = .main) {
        socket = GCDAsyncUdpSocket()
        if let configInterface = configuration.interface,
           configInterface.isEmpty == false {
            self.interface = configInterface
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

    /// An OSC UDP Peer.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address
    ///                or nil if the peer should listen on all interfaces.
    ///   - host: The destination the peer should send UDP packets to.
    ///   - port: The port for both the host the peer should send packets to and for the peer itself to receive packets on.
    ///   - delegate: The peers delegate.
    ///   - queue: The dispatch queue that the peer executes all delegate callbacks on.
    public convenience init(interface: String? = nil,
                            host: String,
                            port: UInt16,
                            delegate: OSCUdpPeerDelegate? = nil,
                            queue: DispatchQueue = .main) {
        let configuration = OSCUdpPeerConfiguration(interface: interface,
                                                    host: host,
                                                    port: port)
        self.init(configuration: configuration,
                  delegate: delegate,
                  queue: queue)
    }

    deinit {
        stopRunning()
        socket.synchronouslySetDelegate(nil)
    }

    // MARK: Running

    /// Start the peer running
    ///
    /// The peer will bind its socket to a port. If an interface has been set,
    /// it will also bind to that so packets are only received through that interface;
    /// otherwise packets are received on all up and running interfaces.
    /// - Throws: An error relating to the binding of a socket.
    public func startRunning() throws {
        guard isRunning == false else { return }
        try socket.bind(toPort: port, interface: interface)
        try socket.beginReceiving()
        isRunning = true
    }

    /// Stop the peer running.
    ///
    /// The peers socket is closed.
    public func stopRunning() {
        guard isRunning else { return }
        socket.close()
    }

    // MARK: Reuse Port

    /// Sets the reusePort state of the peers socket.
    /// - Parameter flag: true to enable it; otherwise, false to disable it.
    /// - Throws: An error, if one occured in the set socket function.
    ///
    /// By default, only one socket can be bound to a given port at a time.
    /// To enable multiple processes to simultaneously bind to the same port,
    /// you need to enable this functionality. All processes that wish to use the
    /// port simultaneously must all enable reuse port on the socket bound to that port.
    /// This includes other applications attempting to use the same port...
    public func enableReusePort(_ flag: Bool) throws {
        stopRunning()
        try socket.enableBroadcast(flag)
        reusePort = flag
    }
    
    // MARK: Send
    
    /// Send an OSCPacket from the peer.
    /// - Parameter packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    /// - Throws: An `OSCUdpPeerError.peerSocketIsNotBound` if the peer is not currently running.
    public func send(_ packet: OSCPacket) throws {
        guard isRunning else { throw OSCUdpPeerError.peerSocketIsNotBound }
        try send(packet: packet, with: packet.data())
    }

    /// Send the raw data of an `OSCPacket` from the peer.
    /// - Parameter data: Data from an `OSCMessage` or `OSCBundle`.
    /// - Throws: An `OSCUdpPeerError.peerSocketIsNotBound` if the peer is not currently running.
    public func send(_ data: Data) throws {
        guard isRunning else { throw OSCUdpPeerError.peerSocketIsNotBound }
        let packet = try OSCParser.packet(from: data)
        try send(packet: packet, with: data)
    }
   
    /// Send an OSCPacket and its associated data from the peer.
    /// - Parameter packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    /// - Parameter data: Data from the given packet.
    /// - Throws: An `OSCUdpPeerError.peerSocketIsNotBound` if the peer is not currently running.
    ///
    /// `data` is an input property as its a computed property of an `OSCPacket`.
    /// Therefore by passing it into this function allows for us to not calculate it
    /// once more when send(_:Data) is called.
    private func send(packet: OSCPacket, with data: Data) throws {
        sendingPackets[tag] = OSCSentPacket(host: socket.localHost(),
                                            port: socket.localPort(),
                                            packet: packet)
        socket.send(data,
                    toHost: host,
                    port: port,
                    withTimeout: timeout,
                    tag: tag)
        tag = tag == Int.max ? 0 : tag + 1
    }

}

// MARK: - GCDAsyncUDPSocketDelegate
extension OSCUdpPeer: GCDAsyncUdpSocketDelegate {

    public func udpSocket(_ sock: GCDAsyncUdpSocket,
                          didReceive data: Data,
                          fromAddress address: Data,
                          withFilterContext filterContext: Any?) {
        guard let host = GCDAsyncUdpSocket.host(fromAddress: address) else { return }
        do {
            let packet = try OSCParser.packet(from: data)
            delegate?.peer(self,
                           didReceivePacket: packet,
                           fromHost: host,
                           port: GCDAsyncUdpSocket.port(fromAddress: address))
        } catch {
            delegate?.peer(self,
                           didReadData: data,
                           with: error)
        }
        if !isRunning {
            isRunning = true
        }
    }

    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket,
                                  withError error: Error?) {
        isRunning = false
        delegate?.peer(self, socketDidCloseWithError: error)
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        guard let sentPacket = sendingPackets[tag] else { return }
        sendingPackets[tag] = nil
        delegate?.peer(self,
                       didSendPacket: sentPacket.packet,
                       fromHost: sentPacket.host,
                       port: sentPacket.port)
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        guard let sentPacket = sendingPackets[tag] else { return }
        sendingPackets[tag] = nil
        delegate?.peer(self,
                       didNotSendPacket: sentPacket.packet,
                       fromHost: sentPacket.host,
                       port: sentPacket.port,
                       error: error)
    }

}
