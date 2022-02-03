//
//  OSCSocket.swift
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
import NetUtils

public class OSCSocket {
    
    private let timeout: TimeInterval = 3.0
    
    public private(set) var tcpSocket: GCDAsyncSocket?
    public private(set) var udpSocket: GCDAsyncUdpSocket?
    public var interface: String?
    public var host: String?
    public var port: UInt16 = 0
    
    public weak var delegate: OSCDebugDelegate?
    
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
    
    public func joinMulticast(group: String) throws {
        guard let socket = udpSocket else { return }
        if let aInterface = self.interface {
            try socket.joinMulticastGroup(group, onInterface: aInterface)
        } else {
            try socket.joinMulticastGroup(group)
        }
        delegate?.debugLog("UDP Socket - Joined Multicast Group: \(group)")
    }
    
    public func leaveMulticast(group: String) throws {
        guard let socket = udpSocket else { return }
        if let aInterface = self.interface {
            try socket.leaveMulticastGroup(group, onInterface: aInterface)
        } else {
            try socket.leaveMulticastGroup(group)
        }
        delegate?.debugLog("UDP Socket - Left Multicast Group: \(group)")
    }
    
    public func startListening() throws {
        
        if let socket = self.tcpSocket {
            if let aInterface = self.interface  {
                delegate?.debugLog("TCP Socket - Start Listening on Interface: \(aInterface), withPort: \(port)")
                try socket.accept(onInterface: aInterface, port: port)
            } else {
                delegate?.debugLog("TCP Socket - Start Listening on Port: \(port)")
                try socket.accept(onPort: port)
            }
        }
        if let socket = self.udpSocket {
            if let aInterface = self.interface {
                delegate?.debugLog("UDP Socket - Start Listening on Interface: \(aInterface), withPort: \(port)")
                try socket.bind(toPort: port, interface: aInterface)
                try socket.beginReceiving()
            } else {
                delegate?.debugLog("UDP Socket - Start Listening on Port: \(port)")
                try socket.bind(toPort: port)
                try socket.beginReceiving()
            }
        }
    }
    
    public func startListening(with groups: [String]) throws {
        if let socket = self.udpSocket {
            delegate?.debugLog("UDP Socket - Start Listening on Port: \(port)")
            try socket.bind(toPort: port)
            try socket.beginReceiving()
            for group in groups {
                try joinMulticast(group: group)
            }
        }
    }
    
    public func stopListening() {
        if self.isTCPSocket {
            guard let socket = self.tcpSocket else { return }
            socket.disconnectAfterWriting()
            delegate?.debugLog("TCP Socket - Stop Listening)")
        } else {
            guard let socket = self.udpSocket else { return }
            socket.close()
            delegate?.debugLog("UDP Socket - Stop Listening)")
        }
    }
    
    public func connect() throws {
        guard let socket = self.tcpSocket, let aHost = self.host, self.isTCPSocket else { return }
        if let aInterface = self.interface {
            try socket.connect(toHost: aHost, onPort: port, viaInterface: aInterface, withTimeout: -1)
        } else {
            try socket.connect(toHost: aHost, onPort: port, withTimeout: -1)
        }
    }
    
    public func disconnect() {
        guard let socket = self.tcpSocket else { return }
        socket.disconnect()
    }
    
    public func sendTCP(packet: OSCPacket, withStreamFraming streamFraming: OSCTCPStreamFraming) {
        if let socket = self.tcpSocket, !packet.packetData().isEmpty {
            switch streamFraming {
            case .SLIP:
                // Outgoing OSC Packets are framed using the double END SLIP protocol http://www.rfc-editor.org/rfc/rfc1055.txt
                var slipData = Data()
                /* Send an initial END character to flush out any data that may
                 * have accumulated in the receiver due to line noise
                 */
                slipData.append(slipEnd.data)
                for byte in packet.packetData() {
                    if byte == slipEnd {
                        /* If it's the same code as an END character, we send a
                         * special two character code so as not to make the
                         * receiver think we sent an END
                         */
                        slipData.append(slipEsc.data)
                        slipData.append(slipEscEnd.data)
                    } else if byte == slipEsc {
                        /* If it's the same code as an ESC character,
                         * we send a special two character code so as not
                         * to make the receiver think we sent an ESC
                         */
                        slipData.append(slipEsc.data)
                        slipData.append(slipEscEsc.data)
                    } else {
                        // Otherwise, we just send the character
                        slipData.append(byte.data)
                    }
                }
                // Tell the receiver that we're done sending the packet
                slipData.append(slipEnd.data)
                socket.write(slipData, withTimeout: timeout, tag: slipData.count)
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
                let enableBroadcast = Interface.allInterfaces().contains(where: { $0.name == interface && ($0.broadcastAddress == host || "255.255.255.255" == host ) })
                do {
                    try socket.enableBroadcast(enableBroadcast)
                } catch {
                    delegate?.debugLog("Could not \(enableBroadcast == true ? "Enable" : "Disable") the broadcast flag on UDP Socket.")
                }
                do {
                    // Port 0 means that the OS should choose a random ephemeral port for this socket.
                   try socket.bind(toPort: 0, interface: aInterface)
                } catch {
                    delegate?.debugLog("Warning: \(socket) unable to bind interface")
                }
            }
            if let aHost = host {
                socket.send(packet.packetData(), toHost: aHost, port: self.port, withTimeout: timeout, tag: 0)
                print("Sending", aHost, port)
                socket.closeAfterSending()
            }
        }
    }    
    
}

extension OSCSocket: CustomStringConvertible {
    public var description: String {
        if isTCPSocket {
            return "TCP Socket \(self.host ?? "No Host"):\(self.port) isConnected = \(isConnected)"
        } else {
            return "UDP Socket \(self.host ?? "No Host"):\(self.port)"
        }
    }
}

extension Numeric {
    
    var data: Data {
        var source = self
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
    
}


