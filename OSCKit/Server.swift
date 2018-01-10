//
//  Server.swift
//  OSCKit
//
//  Created by Sam Smallman on 29/10/2017.
//  Copyright © 2017 Artifice Industries Ltd. http://artificers.co.uk
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

// MARK: Server

import Foundation
import CocoaAsyncSocket

public class Server: NSObject, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    
    private(set) var tcpSocket: Socket!
    private(set) var udpSocket: Socket!
    
    private var activeTCPSockets: NSMutableDictionary!  // Sockets keyed by index of when the connection was accepted.
    private var activeData: NSMutableDictionary!        // NSMutableData keyed by index; buffers the incoming data.
    private var activeState: NSMutableDictionary!       // NSMutableDictionary keyed by index; stores state of incoming data.
    private var activeIndex: Int = 0
    private var joinedMultiCastGroups: [String] = []
    
    public var interface: String = "localhost" {
        willSet {
            stopListening()
            self.tcpSocket?.interface = newValue
            self.udpSocket?.interface = newValue
        }
    }
    public var port: UInt16 = 0 {
        willSet {
            stopListening()
            self.tcpSocket?.port = newValue
            self.udpSocket?.port = newValue
        }
    }
    public var tcpFormat: OSCParser.oscTCPVersion = .SLIP
    
    private var udpReplyPort: UInt16 = 0
    var delegate: OSCPacketDestination?
    
    public override init() {
        super.init()
        let rawTCPSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        let rawUDPSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        self.tcpSocket = Socket(with: rawTCPSocket)
        self.udpSocket = Socket(with: rawUDPSocket)
        self.activeTCPSockets = NSMutableDictionary(capacity: 1)
        self.activeData = NSMutableDictionary(capacity: 1)
        self.activeState = NSMutableDictionary(capacity: 1)
    }
    
    deinit {
        for group in joinedMultiCastGroups {
            try! udpSocket.leaveMulticast(group: group)
        }
    }
    
    // MARK: Multicasting
    
    public func joinMulticast(group: String) throws {
        try udpSocket.joinMulticast(group: group)
        if !joinedMultiCastGroups.contains(group) {
            joinedMultiCastGroups.append(group)
        }
    }
    
    public func leaveMulticast(group: String) throws {
        try udpSocket.leaveMulticast(group: group)
        if joinedMultiCastGroups.contains(group) {
            if let index = joinedMultiCastGroups.index(of: group) {
                joinedMultiCastGroups.remove(at: index)
            }
        }
    }
    
    // MARK: Listening

    public func startListening() throws {
        do {
            try tcpSocket.startListening()
            try udpSocket.startListening()
        } catch let error as NSError {
            print(error.localizedDescription)
        }

    }
    
    public func stopListening() {
        tcpSocket.stopListening()
        udpSocket.stopListening()
    }
    
    // MARK: GCDAsyncSocketDelegate
    
    public func newSocketQueueForConnection(fromAddress address: Data, on sock: GCDAsyncSocket) -> DispatchQueue? {
        return nil
    }
    
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didAcceptNewSocket: \(newSocket))")
        #endif
        
        let activeSocket = Socket(with: newSocket)
        activeSocket.host = newSocket.connectedHost
        activeSocket.port = newSocket.connectedPort
        
        let key = NSNumber(integerLiteral: self.activeIndex)
        self.activeTCPSockets?.setObject(activeSocket, forKey: key)
        self.activeData?.setObject(NSMutableData(), forKey: key)
        self.activeState?.setObject(["socket": activeSocket, "dangling_ESC": false], forKey: key)
        
        newSocket.readData(withTimeout: -1, tag: self.activeIndex)
        
        self.activeIndex += 1
    }
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didConnectToHost: \(host):\(port)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        #if Server_Debug
            let newData = data as NSData
            debugPrint("TCP Socket: \(sock) didRead Data of length: \(newData.length), withTag: \(tag)")
        #endif
        
        guard let newActiveData = self.activeData.object(forKey: NSNumber(integerLiteral: tag)) as? NSMutableData, let newActiveState = self.activeState.object(forKey: NSNumber(integerLiteral: tag)) as? NSMutableDictionary else { return }

            print("Read Slip Data")
            OSCParser().translate(OSCData: data, version: tcpFormat, to: newActiveData, with: newActiveState)
            sock.readData(withTimeout: -1, tag: tag)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didReadPartialDataOfLength: \(partialLength), withTag: \(tag)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didWriteDataWithTag: \(tag)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didWritePartialDataOfLength: \(partialLength), withTag: \(tag)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) shouldTimeoutReadWithTag: \(tag)")
        #endif
        return 0
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) shouldTimeoutWriteWithTag: \(tag)")
        #endif
        return 0
    }
    
    public func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didCloseReadStream")
        #endif
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) didDisconnect, withError: \(String(describing: err))")
        #endif
        
        var keyOfDisconnectingSocket: Any?
        for key in self.activeTCPSockets.allKeys {
            if let socket = self.activeTCPSockets.object(forKey: key) as? Socket, socket.tcpSocket == sock {
                keyOfDisconnectingSocket = key
                break
            }
        }
        
        if let key = keyOfDisconnectingSocket {
            self.activeTCPSockets.removeObject(forKey: key)
            self.activeData.removeObject(forKey: key)
            self.activeState.removeObject(forKey: key)
        } else {
            debugPrint("Error: Server couldn't find the Socket associated with the disconnecting TCP Socket")
        }
    }
    
    public func socketDidSecure(_ sock: GCDAsyncSocket) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didSecure")
        #endif
    }
    
    // MARK: GCDAsyncUDPSocketDelegate
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) didConnectToAddress \(address)")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) didNotConnect, dueToError: \(String(describing: error?.localizedDescription))")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) didSendDataWithTag: \(tag)")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) didNotSendDataWithTag: \(tag), dueToError: \(String(describing: error?.localizedDescription))")
        #endif
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        #if Server_Debug
            let newData = data as NSData
            debugPrint("UDP Socket: \(sock) didReceiveData of Length: \(newData.length), fromAddress \(address)")
        #endif
        
        let rawReplySocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        let socket = Socket(with: rawReplySocket)
        socket.host = GCDAsyncUdpSocket.host(fromAddress: address)
        socket.port = self.udpReplyPort
        debugPrint("UDP Socket: \(sock) Did Receive Data \(data)")
        guard let packetDestination = delegate else { return }
        OSCParser().process(OSCDate: data, for: packetDestination, with: socket)
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) Did Close. With Error: \(String(describing: error?.localizedDescription))")
        #endif
    }
}
