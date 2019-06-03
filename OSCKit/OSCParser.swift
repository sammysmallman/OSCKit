//
//  OSCParser.swift
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

public enum OSCParserError: Error {
    case unrecognisedData
    case noSocket
    case cantConfirmDanglingESC
    case cantParseAddressPattern
    case cantParseTypeTagString
    case cantParseOSCString
    case cantParseOSCInt
    case cantParseOSCFloat
    case cantParseOSCBlob
    case cantParseOSCTimeTag
    case cantParseSizeOfElement
    case cantParseTypeOfElement
    case cantParseBundleElement
}

// MARK: Parser

public class OSCParser {
    
    private enum slipCharacter: Int {
        case END = 0o0300       /* indicates end of packet */
        case ESC = 0o0333       /* indicates byte stuffing */
        case ESC_END = 0o0334   /* ESC ESC_END means END data byte */
        case ESC_ESC = 0o0335   /* ESC ESC_ESC means ESC data byte */
    }
    
    public enum streamFraming {
        case SLIP
        case PLH
    }
    
    private var plhDataBuffer: Data?
    
    public func process(OSCDate data: Data, for destination: OSCPacketDestination, with replySocket: Socket) throws {
        if !data.isEmpty {
            let firstCharacter = data.prefix(upTo: 1)
            guard let string = String(data: firstCharacter, encoding: .utf8) else {
                throw OSCParserError.unrecognisedData
            }
            if string == "/" { // OSC Messages begin with /
                do {
                    try process(OSCMessageData: data, for: destination, with: replySocket)
                } catch {
                    throw error
                }
            } else if string == "#" { // OSC Bundles begin with #
                do {
                    try process(OSCBundleData: data, for: destination, with: replySocket)
                } catch {
                    throw error
                }
            } else {
                throw OSCParserError.unrecognisedData
            }
        }
    }
    
    private func process(OSCMessageData data: Data, for destination: OSCPacketDestination, with replySocket: Socket) throws {
        var startIndex = 0
        do {
            let message = try parseOSCMessage(with: data, startIndex: &startIndex)
            message.replySocket = replySocket
            destination.take(message: message)
        } catch {
            throw error
        }
    }
    
    private func process(OSCBundleData data: Data, for destination: OSCPacketDestination, with replySocket: Socket) throws {
        do {
            let  bundle = try parseOSCBundle(with: data)
            bundle.replySocket = replySocket
            destination.take(bundle: bundle)
        } catch {
            throw error
        }
    }
    
    public func translate(OSCData tcpData: Data, streamFraming: streamFraming, to data: NSMutableData, with state: NSMutableDictionary, andDestination destination: OSCPacketDestination) throws {
        switch streamFraming {
        case .SLIP:
            // There are two versions of OSC. OSC 1.1 frames messages using the SLIP protocol: http://www.rfc-editor.org/rfc/rfc1055.txt
            guard let socket = state.object(forKey: "socket") as? Socket else {
                throw OSCParserError.noSocket
            }
            guard let dangling_ESC = state.object(forKey: "dangling_ESC") as? Bool else {
                throw OSCParserError.cantConfirmDanglingESC
            }
            
            let end = UInt8(slipCharacter.END.rawValue)
            let esc = UInt8(slipCharacter.ESC.rawValue)
            
            let length = tcpData.count
            let buffer = tcpData
            for (index, byte) in buffer.enumerated() {
                if dangling_ESC {
                    //                    dangling_ESC = false
                    state.setValue(false, forKey: "dangling_ESC")
                    if byte == UInt8(slipCharacter.ESC_END.rawValue) {
                        data.append(Data([end]))
                    } else if byte == UInt8(slipCharacter.ESC_ESC.rawValue) {
                        data.append(Data([esc]))
                    } else {
                        // Protocol violation. Pass the byte along and hope for the best.
                        data.append(Data([buffer[index]]))
                    }
                } else if byte == end {
                    // The data is now a complete message.
                    let newData = data as Data
                    do {
                        try process(OSCDate: newData, for: destination, with: socket)
                        data.setData(Data())
                    } catch {
                        throw error
                    }
                } else if byte == esc {
                    if index + 1 < length {
                        if buffer[index + 1] == UInt8(slipCharacter.ESC_END.rawValue) {
                            data.append(Data([end]))
                        } else if buffer[index + 1] == UInt8(slipCharacter.ESC_ESC.rawValue) {
                            data.append(Data([esc]))
                        } else {
                            // Protocol violation. Pass the byte along and hope for the best.
                            data.append(Data([buffer[index + 1]]))
                        }
                    } else {
                        // The incoming raw data stopped in the middle of an escape sequence.
                        state.setValue(true, forKey: "dangling_ESC")
                    }
                } else {
                    data.append(Data([buffer[index]]))
                }
            }
        case .PLH:
            guard let socket = state.object(forKey: "socket") as? Socket else {
                throw OSCParserError.noSocket
            }
            var buffer = Data()
            // If there is data in the plhDataBuffer, append it to the beginning of our Data before working with it.
            if let data = plhDataBuffer, !data.isEmpty {
                buffer.append(data)
            }
            buffer.append(tcpData)
            // Start iterating over the data as soon as we have something greater than UInt32.
            // The first 4 bytes will hopefully be the packet size so with any luck we'll have that to process.
            while buffer.count > 4 {
                // Get the packet length of our first message.
//                let packetLength = buffer.subdata(in: buffer.startIndex..<buffer.startIndex + 4).withUnsafeBytes({ $0.load(as: Int32.self) })
                let packetLength = buffer.subdata(in: buffer.startIndex..<buffer.startIndex + 4).withUnsafeBytes { (pointer: UnsafePointer<Int32>) -> Int32 in
                    return pointer.pointee.bigEndian
                }
                // Check to see if we actually have enough data to process.
                if buffer.count >= packetLength + 4, packetLength > 0 {
                    let dataRange = buffer.startIndex + 4..<buffer.startIndex + Int(packetLength + 4)
                    let possibleOSCData = buffer.subdata(in: dataRange)
                    do {
                        try process(OSCDate: possibleOSCData, for: destination, with: socket)
                        buffer.removeSubrange(dataRange)
                    } catch {
                        buffer.remove(at: 0)
                    }
                } else {
                    buffer.remove(at: 0)
                }
            }
            plhDataBuffer = buffer
            socket.tcpSocket?.readData(withTimeout: -1, tag: 0)
        }
    }
    
    private func parseOSCMessage(with data: Data, startIndex firstIndex: inout Int) throws -> OSCMessage {
        guard let addressPattern = oscString(with: data, startIndex: &firstIndex) else {
            throw OSCParserError.cantParseAddressPattern
        }
        guard let typeTagString = oscString(with: data, startIndex: &firstIndex) else {
            throw OSCParserError.cantParseTypeTagString
        }
        // If the Type Tag String starts with "," and has 1 or more characters after, we possibly have some arguments.
        var arguments: [Any] = []
        if typeTagString.first == "," && typeTagString.count > 1 {
            // Remove "," as we will iterate over the different type of tags.
            var typeTags = typeTagString
            typeTags.removeFirst()
            for tag in typeTags {
                switch tag {
                case "s":
                    guard let stringArgument = oscString(with: data, startIndex: &firstIndex) else {
                        throw OSCParserError.cantParseOSCString
                    }
                    arguments.append(stringArgument)
                case "i":
                    guard let intArgument = oscInt(with: data, startIndex: &firstIndex) else {
                        throw OSCParserError.cantParseOSCInt
                    }
                    arguments.append(intArgument)
                case "f":
                    guard let floatArgument = oscFloat(with: data, startIndex: &firstIndex) else {
                        throw OSCParserError.cantParseOSCFloat
                    }
                    arguments.append(floatArgument)
                case "b":
                    guard let blobArgument = oscBlob(with: data, startIndex: &firstIndex) else {
                        throw OSCParserError.cantParseOSCBlob
                    }
                    arguments.append(blobArgument)
                case "t":
                    guard let timeTagArgument = oscTimeTag(withData: data, startIndex: &firstIndex) else {
                        throw OSCParserError.cantParseOSCTimeTag
                    }
                    arguments.append(timeTagArgument)
                case "T":
                    arguments.append(OSCArgument.oscTrue)
                case "F":
                    arguments.append(OSCArgument.oscFalse)
                case "N":
                    arguments.append(OSCArgument.oscNil)
                case "I":
                    arguments.append(OSCArgument.oscImpulse)
                default:
                    continue
                }
            }
        }
        return OSCMessage(messageWithAddressPattern: addressPattern, arguments: arguments)
    }
    
    private func parseOSCBundle(with data: Data) throws -> OSCBundle {
        // Check the Bundle has a string prefix of "#bundle#
        if "#bundle".oscStringData() == data.subdata(in: Range(0...7)) {
            var startIndex = 8
            // All Bundles have a Time Tag, even if its just immedietly - Seconds 0, Fractions 1.
            guard let timeTag = oscTimeTag(withData: data, startIndex: &startIndex) else {
                throw OSCParserError.cantParseOSCTimeTag
            }
            // Does the Bundle have any data in it? Bundles could be empty with no messages or bundles within.
            if startIndex < data.endIndex {
                let bundleData = data.subdata(in: startIndex..<data.endIndex)
                let size = Int32(data.count - startIndex)
                do {
                    let elements = try parseOSCBundleElements(with: 0, data: bundleData, andSize: size)
                    return OSCBundle(bundleWithElements: elements, timeTag: timeTag)
                } catch {
                    throw error
                }
            } else {
                return OSCBundle(bundleWithElements: [], timeTag: timeTag)
            }
        } else {
            throw OSCParserError.unrecognisedData
        }
    }
    
    func parseOSCBundleElements(with index: Int, data: Data, andSize size: Int32) throws -> [OSCPacket] {
        var elements: [OSCPacket] = []
        var startIndex = 0
        var buffer: Int32 = 0
        repeat {
            guard let elementSize = oscInt(with: data, startIndex: &startIndex) else {
                throw OSCParserError.cantParseSizeOfElement
            }
            buffer += 4
            guard let string = String(data: data.subdata(in: startIndex..<data.endIndex).prefix(upTo: 1), encoding: .utf8) else {
                throw OSCParserError.cantParseTypeOfElement
            }
            if string == "/" { // OSC Messages begin with /
                do {
                    let newElement = try parseOSCMessage(with: data, startIndex: &startIndex)
                    elements.append(newElement)
                } catch {
                    throw error
                }
            } else if string == "#" { // OSC Bundles begin with #
                // #bundle takes up 8 bytes
                startIndex += 8
                // All Bundles have a Time Tag, even if its just immedietly - Seconds 0, Fractions 1.
                guard let timeTag = oscTimeTag(withData: data, startIndex: &startIndex) else {
                    throw OSCParserError.cantParseOSCTimeTag
                }
                if startIndex < size {
                    let bundleData = data.subdata(in: startIndex..<startIndex + Int(elementSize) - 16)
                    do {
                        let bundleElements = try parseOSCBundleElements(with: index, data: bundleData, andSize: Int32(bundleData.count))
                        elements.append(OSCBundle(bundleWithElements: bundleElements, timeTag: timeTag))
                    } catch {
                        throw error
                    }
                } else {
                    elements.append(OSCBundle(bundleWithElements: [], timeTag: timeTag))
                }
            } else {
                throw OSCParserError.unrecognisedData
            }
            buffer += elementSize
            startIndex = index + Int(buffer)
        } while buffer < size
        return elements
    }
    
    private func oscString(with buffer: Data, startIndex firstIndex: inout Int) -> String? {
        // Read the data from the start index until you hit a zero, the part before will be the string data.
        for (index, byte) in buffer[firstIndex...].enumerated() where byte == 0 {
            guard let result = String(data: buffer[firstIndex..<(firstIndex + index)], encoding: .utf8) else { return nil }
            /* An OSC String is a sequence of non-null ASCII characters followed by a null, followed by 0-3 additional null characters to make the total number of bits a multiple of 32 Bits, 4 Bytes.
             */
            firstIndex = (4 * Int(ceil(Double(firstIndex + index + 1) / 4)))
            return result
        }
        return nil
    }
    
    private func oscInt(with buffer: Data, startIndex firstIndex: inout Int) -> Int32? {
        // An OSC Int is a 32-bit big-endian two's complement integer.
        let result = buffer.subdata(in: firstIndex..<firstIndex + 4).withUnsafeBytes { (pointer: UnsafePointer<Int32>) -> Int32 in
            return pointer.pointee.bigEndian
        }
        firstIndex += 4
        return result
    }
    
    private func oscFloat(with buffer: Data, startIndex firstIndex: inout Int) -> Float32? {
        // An OSC Float is a 32-bit big-endian IEEE 754 floating point number.
        let result = buffer.subdata(in: firstIndex..<firstIndex + 4).withUnsafeBytes { (pointer: UnsafePointer<CFSwappedFloat32>) -> Float32 in
            return CFConvertFloat32SwappedToHost(pointer.pointee)
        }
        firstIndex += 4
        return result
    }
    
    private func oscBlob(with buffer: Data, startIndex firstIndex: inout Int) -> Data? {
        /* An int32 size count, followed by that many 8-bit bytes of arbitrary binary data, followed by 0-3 additional zero bytes to make the total number of bits a multiple of 32, 4 bytes
         */
        let blobSize = buffer.subdata(in: firstIndex..<firstIndex + 4).withUnsafeBytes { (pointer: UnsafePointer<Int32>) -> Int32 in
            return pointer.pointee.bigEndian
        }
        firstIndex += 4
        let result = buffer.subdata(in: firstIndex..<(firstIndex + Int(blobSize)))
        return result
    }
    
    private func oscTimeTag(withData data: Data, startIndex firstIndex: inout Int) -> OSCTimeTag? {
        let oscTimeTagData = data[firstIndex..<firstIndex + 8]
        firstIndex += 8
        return OSCTimeTag(withData: oscTimeTagData)
    }
    
}
