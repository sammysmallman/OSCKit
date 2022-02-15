//
//  OSCTcpServer.swift
//  OSCKit
//
//  Created by Sam Smallman on 10/07/2021.
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
import CocoaAsyncSocket
import CoreOSC

/// An object that accepts connections from TCP clients and can send & receive OSCPackets to and from them.
public class OSCTcpServer: NSObject {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCTcpServer(\
        interface: \(String(describing: interface)), \
        port: \(port), \
        streamFraming: \(streamFraming))
        """
    }

    /// A configuration object representing the current configurable state of the server.
    public var configuration: OSCTcpServerConfiguration {
        OSCTcpServerConfiguration(interface: interface,
                                  port: port,
                                  streamFraming: streamFraming)
    }

    /// The servers TCP socket that all new connections are accepted on.
    /// Also where all `OSCPacket`s are received from.
    private var socket: GCDAsyncSocket = GCDAsyncSocket()

    /// A `Dictionary` of client TCP sockets connected to the server.
    /// This dictionary is keyed by the sockets with the value containing the state of each client.
    private var sockets: [GCDAsyncSocket: ClientState] = [:]

    /// An `Array` of tuples representing the host and port for each of the servers connected clients.
    public var clients: [(host: String, port: UInt16)] {
        sockets.compactMap { (host: $0.value.host, port: $0.value.port) }
    }

    /// The timeout for the read and write operartions.
    /// If the timeout value is negative, the send operation will not use a timeout.
    public var timeout: TimeInterval = -1

    /// A boolean value that indicates whether the server is listening for new connections and OSC packets.
    public private(set) var isListening: Bool = false

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the server will listen on all interfaces.
    ///
    /// Setting this property will stop the server listening.
    public var interface: String? {
        didSet {
            stopListening()
        }
    }

    /// The servers local host.
    public var localHost: String? { socket.localHost }

    /// The port the server should listen for packets on.
    ///
    /// Setting this property will stop the server listening.
    public var port: UInt16 {
        didSet {
            stopListening()
        }
    }

    /// The stream framing all OSCPackets will be encoded and decoded with.
    ///
    /// There are two versions of OSC:
    /// - OSC 1.0 uses packet length headers.
    /// - OSC 1.1 uses the [SLIP protocol](http://www.rfc-editor.org/rfc/rfc1055.txt).
    public var streamFraming: OSCTcpStreamFraming = .SLIP {
        didSet {
            sockets.forEach { sockets[$0.key]!.state = OSCTcp.SocketState() }
        }
    }

    /// The dispatch queue that the server runs and executes all delegate callbacks on.
    private let queue: DispatchQueue

    /// The servers delegate.
    ///
    /// The delegate must conform to the `OSCTcpServerDelegate` protocol.
    public weak var delegate: OSCTcpServerDelegate?

    /// A dictionary of `OSCPackets` keyed by the sequenced `tag` number.
    ///
    /// This allows for a reference to a sent packet when the
    /// GCDAsyncSocketDelegate method socket(_:didWriteDataWithTag:) is called.
    private var sendingMessages: [Int: SentMessage] = [:]

    /// A sequential tag that is increased and associated with each message sent.
    ///
    /// The tag will wrap around to 0 if the maximum amount has been reached.
    /// This allows for a reference to a sent packet when the
    /// GCDAsyncSocketDelegate method socket(_:didWriteDataWithTag:) is called.
    private var tag: Int = 0

    /// An OSC TCP Server.
    /// - Parameters:
    ///   - configuration: A configuration object that defines the behavior of a TCP server.
    ///   - delegate: The servers delegate.
    ///   - queue: The dispatch queue that the server runs and executes all delegate callbacks on.
    public init(configuration: OSCTcpServerConfiguration,
                delegate: OSCTcpServerDelegate? = nil,
                queue: DispatchQueue = .main) {
        if configuration.interface?.isEmpty == false {
            interface = configuration.interface
        } else {
            interface = nil
        }
        port = configuration.port
        streamFraming = configuration.streamFraming
        self.delegate = delegate
        self.queue = queue
        super.init()
        socket.setDelegate(self, delegateQueue: queue)
    }

    /// An OSC TCP Server.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address
    ///                or nil if the server should listen on all interfaces.
    ///   - port: The port the server accept new connections and listen for packets on.
    ///   - streamFraming: The stream framing all OSCPackets will be encoded and decoded with by the server.
    ///   - delegate: The servers delegate.
    ///   - queue: The dispatch queue that the server executes all delegate callbacks on.
    public convenience init(interface: String? = nil,
                            port: UInt16,
                            streamFraming: OSCTcpStreamFraming,
                            delegate: OSCTcpServerDelegate? = nil,
                            queue: DispatchQueue = .main) {
        let configuration = OSCTcpServerConfiguration(interface: interface,
                                                      port: port,
                                                      streamFraming: streamFraming)
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
    /// - Throws: An error relating to the setting up of the socket.
    ///
    /// The server will accept connections on the servers port. If an interface
    /// has been set, it will only accept connections through that interface;
    /// otherwise connections are accepted on all up and running interfaces.
    public func startListening() throws {
        if socket.delegateQueue != queue {
            socket.synchronouslySetDelegateQueue(queue)
        }
        try socket.accept(onInterface: interface, port: port)
        isListening = true
    }

    /// Stop the server listening.
    ///
    /// All currently connected clients will be disconnected and the servers socket is closed.
    public func stopListening() {
        guard isListening else { return }
        isListening = false
        sockets.forEach { $0.key.disconnectAfterWriting() }
        socket.disconnectAfterReadingAndWriting()
        socket.synchronouslySetDelegateQueue(nil)
    }

    /// Send an `OSCPacket` to all connected clients.
    /// - Parameters:
    ///  - packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    public func send(_ packet: OSCPacket) {
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.sockets.forEach { socket in
                strongSelf.socket.readData(withTimeout: strongSelf.timeout, tag: 0)
                strongSelf.sendingMessages[strongSelf.tag] = SentMessage(host: socket.value.host,
                                                                         port: socket.value.port,
                                                                         packet: packet)
                OSCTcp.send(packet: packet,
                            streamFraming: strongSelf.streamFraming,
                            with: socket.key,
                            timeout: strongSelf.timeout,
                            tag: strongSelf.tag)
                strongSelf.tag = strongSelf.tag == Int.max ? 0 : strongSelf.tag + 1
            }
        }
    }

    /// Send the raw data of an `OSCPacket` to all connected clients.
    /// - Parameter data: Data from an `OSCMessage` or `OSCBundle`.
    /// - Throws: An `OSCParserError` if a packet can't be parsed from the data.
    public func send(_ data: Data) throws {
        let packet = try OSCParser.packet(from: data)
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.sockets.forEach { socket in
                strongSelf.socket.readData(withTimeout: strongSelf.timeout, tag: 0)
                strongSelf.sendingMessages[strongSelf.tag] = SentMessage(host: socket.value.host,
                                                                         port: socket.value.port,
                                                                         packet: packet)
                OSCTcp.send(data: data,
                            streamFraming: strongSelf.streamFraming,
                            with: socket.key,
                            timeout: strongSelf.timeout,
                            tag: strongSelf.tag)
                strongSelf.tag = strongSelf.tag == Int.max ? 0 : strongSelf.tag + 1
            }
        }
    }

    /// Send an `OSCPacket` to a connected client.
    /// - Parameters:
    ///   - packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    ///   - host: The host of the client the packet should be sent to.
    ///   - port: The port of the client the packet should be sent to.
    public func send(_ packet: OSCPacket, to host: String, port: UInt16) {
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            guard let socket = strongSelf.sockets.first(where: {
                $0.value.host == host && $0.value.port == port
            }) else {
                return
            }
            strongSelf.socket.readData(withTimeout: strongSelf.timeout, tag: 0)
            strongSelf.sendingMessages[strongSelf.tag] = SentMessage(host: socket.value.host,
                                                                     port: socket.value.port,
                                                                     packet: packet)
            OSCTcp.send(packet: packet,
                        streamFraming: strongSelf.streamFraming,
                        with: socket.key,
                        timeout: strongSelf.timeout,
                        tag: strongSelf.tag)
            strongSelf.tag = strongSelf.tag == Int.max ? 0 : strongSelf.tag + 1
        }
    }

    /// Send the raw data of an `OSCPacket` to a connected client.
    /// - Parameters:
    ///   - data: Data from an `OSCMessage` or `OSCBundle`.
    ///   - host: The host of the client the packet should be sent to.
    ///   - port: The port of the client the packet should be sent to.
    /// - Throws: An `OSCParserError` if a packet can't be parsed from the data.
    public func send(_ data: Data, to host: String, port: UInt16) throws {
        let packet = try OSCParser.packet(from: data)
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            guard let socket = strongSelf.sockets.first(where: {
                $0.value.host == host && $0.value.port == port
            }) else {
                return
            }
            strongSelf.socket.readData(withTimeout: strongSelf.timeout, tag: 0)
            strongSelf.sendingMessages[strongSelf.tag] = SentMessage(host: socket.value.host,
                                                                     port: socket.value.port,
                                                                     packet: packet)
            OSCTcp.send(data: data,
                        streamFraming: strongSelf.streamFraming,
                        with: socket.key,
                        timeout: strongSelf.timeout,
                        tag: strongSelf.tag)
            strongSelf.tag = strongSelf.tag == Int.max ? 0 : strongSelf.tag + 1
        }
    }

}

// MARK: - GCDAsyncSocketDelegate
extension OSCTcpServer: GCDAsyncSocketDelegate {

    public func socket(_ sock: GCDAsyncSocket,
                       didAcceptNewSocket newSocket: GCDAsyncSocket) {
        if !isListening {
            isListening = true
        }
        guard let host = newSocket.connectedHost else { return }
        sockets[newSocket] = ClientState(host: host,
                                         port: newSocket.connectedPort)
        newSocket.readData(withTimeout: timeout, tag: 0)
        delegate?.server(self,
                         didConnectToClientWithHost: host,
                         port: newSocket.connectedPort)
    }

    public func socket(_ sock: GCDAsyncSocket,
                       didRead data: Data,
                       withTag tag: Int) {
        if !isListening {
            isListening = true
        }
        guard sockets.keys.contains(sock) else { return }
        do {
            switch streamFraming {
            case .SLIP:
                try OSCTcp.decodeSLIP(data,
                                      with: &sockets[sock]!.state,
                                      dispatchHandler: { [weak self] packet in
                    guard let strongSelf = self,
                          let host = sock.connectedHost else { return }
                    if let message = OSCKit.message(for: packet) {
                        strongSelf.send(message)
                    } else {
                        guard let delegate = strongSelf.delegate else { return }
                        delegate.server(strongSelf,
                                        didReceivePacket: packet,
                                        fromHost: host,
                                        port: sock.connectedPort)
                    }
                })
            case .PLH:
                try OSCTcp.decodePLH(data,
                                     with: &sockets[sock]!.state.data,
                                     dispatchHandler: { [weak self] packet in
                    guard let strongSelf = self,
                          let host = sock.connectedHost else { return }
                    if let message = OSCKit.message(for: packet) {
                        strongSelf.send(message)
                    } else {
                        guard let delegate = strongSelf.delegate else { return }
                        delegate.server(strongSelf,
                                        didReceivePacket: packet,
                                        fromHost: host,
                                        port: sock.connectedPort)
                    }
                })
            }
        } catch {
            delegate?.server(self, didReadData: data, with: error)
        }
        sock.readData(withTimeout: timeout, tag: 0)
    }
    


    public func socket(_ sock: GCDAsyncSocket,
                       didWriteDataWithTag tag: Int) {
        if !isListening {
            isListening = true
        }
        guard let sentMessage = sendingMessages[tag] else { return }
        sendingMessages[tag] = nil
        if OSCKit.listening(for: sentMessage.packet) {
            delegate?.server(self,
                             didSendPacket: sentMessage.packet,
                             toClientWithHost: sentMessage.host,
                             port: sentMessage.port)
        }
    }

    public func socketDidDisconnect(_ sock: GCDAsyncSocket,
                                    withError error: Error?) {
        if sock != socket {
            if !isListening {
                isListening = true
            }
            guard let host = sockets[sock]?.host,
                  let port = sockets[sock]?.port else { return }
            sockets[sock] = nil
            delegate?.server(self,
                             didDisconnectFromClientWithHost: host,
                             port: port)
        } else {
            delegate?.server(self,
                             socketDidCloseWithError: error)
            sockets.removeAll()
            sendingMessages.removeAll()
            tag = 0
            isListening = false
        }
    }

}

extension OSCTcpServer {

    /// An object that contains the state of a client connection.
    private struct ClientState {

        /// The host of the client.
        let host: String

        /// The port of the client.
        let port: UInt16

        /// An object that contains the current state of the received data from a clients socket.
        var state: OSCTcp.SocketState

        /// An object that contains the state of a client connection.
        /// - Parameters:
        ///   - host: The host of the client.
        ///   - port: The port of the client.
        ///   - state: An object that contains the current state of the received data from a clients socket.
        init(host: String,
             port: UInt16,
             state: OSCTcp.SocketState = .init()) {
            self.host = host
            self.port = port
            self.state = state
        }

    }
}

extension OSCTcpServer {

    /// An object that represents a packet sent to a client.
    private struct SentMessage {

        /// The host of the client the message was sent to.
        let host: String

        /// The port of the client the message was sent to.
        let port: UInt16

        /// The message that was sent to the client.
        let packet: OSCPacket

    }
}
