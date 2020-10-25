//
//  OSCSocket.swift
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

// MARK: Socket

import Foundation
import CocoaAsyncSocket
import NetUtils

extension Socket: CustomStringConvertible {
    public var description: String {
        if isTCPSocket {
            return "TCP Socket \(self.host ?? "No Host"):\(self.port) isConnected = \(isConnected)"
        } else {
            return "UDP Socket \(self.host ?? "No Host"):\(self.port)"
        }
    }
}

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
    
    public func reusePort(reuse: Bool) throws {
        guard let socket = self.udpSocket else { return }
        try socket.enableReusePort(reuse)
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
    
    func joinMulticast(group: String) throws {
        guard let socket = udpSocket else { return }
        if let aInterface = self.interface {
            try socket.joinMulticastGroup(group, onInterface: aInterface)
        } else {
            try socket.joinMulticastGroup(group)
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
    
    func startListening(with groups: [String]) throws {
        if let socket = self.udpSocket {
            #if Socket_Debug
            debugPrint("UDP Socket - Start Listening on Port: \(port)")
            #endif
            try socket.bind(toPort: port)
            try socket.beginReceiving()
            for group in groups {
                try joinMulticast(group: group)
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
    
    public func sendTCP(packet: OSCPacket, withStreamFraming streamFraming: OSCTCPStreamFraming) {
        if let socket = self.tcpSocket, !packet.packetData().isEmpty {
            switch streamFraming {
            case .SLIP:
                // Outgoing OSC Packets are framed using the double END SLIP protocol http://www.rfc-editor.org/rfc/rfc1055.txt
                let escENDbytes: [UInt8] = [SLIP_ESC, SLIP_ESC_END]
                let escEND = UInt16(escENDbytes[0]) << 8 | UInt16(escENDbytes[1])
                let escESCbytes: [UInt8] = [SLIP_ESC, SLIP_ESC_ESC]
                let escESC = UInt16(escESCbytes[0]) << 8 | UInt16(escESCbytes[1])
                
                var slipData = Data()
                var endValue = SLIP_END.bigEndian
                slipData.append(UnsafeBufferPointer(start: &endValue, count: 1))
                
                for byte in packet.packetData() {
                    if byte == SLIP_END {
                        var escENDValue = escEND.bigEndian
                        slipData.append(UnsafeBufferPointer(start: &escENDValue, count: 2))
                    } else if byte == SLIP_ESC {
                        var escESCValue = escESC.bigEndian
                        slipData.append(UnsafeBufferPointer(start: &escESCValue, count: 2))
                    } else {
                        var byteValue = byte
                        slipData.append(UnsafeBufferPointer(start: &byteValue, count: 1))
                    }
                }
                slipData.append(UnsafeBufferPointer(start: &endValue, count: 1))
                socket.write(slipData, withTimeout: timeout, tag: packet.packetData().count)
            case .PLH:
                // Outgoing OSC Packets are framed using a packet length header
                var plhData = Data()
                let size = Data(UInt32(packet.packetData().count).byteArray())
                plhData.append(size)
                plhData.append(packet.packetData())
                socket.write(plhData, withTimeout: timeout, tag: plhData.count)
            }
        }
    }
    
    public func sendUDP(packet: OSCPacket) {
        if let socket = self.udpSocket {
            if let aInterface = self.interface {
                let enableBroadcast = Interface.allInterfaces().contains(where: { $0.name == interface && $0.broadcastAddress == host })
                do {
                    try socket.enableBroadcast(enableBroadcast)
                } catch {
                    debugPrint("Could not \(enableBroadcast == true ? "Enable" : "Disable") the broadcast flag on UDP Socket.")
                }
                do {
                    // Port 0 means that the OS should choose a random ephemeral port for this socket.
                   try socket.bind(toPort: 0, interface: aInterface)
                } catch {
                    debugPrint("Warning: \(socket) unable to bind interface")
                }
            }
            if let aHost = host {
                socket.send(packet.packetData(), toHost: aHost, port: self.port, withTimeout: timeout, tag: 0)
                socket.closeAfterSending()
            }
        }
    }    
    
}
