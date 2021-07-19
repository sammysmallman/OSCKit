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

    /// Send an `OSCPacket` with a socket.
    /// - Parameters:
    ///   - packet: The `OSCPacket` to be sent.
    ///   - streamFraming: The method in with the packet will be encoded.
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
        let packetData = packet.packetData()
        guard packetData.isEmpty == false else { return }
        switch streamFraming {
        case .SLIP: // SLIP Protocol: http://www.rfc-editor.org/rfc/rfc1055.txt
            var slipData = Data()
            /*
             * Send an initial END character to flush out any data that may
             * have accumulated in the receiver due to line noise
             */
            slipData.append(slipEnd.data)
            for byte in packetData {
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
            let size = Data(UInt32(packetData.count).byteArray())
            plhData.append(size)
            plhData.append(packetData)
            socket.write(plhData, withTimeout: timeout, tag: tag)
        }
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
