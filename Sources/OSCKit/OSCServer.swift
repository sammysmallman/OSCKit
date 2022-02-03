//
//  OSCServer.swift
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

public class OSCServer: NSObject, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    
    private(set) var tcpSocket: OSCSocket!
    private(set) var udpSocket: OSCSocket!
    
    private var activeTCPSockets: NSMutableDictionary!  // Sockets keyed by index of when the connection was accepted.
    private var activeData: NSMutableDictionary!        // NSMutableData keyed by index; buffers the incoming data.
    private var activeState: NSMutableDictionary!       // NSMutableDictionary keyed by index; stores state of incoming data.
    private var activeIndex: Int = 0
    private var joinedMulticastGroups: [String] = []
    
    /// The delegate which receives debug log messages from this producer.
    public weak var debugDelegate: OSCDebugDelegate?
    
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
                debugDelegate?.debugLog("Error: \(error.localizedDescription)")
            }
        }
    }
    public var streamFraming: OSCTCPStreamFraming = .SLIP
    
    private var udpReplyPort: UInt16? = nil
    public var delegate: OSCPacketDestination?
    
    public init(dispatchQueue: DispatchQueue) {
        super.init()
        let rawTCPSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatchQueue)
        let rawUDPSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatchQueue)
        self.tcpSocket = OSCSocket(with: rawTCPSocket)
        self.udpSocket = OSCSocket(with: rawUDPSocket)
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
        } catch {
            debugDelegate?.debugLog(error.localizedDescription)
        }
    }
    
    public func stopListening() {
        tcpSocket.stopListening()
        for group in joinedMulticastGroups {
            do {
                try udpSocket.leaveMulticast(group: group)
            } catch {
                debugDelegate?.debugLog(error.localizedDescription)
            }
        }
        udpSocket.stopListening()
    }
    
    // MARK: GCDAsyncSocketDelegate
    
    public func newSocketQueueForConnection(fromAddress address: Data, on sock: GCDAsyncSocket) -> DispatchQueue? {
        return nil
    }
    
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didAcceptNewSocket: \(newSocket))")
        
        let activeSocket = OSCSocket(with: newSocket)
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
        debugDelegate?.debugLog("TCP Socket: \(sock) didConnectToHost: \(host):\(port)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let delegate = self.delegate else { return }
        debugDelegate?.debugLog("TCP Socket: \(sock) didRead Data of length: \(data.count), withTag: \(tag)")

        guard let newActiveData = self.activeData.object(forKey: tag) as? NSMutableData, let newActiveState = self.activeState.object(forKey: tag) as? NSMutableDictionary else {
            return
        }
        do {
            try OSCParser().translate(OSCData: data, streamFraming: streamFraming, to: newActiveData, with: newActiveState, andDestination: delegate)
            sock.readData(withTimeout: -1, tag: tag)
        } catch {
            debugDelegate?.debugLog("Error: \(error)")
        }
        
    }
    
    public func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didReadPartialDataOfLength: \(partialLength), withTag: \(tag)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didWriteDataWithTag: \(tag)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didWritePartialDataOfLength: \(partialLength), withTag: \(tag)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        debugDelegate?.debugLog("TCP Socket: \(sock) shouldTimeoutReadWithTag: \(tag)")
        return 0
    }
    
    public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        debugDelegate?.debugLog("TCP Socket: \(sock) shouldTimeoutWriteWithTag: \(tag)")
        return 0
    }
    
    public func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didCloseReadStream")
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didDisconnect, withError: \(String(describing: err))")
        if sock != tcpSocket.tcpSocket {
            var keyOfDisconnectingSocket: Any?
            for key in self.activeTCPSockets.allKeys {
                if let socket = self.activeTCPSockets.object(forKey: key) as? OSCSocket, socket.tcpSocket == sock {
                    keyOfDisconnectingSocket = key
                    break
                }
            }
            if let key = keyOfDisconnectingSocket {
                self.activeTCPSockets.removeObject(forKey: key)
                self.activeData.removeObject(forKey: key)
                self.activeState.removeObject(forKey: key)
            } else {
                debugDelegate?.debugLog("Error: Server couldn't find the Socket associated with the disconnecting TCP Socket")
            }
        } else {
            debugDelegate?.debugLog("Server disconnecting its own listening TCP Socket")
        }

    }
    
    public func socketDidSecure(_ sock: GCDAsyncSocket) {
        debugDelegate?.debugLog("TCP Socket: \(sock) didSecure")
    }
    
    // MARK: GCDAsyncUDPSocketDelegate
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didConnectToAddress \(address)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didNotConnect, dueToError: \(String(describing: error?.localizedDescription))")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didSendDataWithTag: \(tag)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) didNotSendDataWithTag: \(tag), dueToError: \(String(describing: error?.localizedDescription))")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {

        debugDelegate?.debugLog("UDP Socket: \(sock) didReceiveData of Length: \(data.count), fromAddress \(address)")
        
        let rawReplySocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        let socket = OSCSocket(with: rawReplySocket)
        socket.interface = interface
        socket.host = GCDAsyncUdpSocket.host(fromAddress: address)
        if let port = udpReplyPort {
            socket.port = port
        } else {
            socket.port = GCDAsyncUdpSocket.port(fromAddress: address)
        }
        guard let packetDestination = delegate else { return }
        do {
            try  OSCParser().process(OSCDate: data, for: packetDestination, with: socket)
        } catch OSCParserError.unrecognisedData {
            debugDelegate?.debugLog("Error: Unrecognized data \(data)")
        } catch {
            debugDelegate?.debugLog("Other error: \(error)")
        }
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        debugDelegate?.debugLog("UDP Socket: \(sock) Did Close. With Error: \(String(describing: error?.localizedDescription))")
    }
}

