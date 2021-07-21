//
//  OSCTcpClient.swift
//  OSCKit
//
//  Created by Sam Smallman on 09/07/2021.
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

/// An object that establishes a connection to a server via TCP and can send and receive OSCPackets.
public class OSCTcpClient: NSObject {

    /// A textual representation of this instance.
    public override var description: String {
        """
        OSCKit.OSCUTcpClient(\
        interface: \(String(describing: interface)), \
        host: \(host), \
        port: \(port), \
        streamFraming: \(streamFraming))
        """
    }

    /// A configuration object representing the current configurable state of the client.
    public var configuration: OSCTcpClientConfiguration {
        OSCTcpClientConfiguration(interface: interface,
                                  host: host,
                                  port: port,
                                  streamFraming: streamFraming)
    }

    /// The clients TCP socket that all OSCPackets are sent and received from.
    private var socket: GCDAsyncSocket = GCDAsyncSocket()

    /// The clients local host.
    public var localHost: String? { socket.localHost }

    /// The clients local port.
    public var localPort: UInt16? { socket.localPort }

    /// The timeout for the connect opeartion.
    /// If the timeout value is negative, the connect operation will not use a timeout.
    public var connectingTimeout: TimeInterval = 1

    /// The timeout for the send opeartion.
    /// If the timeout value is negative, the send operation will not use a timeout.
    public var timeout: TimeInterval = -1

    /// The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.1.15").
    /// If the value of this is nil the client will uses the default interface.
    ///
    /// Setting this property will disconnect the client.
    public var interface: String? {
        didSet {
            disconnect()
        }
    }

    /// The host of the server that the client should connect to.
    /// May be specified as a domain name (e.g. "google.com") or an IP address string (e.g. "192.168.1.16").
    /// You may also use the convenience strings of "loopback" or "localhost".
    ///
    /// Setting this property will disconnect the client.
    public var host: String {
        didSet {
            disconnect()
        }
    }

    /// The port of the host the client should send packets to.
    ///
    /// Setting this property will disconnect the client.
    public var port: UInt16 {
        didSet {
            disconnect()
        }
    }

    /// The stream framing all OSCPackets will be encoded and decoded with.
    ///
    /// There are two versions of OSC:
    /// - OSC 1.0 uses packet length headers.
    /// - OSC 1.1 uses the [SLIP protocol](http://www.rfc-editor.org/rfc/rfc1055.txt).
    public var streamFraming: OSCTcpStreamFraming = .SLIP {
        didSet {
            state = OSCTcp.SocketState()
        }
    }

    /// The dispatch queue that the client executes all delegate callbacks on.
    private let queue: DispatchQueue

    /// The clients delegate.
    ///
    /// The delegate must conform to the `OSCTcpClientDelegate` protocol.
    public weak var delegate: OSCTcpClientDelegate?

    /// A dictionary of `OSCPackets` keyed by the sequenced `tag` number.
    ///
    /// This allows for a reference to a sent packet when the
    /// GCDAsyncSocketDelegate method socket(_:didWriteDataWithTag:) is called.
    private var sendingMessages: [Int: OSCPacket] = [:]

    /// A sequential tag that is increased and associated with each message sent.
    ///
    /// The tag will wrap around to 0 if the maximum amount has been reached.
    /// This allows for a reference to a sent packet when the
    /// GCDAsyncSocketDelegate method socket(_:didWriteDataWithTag:) is called.
    private var tag: Int = 0

    /// A boolean value that indicates whether the client is connected to a server.
    public var isConnected: Bool { socket.isConnected }

    /// An object that contains the current state of the received data from the clients socket.
    private var state = OSCTcp.SocketState()

    /// An OSC TCP Client.
    /// - Parameters:
    ///   - configuration: A configuration object that defines the behavior of a TCP client.
    ///   - delegate: The clients delegate.
    ///   - queue: The dispatch queue that the client executes all delegate callbacks on.
    public init(configuration: OSCTcpClientConfiguration,
                delegate: OSCTcpClientDelegate? = nil,
                queue: DispatchQueue = .main) {
        interface = configuration.interface
        host = configuration.host
        port = configuration.port
        streamFraming = configuration.streamFraming
        self.delegate = delegate
        self.queue = queue
        super.init()
        socket.setDelegate(self, delegateQueue: queue)
    }

    /// An OSC TCP Client.
    /// - Parameters:
    ///   - interface: An interface name (e.g. "en1" or "lo0"), the corresponding IP address or nil.
    ///   - host: The host of the server that the client should connect to.
    ///   - port: The port of the host the client should send packets to.
    ///   - streamFraming: The stream framing all OSCPackets will be encoded and decoded with by the client.
    ///   - delegate: The clients delegate.
    ///   - queue: The dispatch queue that the client executes all delegate callbacks on.
    public convenience init(interface: String? = nil,
                            host: String,
                            port: UInt16,
                            streamFraming: OSCTcpStreamFraming,
                            delegate: OSCTcpClientDelegate? = nil,
                            queue: DispatchQueue = .main) {
        let configuration = OSCTcpClientConfiguration(interface: interface,
                                                      host: host,
                                                      port: port,
                                                      streamFraming: streamFraming)
        self.init(configuration: configuration, delegate: delegate, queue: queue)
    }

    deinit {
        disconnect()
        socket.synchronouslySetDelegate(nil)
    }

    /// Connect the client to a server.
    /// - Throws: An error if there is an invalid host or interface.
    public func connect() throws {
        // If a socket is in the process of connecting, it may be neither disconnected nor connected.
        // We shouldn't attempt to connect again if it is currently in the process of connecting.
        guard isConnected == false && socket.isDisconnected == true else { return }
        if socket.delegateQueue != queue {
            socket.synchronouslySetDelegateQueue(queue)
        }
        try socket.connect(toHost: host,
                           onPort: port,
                           viaInterface: interface,
                           withTimeout: connectingTimeout)
        socket.readData(withTimeout: timeout, tag: 0)
    }

    /// Disconnect the client from a server.
    public func disconnect() {
        guard isConnected else { return }
        socket.disconnect()
        socket.synchronouslySetDelegateQueue(nil)
    }

    /// Send an `OSCPacket` to the connected server.
    /// - Parameter packet: The packet to be sent, either an `OSCMessage` or `OSCBundle`.
    /// - Throws: An error if the client is not already connected and connecting causes an error.
    ///
    /// If  the client is not already connected to a server `connect()` will be called first.
    public func send(_ packet: OSCPacket) throws {
        try connect()
        guard isConnected else { return }
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.socket.readData(withTimeout: strongSelf.timeout, tag: 0)
            strongSelf.sendingMessages[strongSelf.tag] = packet
            OSCTcp.send(packet: packet,
                        streamFraming: strongSelf.streamFraming,
                        with: strongSelf.socket,
                        timeout: strongSelf.timeout,
                        tag: strongSelf.tag)
            strongSelf.tag = strongSelf.tag == Int.max ? 0 : strongSelf.tag + 1
        }
    }

    /// Send the raw data of an `OSCPacket` to the connected server.
    /// - Parameter data: Data from an `OSCMessage` or `OSCBundle`.
    /// - Throws: An error if a packet can't be parsed from the data or if the client is not
    ///           already connected and connecting causes an error.
    ///
    /// If  the client is not already connected to a server `connect()` will be called first.
    public func send(_ data: Data) throws {
        try connect()
        let packet = try OSCParser.packet(from: data)
        guard isConnected else { return }
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.socket.readData(withTimeout: strongSelf.timeout, tag: 0)
            strongSelf.sendingMessages[strongSelf.tag] = packet
            OSCTcp.send(data: data,
                        streamFraming: strongSelf.streamFraming,
                        with: strongSelf.socket,
                        timeout: strongSelf.timeout,
                        tag: strongSelf.tag)
            strongSelf.tag = strongSelf.tag == Int.max ? 0 : strongSelf.tag + 1
        }
    }

}

// MARK: - GCDAsyncSocketDelegate
extension OSCTcpClient: GCDAsyncSocketDelegate {

    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        delegate?.client(self, didConnectTo: host, port: port)
    }

    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        do {
            switch streamFraming {
            case .SLIP:
                try OSCTcp.decodeSLIP(data,
                                      with: &state,
                                      dispatchHandler: { [weak self] packet in
                    guard let strongSelf = self,
                          let delegate = strongSelf.delegate else { return }
                    delegate.client(strongSelf, didReceivePacket: packet)
                })
            case .PLH:
                try OSCTcp.decodePLH(data,
                                     with: &state.data,
                                     dispatchHandler: { [weak self] packet in
                    guard let strongSelf = self,
                          let delegate = strongSelf.delegate else { return }
                    delegate.client(strongSelf, didReceivePacket: packet)
                })
            }
            sock.readData(withTimeout: timeout, tag: 0)
        } catch {
            delegate?.client(self, didReadData: data, with: error)
        }
    }

    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        guard let packet = sendingMessages[tag] else { return }
        sendingMessages[tag] = nil
        delegate?.client(self, didSendPacket: packet)
    }

    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError error: Error?) {
        delegate?.client(self, didDisconnectWith: error)
        state = OSCTcp.SocketState()
        sendingMessages.removeAll()
        tag = 0
    }

}
