//
//  OSCClient.swift
//  OSCKit
//
//  Created by Sam Smallman on 29/10/2017.
//  Copyright © 2022 Sam Smallman. https://github.com/SammySmallman
//
// This file is part of OSCKit
//
// OSCKit is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OSCKit is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import CocoaAsyncSocket

public class OSCClient : NSObject, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    
    private var socket: OSCSocket?
    private var userData: NSData?
    private var readData = NSMutableData()
    private var readState = NSMutableDictionary()
    private var activeData = NSMutableDictionary()
    private var activeState = NSMutableDictionary()
    
    public weak var delegate: (OSCClientDelegate & OSCPacketDestination)?
    
    /// The delegate which receives debug log messages from this producer.
    public weak var debugDelegate: OSCDebugDelegate?
    
    public var isConnected: Bool {
        get {
            guard let sock = self.socket else { return false }
            return sock.isConnected
        }
    }
    
    public var useTCP = false {
        didSet {
            destroySocket()
        }
    }
    
    public var interface: String? {
        didSet {
            if let aInterface = interface, aInterface.isEmpty {
                interface = nil
            }
            guard let sock = self.socket else { return }
            sock.interface = interface
        }
    }
    
    public var host: String? = "localhost" {
        didSet {
            if let aHost = host, aHost.isEmpty {
                host = nil
            }
            guard let sock = self.socket else { return }
            sock.host = host
        }
    }
    
    public var port: UInt16 = 24601 {
        didSet {
            guard let sock = self.socket else { return }
            sock.port = port
        }
    }
    public var streamFraming: OSCTCPStreamFraming = .SLIP
    
    public override init() {
        super.init()
    }
    
    internal func createSocket() {
        if self.useTCP {
            let tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            self.socket = OSCSocket(with: tcpSocket)
            guard let sock = self.socket else { return }
            self.readState.setValue(sock, forKey: "socket")
            self.readState.setValue(false, forKey: "dangling_ESC")
        } else {
            let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
            self.socket = OSCSocket(with: udpSocket)
        }
        guard let sock = self.socket else { return }
        sock.interface = self.interface
        sock.host = self.host
        sock.port = self.port
    }
    
    internal func destroySocket() {
        self.readState.removeObject(forKey: "socket")
        self.readState.removeObject(forKey: "dangling_ESC")
        self.socket?.disconnect()
        self.socket = nil
    }
    
    public func connect() throws {
        if self.socket == nil {
            createSocket()
        }
        guard let sock = self.socket else { return }
        try sock.connect()
        if let tcpSocket = sock.tcpSocket, sock.isTCPSocket {
            tcpSocket.readData(withTimeout: -1, tag: 0)
        }
    }
    
    public func disconnect() {
        self.socket?.disconnect()
        self.readData = NSMutableData()
        self.readState.setValue(false, forKey: "dangling_ESC")
    }
    
    public func send(packet: OSCPacket) {
        if self.socket == nil {
            do {
                try connect()
            } catch {
                debugDelegate?.debugLog("Could not send establish connection to send packet.")
            }
        }
        guard let sock = self.socket else {
            debugDelegate?.debugLog("Error: Could not send data; no socket available.")
            return
        }
        if let tcpSocket = sock.tcpSocket, sock.isTCPSocket {
            // Listen for a potential response.
            tcpSocket.readData(withTimeout: -1, tag: 0)
            sock.sendTCP(packet: packet, withStreamFraming: streamFraming)
        } else {
            sock.sendUDP(packet: packet)
        }
    }
    
    // MARK: GCDAsyncSocketDelegate
    
    public func newSocketQueueForConnection(fromAddress address: Data, on sock: GCDAsyncSocket) -> DispatchQueue? {
        return nil
    }
    
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        // Client sockets do not accept new incoming connections.
    }
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        debugDelegate?.debugLog("Client Socket: \(sock) didConnectToHost: \(host):\(port)")
        guard let delegate = self.delegate else { return }
        delegate.clientDidConnect(client: self)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        debugDelegate?.debugLog("Client Socket: \(sock) didRead Data of length: \(data.count), withTag: \(tag)")
        
        guard let delegate = self.delegate else { return }
        do {
            try OSCParser().translate(OSCData: data, streamFraming: streamFraming, to: readData, with: readState, andDestination: delegate)
            sock.readData(withTimeout: -1, tag: tag)
        } catch {
            debugDelegate?.debugLog("Error: \(error)")
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        debugDelegate?.debugLog("Client Socket: \(sock) didReadPartialDataOfLength: \(partialLength), withTag: \(tag)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        debugDelegate?.debugLog("Client Socket: \(sock) didWriteDataWithTag: \(tag)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        debugDelegate?.debugLog("Client Socket: \(sock) didWritePartialDataOfLength: \(partialLength), withTag: \(tag)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        debugDelegate?.debugLog("Client Socket: \(sock) shouldTimeoutReadWithTag: \(tag)")
        return 0
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        debugDelegate?.debugLog("Client Socket: \(sock) shouldTimeoutWriteWithTag: \(tag)")
        return 0
    }
    
    public func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        debugDelegate?.debugLog("Client Socket: \(sock) didCloseReadStream")
        self.readData.setData(Data())
        self.readState.setValue(false, forKey: "dangling_ESC")
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        debugDelegate?.debugLog("Client Socket: \(sock) didDisconnect, withError: \(err.debugDescription)")
        self.readData.setData(Data())
        self.readState.setValue(false, forKey: "dangling_ESC")
        guard let delegate = self.delegate else { return }
        delegate.clientDidDisconnect(client: self)
    }
    
    public func socketDidSecure(_ sock: GCDAsyncSocket) {
        debugDelegate?.debugLog("Client Socket: \(sock) didSecure")
    }
    
    // MARK: GCDAsyncUDPSocketDelegate
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didConnectToAddress \(address)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didNotConnect, dueToError: \(error.debugDescription))")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didSendDataWithTag: \(tag)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didNotSendDataWithTag: \(tag), dueToError: \(error.debugDescription)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didReceiveData of Length: \(data.count), fromAddress \(address)")
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) Did Close. With Error: \(String(describing: error?.localizedDescription))")
    }
    
}
