//
//  OSCServer.swift
//  OSCKit
//
//  Created by Sam Smallman on 29/10/2017.
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

// MARK: Server

import Foundation
import CocoaAsyncSocket

public class OSCServer: NSObject, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    
    private(set) var tcpSocket: Socket!
    private(set) var udpSocket: Socket!
    
    private var activeTCPSockets: NSMutableDictionary!  // Sockets keyed by index of when the connection was accepted.
    private var activeData: NSMutableDictionary!        // NSMutableData keyed by index; buffers the incoming data.
    private var activeState: NSMutableDictionary!       // NSMutableDictionary keyed by index; stores state of incoming data.
    private var activeIndex: Int = 0
    private var joinedMulticastGroups: [String] = []
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
    public var reusePort: Bool = false {
        willSet {
            stopListening()
            do {
                try self.udpSocket?.reusePort(reuse: newValue)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    public var streamFraming: OSCParser.streamFraming = .SLIP
    
    private var udpReplyPort: UInt16 = 0
    public var delegate: OSCPacketDestination?
    
    public init(dispatchQueue: DispatchQueue) {
        super.init()
        let rawTCPSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatchQueue)
        let rawUDPSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatchQueue)
        self.tcpSocket = Socket(with: rawTCPSocket)
        self.udpSocket = Socket(with: rawUDPSocket)
        self.activeTCPSockets = NSMutableDictionary(capacity: 1)
        self.activeData = NSMutableDictionary(capacity: 1)
        self.activeState = NSMutableDictionary(capacity: 1)
    }
    
    convenience public override init() {
        self.init(dispatchQueue: DispatchQueue.main)
    }
    
    deinit {
        for group in joinedMulticastGroups {
            try! udpSocket.leaveMulticast(group: group)
        }
        stopListening()
    }
    
    // MARK: Multicasting
    
    public func startListening(with groups: [String]) throws {
        joinedMulticastGroups = groups
        try udpSocket.startListening(with: groups)
    }
    
    public func joinMulticast(group: String) throws {
        try udpSocket.joinMulticast(group: group)
        if !joinedMulticastGroups.contains(group) {
            joinedMulticastGroups.append(group)
        }
    }
    
    public func leaveMulticast(group: String) throws {
        try udpSocket.leaveMulticast(group: group)
        if joinedMulticastGroups.contains(group) {
            if let index = joinedMulticastGroups.firstIndex(of: group) {
                joinedMulticastGroups.remove(at: index)
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
        for group in joinedMulticastGroups {
            do {
                try udpSocket.leaveMulticast(group: group)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
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
        let dictionary: NSMutableDictionary = ["socket": activeSocket, "dangling_ESC": false]
        self.activeState?.setObject(dictionary, forKey: key)
        newSocket.readData(withTimeout: -1, tag: self.activeIndex)
        
        self.activeIndex += 1
    }
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didConnectToHost: \(host):\(port)")
        #endif
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let delegate = self.delegate else { return }
        #if Server_Debug
            debugPrint("TCP Socket: \(sock) didRead Data of length: \(data.count), withTag: \(tag)")
        #endif

        guard let newActiveData = self.activeData.object(forKey: tag) as? NSMutableData, let newActiveState = self.activeState.object(forKey: tag) as? NSMutableDictionary else {
            return
        }
        do {
            try OSCParser().translate(OSCData: data, streamFraming: streamFraming, to: newActiveData, with: newActiveState, andDestination: delegate)
            sock.readData(withTimeout: -1, tag: tag)
        } catch {
            print("Error: \(error)")
        }
        
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
            debugPrint("TCP Socket: \(sock) didDisconnect, withError: \(String(describing: err))")
        #endif
        if sock != tcpSocket.tcpSocket {
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
                #if Server_Debug
                    debugPrint("Error: Server couldn't find the Socket associated with the disconnecting TCP Socket")
                #endif
            }
        } else {
            #if Server_Debug
                debugPrint("Server disconnecting its own listening TCP Socket")
            #endif
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
        socket.interface = interface
        socket.host = GCDAsyncUdpSocket.host(fromAddress: address)
        socket.port = port
        guard let packetDestination = delegate else { return }
        do {
            try  OSCParser().process(OSCDate: data, for: packetDestination, with: socket)
        } catch OSCParserError.unrecognisedData {
            debugPrint("Error: Unrecognized data \(data)")
        } catch {
            print("Other error: \(error)")
        }
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        #if Server_Debug
            debugPrint("UDP Socket: \(sock) Did Close. With Error: \(String(describing: error?.localizedDescription))")
        #endif
    }
}
