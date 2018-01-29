//
//  OSCSocket.swift
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

// MARK: Socket

import Foundation
import CocoaAsyncSocket

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
    
    private enum slipCharacter: Int {
        case END = 0o0300       /* indicates end of packet */
        case ESC = 0o0333       /* indicates byte stuffing */
        case ESC_END = 0o0334   /* ESC ESC_END means END data byte */
        case ESC_ESC = 0o0335   /* ESC ESC_ESC means ESC data byte */
    }
    
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
    
    func sendTCP(packet: OSCPacket, withStreamFraming streamFraming: OSCParser.streamFraming) {
        if let socket = self.tcpSocket, !packet.packetData().isEmpty {
            switch streamFraming {
            case .SLIP:
                // Outgoing OSC Packets are framed using the double END SLIP protocol http://www.rfc-editor.org/rfc/rfc1055.txt
                let escENDbytes: [UInt8] = [UInt8(slipCharacter.ESC.rawValue), UInt8(slipCharacter.ESC_END.rawValue)]
                let escEND = UInt16(escENDbytes[0]) << 8 | UInt16(escENDbytes[1])
                let escESCbytes: [UInt8] = [UInt8(slipCharacter.ESC.rawValue), UInt8(slipCharacter.ESC_ESC.rawValue)]
                let escESC = UInt16(escESCbytes[0]) << 8 | UInt16(escESCbytes[1])
                let end = UInt8(slipCharacter.END.rawValue)
                
                var slipData = Data()
                var endValue = end.bigEndian
                slipData.append(UnsafeBufferPointer(start: &endValue, count: 1))
                
                for byte in packet.packetData() {
                    if byte == UInt8(slipCharacter.END.rawValue) {
                        var escENDValue = escEND.bigEndian
                        slipData.append(UnsafeBufferPointer(start: &escENDValue, count: 2))
                    } else if byte == UInt8(slipCharacter.ESC.rawValue) {
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
                let size = Data(bytes: UInt32(packet.packetData().count).byteArray())
                plhData.append(size)
                plhData.append(packet.packetData())
                socket.write(plhData, withTimeout: timeout, tag: plhData.count)
            }
        }
    }
    
    func sendUDP(packet: OSCPacket) {
        if let socket = self.udpSocket, !packet.packetData().isEmpty {
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
                socket.send(packet.packetData(), toHost: aHost, port: self.port, withTimeout: timeout, tag: 0)
                socket.closeAfterSending()
            }
        }
    }    
    
}
