//
//  Socket.swift
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

// MARK: Socket

import Foundation
import CocoaAsyncSocket

public class Socket {
    
    private let timeout: TimeInterval = 3.0
    
    public private(set) var tcpSocket: GCDAsyncSocket?
    public private(set) var udpSocket: GCDAsyncUdpSocket?
    public var interface: String?
    public var host: String?
    public var port: UInt16 = 0
    
    public var isConnected: Bool {
        get {
            if self.isTCPSocket {
                guard let socket = self.tcpSocket else { return false }
                return socket.isConnected
            } else {
                guard let socket = self.udpSocket else { return false }
                return socket.isConnected()
            }
        }
    }
    
    public var isTCPSocket: Bool {
        get {
            return self.tcpSocket != nil
        }
    }
    
    public var isUDPSocket: Bool {
        get {
            return self.udpSocket != nil
        }
    }
    
    init(with tcpSocket: GCDAsyncSocket) {
        self.tcpSocket = tcpSocket
        self.udpSocket = nil
        self.interface = nil
        self.host = "localhost"
    }
    
    init(with udpSocket: GCDAsyncUdpSocket) {
        self.udpSocket = udpSocket
        self.tcpSocket = nil
        self.interface = nil
        self.host = "localhost"
    }
    
    deinit {
        self.tcpSocket?.delegate = nil
        self.tcpSocket?.disconnect()
        self.tcpSocket = nil
        
        self.udpSocket?.setDelegate(nil)
        self.udpSocket = nil
    }
    
    //    override var description : String {
    //        if self.isTCPSocket() {
    //            return "TCP Socket \(String(reflecting: self.host)):\(String(reflecting: self.port)), isConnected = \(isConnected())"
    //        } else {
    //            return "UDP Socket \(String(reflecting: self.host)):\(String(reflecting: self.port))"
    //        }
    //    }
    
    func joinMulticast(group: String) throws {
        guard let socket = udpSocket else { return }
        if let aInterface = self.interface {
            try socket.joinMulticastGroup(group, onInterface: aInterface)
        } else {
            try socket.joinMulticastGroup(group)
            print("Without Interface")
        }
        #if Socket_Debug
            debugPrint("UDP Socket - Joined Multicast Group: \(group)")
        #endif
    }
    
    func leaveMulticast(group: String) throws {
        guard let socket = udpSocket else { return }
        if let aInterface = self.interface {
            try socket.leaveMulticastGroup(group, onInterface: aInterface)
        } else {
            try socket.leaveMulticastGroup(group)
        }
        #if Socket_Debug
            debugPrint("UDP Socket - Left Multicast Group: \(group)")
        #endif
    }
    
    func startListening() throws {
        
        if let socket = self.tcpSocket {
            if let aInterface = self.interface  {
                #if Socket_Debug
                    debugPrint("TCP Socket - Start Listening on Interface: \(aInterface), withPort: \(port)")
                #endif
                try socket.accept(onInterface: aInterface, port: port)
            } else {
                #if Socket_Debug
                    debugPrint("TCP Socket - Start Listening on Port: \(port)")
                #endif
                try socket.accept(onPort: port)
            }
        }
        if let socket = self.udpSocket {
             print("UDP Socket")
            if let aInterface = self.interface {
                #if Socket_Debug
                    debugPrint("UDP Socket - Start Listening on Interface: \(aInterface), withPort: \(port)")
                #endif
                try socket.bind(toPort: port, interface: aInterface)
                try socket.beginReceiving()
            } else {
                #if Socket_Debug
                    debugPrint("UDP Socket - Start Listening on Port: \(port)")
                #endif
                try socket.bind(toPort: port)
                try socket.beginReceiving()
            }
        }
    }
    
    func stopListening() {
        if self.isTCPSocket {
            guard let socket = self.tcpSocket else { return }
            socket.disconnectAfterWriting()
            #if Socket_Debug
                debugPrint("TCP Socket - Stop Listening)")
            #endif
        } else {
            guard let socket = self.udpSocket else { return }
            socket.close()
            #if Socket_Debug
                debugPrint("UDP Socket - Stop Listening)")
            #endif
        }
    }
    
    func connect() throws {
        guard let socket = self.tcpSocket, let aHost = self.host, self.isTCPSocket else { return }
        if let aInterface = self.interface {
            try socket.connect(toHost: aHost, onPort: port, viaInterface: aInterface, withTimeout: -1)
        } else {
            try socket.connect(toHost: aHost, onPort: port, withTimeout: -1)
        }
    }
    
    func disconnect() {
        guard let socket = self.tcpSocket else { return }
        socket.disconnect()
    }
    
    func sendPacket(with data: Data) {
        if let socket = self.tcpSocket {
            let aData = data as NSData
            socket.write(data, withTimeout: timeout, tag: aData.length)
        }
        if let socket = self.udpSocket {
            if let aInterface = self.interface {
                do {
                    // Port 0 means that the OS should choose a random ephemeral port for this socket.
                   try socket.bind(toPort: 0, interface: aInterface)
                } catch {
                    debugPrint("Warning: \(socket) unable to bind interface")
                }
            }
            do {
                try socket.enableBroadcast(true)
            } catch {
                debugPrint("Warning: \(socket) unable to enable UDP broadcast")
            }
            if let aHost = host {
                socket.send(data, toHost: aHost, port: self.port, withTimeout: timeout, tag: 0)
                socket.closeAfterSending()
            }
        }
    }    
    
}
