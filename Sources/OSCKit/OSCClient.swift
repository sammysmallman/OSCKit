//
//  OSCClient.swift
//  OSCKit
//
//  Created by Sam Smallman on 29/10/2017.
//  Copyright © 2017 Sam Smallman. http://sammy.io
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

public class OSCClient : NSObject, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    
    private var socket: Socket?
    private var userData: NSData?
    private var readData = NSMutableData()
    private var readState = NSMutableDictionary()
    private var activeData = NSMutableDictionary()
    private var activeState = NSMutableDictionary()
    
    public var delegate: (OSCClientDelegate & OSCPacketDestination)?
    
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
    public var streamFraming: OSCParser.streamFraming = .SLIP
    
    public override init() {
        super.init()
    }
    
    internal func createSocket() {
        if self.useTCP {
            let tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            self.socket = Socket(with: tcpSocket)
            guard let sock = self.socket else { return }
            self.readState.setValue(sock, forKey: "socket")
            self.readState.setValue(false, forKey: "dangling_ESC")
        } else {
            let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
            self.socket = Socket(with: udpSocket)
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
                debugPrint("Could not send establish connection to send packet.")
            }
        }
        guard let sock = self.socket else {
            debugPrint("Error: Could not send data; no socket available.")
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
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didConnectToHost: \(host):\(port)")
        #endif
        guard let delegate = self.delegate else { return }
        delegate.clientDidConnect(client: self)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didRead Data of length: \(data.count), withTag: \(tag)")
        #endif
        
        guard let delegate = self.delegate else { return }
        do {
            try OSCParser().translate(OSCData: data, streamFraming: streamFraming, to: readData, with: readState, andDestination: delegate)
            sock.readData(withTimeout: -1, tag: tag)
        } catch {
            print("Error: \(error)")
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didReadPartialDataOfLength: \(partialLength), withTag: \(tag)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didWriteDataWithTag: \(tag)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didWritePartialDataOfLength: \(partialLength), withTag: \(tag)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) shouldTimeoutReadWithTag: \(tag)")
        #endif
        return 0
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) shouldTimeoutWriteWithTag: \(tag)")
        #endif
        return 0
    }
    
    public func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didCloseReadStream")
        #endif
        self.readData.setData(Data())
        self.readState.setValue(false, forKey: "dangling_ESC")
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didDisconnect, withError: \(String(describing: err))")
        #endif
        self.readData.setData(Data())
        self.readState.setValue(false, forKey: "dangling_ESC")
        guard let delegate = self.delegate else { return }
        delegate.clientDidDisconnect(client: self)
    }
    
    public func socketDidSecure(_ sock: GCDAsyncSocket) {
        #if Client_Debug
            debugPrint("Client Socket: \(sock) didSecure")
        #endif
    }
    
    // MARK: GCDAsyncUDPSocketDelegate
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        #if Client_Debug
            debugPrint("UDP Socket: \(sock) didConnectToAddress \(address)")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        #if Client_Debug
            debugPrint("UDP Socket: \(sock) didNotConnect, dueToError: \(String(describing: error?.localizedDescription))")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        #if Client_Debug
            debugPrint("UDP Socket: \(sock) didSendDataWithTag: \(tag)")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        #if Client_Debug
            debugPrint("UDP Socket: \(sock) didNotSendDataWithTag: \(tag), dueToError: \(String(describing: error?.localizedDescription))")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        // Client UDP Sockets do not receive data.
        #if Client_Debug
            debugPrint("UDP Socket: \(sock) didReceiveData of Length: \(data.count), fromAddress \(address)")
        #endif
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) Did Close. With Error: \(String(describing: error?.localizedDescription))")
        #endif
    }
    
    
}
