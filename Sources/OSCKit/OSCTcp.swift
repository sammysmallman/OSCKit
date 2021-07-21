//
//  OSCTcp.swift
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

/// A helper object for OSC TCP operations.
internal struct OSCTcp {

    private init() {}

    /// Send an `OSCPacket` with a socket.
    /// - Parameters:
    ///   - packet: The `OSCPacket` to be sent.
    ///   - streamFraming: The method the packet will be encoded with.
    ///   - socket: A TCP socket.
    ///   - timeout: The timeout for the send opeartion. If the timeout value is negative,
    ///              the send operation will not use a timeout.
    ///   - tag: A convenienve tag, reported back with the
    ///          GCDAsyncSocketDelegate method `socket(_:didWriteDataWithTag:)`.
    static func send(packet: OSCPacket,
                     streamFraming: OSCTcpStreamFraming,
                     with socket: GCDAsyncSocket,
                     timeout: TimeInterval,
                     tag: Int) {
        send(data: packet.data(),
             streamFraming: streamFraming,
             with: socket,
             timeout: timeout,
             tag: tag)
    }

    /// Send the raw data of an `OSCPacket` with a socket.
    /// - Parameters:
    ///   - data: Data from an `OSCPacket`.
    ///   - streamFraming: The method the packet will be encoded with.
    ///   - socket: A TCP socket.
    ///   - timeout: The timeout for the send opeartion. If the timeout value is negative,
    ///              the send operation will not use a timeout.
    ///   - tag: A convenienve tag, reported back with the
    ///          GCDAsyncSocketDelegate method `socket(_:didWriteDataWithTag:)`.
    static func send(data: Data,
                     streamFraming: OSCTcpStreamFraming,
                     with socket: GCDAsyncSocket,
                     timeout: TimeInterval,
                     tag: Int) {
        guard data.isEmpty == false else { return }
        switch streamFraming {
        case .SLIP: // SLIP Protocol: http://www.rfc-editor.org/rfc/rfc1055.txt
            var slipData = Data()
            /*
             * Send an initial END character to flush out any data that may
             * have accumulated in the receiver due to line noise
             */
            slipData.append(slipEnd.data)
            for byte in data {
                if byte == slipEnd {
                    /*
                     * If it's the same code as an END character, we send a
                     * special two character code so as not to make the
                     * receiver think we sent an END
                     */
                    slipData.append(slipEsc.data)
                    slipData.append(slipEscEnd.data)
                } else if byte == slipEsc {
                    /*
                     * If it's the same code as an ESC character,
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
            socket.write(slipData, withTimeout: timeout, tag: tag)
        case .PLH:
            // Outgoing OSC Packets are framed using a packet length header
            var plhData = Data()
            let size = Data(UInt32(data.count).byteArray())
            plhData.append(size)
            plhData.append(data)
            socket.write(plhData, withTimeout: timeout, tag: tag)
        }
    }

    /// Decode and dispatch SLIP encoded TCP `OSCPacket`s.
    /// - Parameters:
    ///   - slipData: The latest data read from the socket.
    ///   - state: A `SocketState` object that contains the current state of the received data from a socket.
    ///   - dispatchHandler: A dispatch handler, called when a `OSCPacket` has successfully been parsed.
    ///   - packet: `OSCPacket`.
    /// - Throws: An `OSCParserError`
    static func decodeSLIP(_ slipData: Data,
                           with state: inout OSCTcp.SocketState,
                           dispatchHandler: (_ packet: OSCPacket) -> Void) throws {
        var index = 0
        // We're using a while loop rather than a for in .enumerated()
        // because we may need to adjust the index when we hit an ESC character.
        while index < slipData.count {
            let char = slipData[index]
            index += 1
            if state.danglingESC {
                state.danglingESC = false
                switch char {
                case slipEscEnd:
                    state.data.append(slipEnd.data)
                case slipEscEsc:
                    state.data.append(slipEsc.data)
                default:
                    // If byte is not one of these two, then we have a protocol violation.
                    // The best bet seems to be to leave the byte alone and just stuff
                    // it into the packet http://www.rfc-editor.org/rfc/rfc1055.txt (Page 6)
                    state.data.append(Data([char]))
                }
            } else {
                switch char {
                case slipEnd:
                    // A minor optimization: if there is no data in the packet, ignore it.
                    // This is meant to avoid bothering IP with all the empty packets generated
                    // by the duplicate END characters which are in turn sent to try to detect
                    // line noise. http://www.rfc-editor.org/rfc/rfc1055.txt (Page 5)
                    guard !state.data.isEmpty else { break }
                    do {
                        let packet = try OSCParser.packet(from: state.data)
                        state.data.removeAll()
                        dispatchHandler(packet)
                    } catch {
                        throw error
                    }
                case slipEsc:
                    if index < slipData.count {
                        // We added 1 to the index when moving into this loop
                        // so this will be the next char along from the char
                        // that we got at the beginning of this loop.
                        let nextChar = slipData[index]
                        // This is why we're using a while loop.
                        // ESC characters mean we jump forward 1.
                        index += 1
                        // We're essentially checking whether two bytes correctly
                        // represent an escaped character. If they do then we're adding
                        // the single escaped character to the data and then treating
                        // it as if we received a single byte by skipping over
                        // the extra escaped one.
                        switch nextChar {
                        case slipEscEnd:
                            state.data.append(slipEnd.data)
                        case slipEscEsc:
                            state.data.append(slipEsc.data)
                        default:
                            // If byte is not one of these two, then we have a
                            // protocol violation. The best bet seems to be to
                            // leave the byte alone and just stuff it into the packet
                            // http://www.rfc-editor.org/rfc/rfc1055.txt (Page 6)
                            state.data.append(Data([char]))
                        }
                    } else {
                        // The incoming raw data stopped in the middle of an escape sequence.
                        state.danglingESC = true
                    }
                default:
                    state.data.append(Data([char]))
                }
            }
        }
    }

    /// Decode and dispatch PLH (Packet Length Header) encoded TCP `OSCPacket`s.
    /// - Parameters:
    ///   - plhData: The latest data read from the socket.
    ///   - data: The current received data from a socket.
    ///   - dispatchHandler: A dispatch handler, called when a `OSCPacket` has successfully been parsed.
    ///   - packet: `OSCPacket`
    /// - Throws: An `OSCParserError`.
    static func decodePLH(_ plhData: Data,
                          with data: inout Data,
                          dispatchHandler: (_ packet: OSCPacket) -> Void) throws {
        var buffer = Data()
        // If there is data in the buffer, append it to the
        // beginning of our Data before working with it.
        if data.isEmpty {
            buffer.append(data)
        }
        buffer.append(plhData)
        // Start iterating over the data as soon as we
        // have something greater than UInt32. The first
        // 4 bytes will hopefully be the packet size so
        // with any luck we'll have that to process.
        while buffer.count > 4 {
            // Get the packet length of our first message.
            let packetLength = buffer.subdata(in: buffer.startIndex..<buffer.startIndex + 4)
                .withUnsafeBytes { $0.load(as: Int32.self) }
                .bigEndian
            // Check to see if we actually have enough data to process.
            if buffer.count >= packetLength + 4, packetLength > 0 {
                let dataRange = buffer.startIndex + 4..<buffer.startIndex + Int(packetLength + 4)
                let possibleOSCData = buffer.subdata(in: dataRange)
                do {
                    let packet = try OSCParser.packet(from: possibleOSCData)
                    buffer.removeSubrange(dataRange)
                    dispatchHandler(packet)
                } catch {
                    buffer.remove(at: 0)
                }
            } else {
                buffer.remove(at: 0)
            }
        }
        data = buffer
    }

    /// An object that contains the current state of the received data from a clients socket.
    ///
    /// This object contains the streaming data as it is received as well as a boolean value that
    /// indicates whether the last received data stopped in the middle of an escape sequence.
    /// The boolean `danglingESC` property is only relevant for .SLIP stream framing where
    /// the [SLIP protocol](http://www.rfc-editor.org/rfc/rfc1055.txt) uses an
    /// ESC characters to denote the end of a packet.
    struct SocketState {

        var data: Data
        var danglingESC: Bool

        init(data: Data = .init(), danglingESC: Bool = false) {
            self.data = data
            self.danglingESC = danglingESC
        }
    }

}
