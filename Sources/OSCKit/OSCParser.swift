//
//  OSCParser.swift
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

import Foundation

internal class OSCParser {

    internal static func packet(from data: Data) throws -> OSCPacket {
        guard let string = String(data: data.prefix(upTo: 1), encoding: .utf8) else {
            throw OSCParserError.unrecognisedData
        }
        if string == "/" { // OSC Messages begin with /
            do {
                return try process(OSCMessageData: data)
            } catch {
                throw error
            }
        } else if string == "#" { // OSC Bundles begin with #
            do {
                return try process(OSCBundleData: data)
            } catch {
                throw error
            }
        } else {
            throw OSCParserError.unrecognisedData
        }
    }

    private static func process(OSCMessageData data: Data) throws -> OSCPacket {
        var startIndex = 0
        return try parseOSCMessage(with: data, startIndex: &startIndex)
    }

    private static func process(OSCBundleData data: Data) throws -> OSCPacket {
        return try parseOSCBundle(with: data)
    }

    internal static func decodeSLIP(_ slipData: Data,
                                    with state: inout OSCTcp.SocketState,
                                    dispatchHandler: (OSCPacket) -> Void) throws {
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
                        let packet = try packet(from: state.data)
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
                        let nextC = slipData[index]
                        // This is why we're using a while loop.
                        // ESC characters mean we jump forward 1.
                        index += 1
                        // We're essentially checking whether two bytes correctly
                        // represent an escaped character. If they do then we're adding
                        // the single escaped character to the data and then treating
                        // it as if we received a single byte by skipping over
                        // the extra escaped one.
                        switch nextC {
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

    internal static func decodePLH(_ plhData: Data,
                                   with data: inout Data,
                                   dispatchHandler: (OSCPacket) -> Void) throws {
        var buffer = Data()
        // If there is data in the plhDataBuffer, append it to the
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
                .withUnsafeBytes({ $0.load(as: Int32.self) }).bigEndian
            // Check to see if we actually have enough data to process.
            if buffer.count >= packetLength + 4, packetLength > 0 {
                let dataRange = buffer.startIndex + 4..<buffer.startIndex + Int(packetLength + 4)
                let possibleOSCData = buffer.subdata(in: dataRange)
                do {
                    let packet = try packet(from: possibleOSCData)
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

    private static func parseOSCMessage(with data: Data, startIndex firstIndex: inout Int) throws -> OSCMessage {
        guard let addressPattern = oscString(with: data, startIndex: &firstIndex) else {
            throw OSCParserError.cantParseAddressPattern
        }

        guard let typeTagString = oscString(with: data, startIndex: &firstIndex) else {
            throw OSCParserError.cantParseTypeTagString
        }

        // If the Type Tag String starts with "," and has 1 or more characters after,
        // we possibly have some arguments.
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
        return OSCMessage(with: addressPattern, arguments: arguments)
    }

    private static func parseOSCBundle(with data: Data) throws -> OSCBundle {
        // Check the Bundle has a string prefix of "#bundle"
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
                    return OSCBundle(with: elements, timeTag: timeTag)
                } catch {
                    throw error
                }
            } else {
                return OSCBundle(timeTag: timeTag)
            }
        } else {
            throw OSCParserError.unrecognisedData
        }
    }

    private static func parseOSCBundleElements(with index: Int, data: Data, andSize size: Int32) throws -> [OSCPacket] {
        var elements: [OSCPacket] = []
        var startIndex = 0
        var buffer: Int32 = 0
        repeat {
            guard let elementSize = oscInt(with: data, startIndex: &startIndex) else {
                throw OSCParserError.cantParseSizeOfElement
            }
            buffer += 4
            guard let string = String(data: data.subdata(in: startIndex..<data.endIndex).prefix(upTo: 1),
                                      encoding: .utf8) else {
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
                        let bundleElements = try parseOSCBundleElements(with: index,
                                                                        data: bundleData,
                                                                        andSize: Int32(bundleData.count))
                        elements.append(OSCBundle(with: bundleElements, timeTag: timeTag))
                    } catch {
                        throw error
                    }
                } else {
                    elements.append(OSCBundle(timeTag: timeTag))
                }
            } else {
                throw OSCParserError.unrecognisedData
            }
            buffer += elementSize
            startIndex = index + Int(buffer)
        } while buffer < size
        return elements
    }

    private static func oscString(with buffer: Data, startIndex firstIndex: inout Int) -> String? {
        // Read the data from the start index until you hit a zero, the part before will be the string data.
        for (index, byte) in buffer[firstIndex...].enumerated() where byte == 0x0 {
            guard let result = String(data: buffer[firstIndex..<(firstIndex + index)],
                                      encoding: .utf8) else { return nil }
             // An OSC String is a sequence of non-null ASCII characters followed by a null,
             // followed by 0-3 additional null characters to make the total number
             // of bits a multiple of 32 Bits, 4 Bytes.
            let bytesRead = firstIndex + index + 1 // Include the Null bytes we found.
            if bytesRead.isMultiple(of: 4) {
                firstIndex = bytesRead
            } else {
                let number = (Double(bytesRead) / 4.0).rounded(.up)
                firstIndex = Int(4.0 * number)
            }
            return result
        }
        return nil
    }

    private static func oscInt(with buffer: Data, startIndex firstIndex: inout Int) -> Int32? {
        // An OSC Int is a 32-bit big-endian two's complement integer.
        let result = buffer.subdata(in: firstIndex..<firstIndex + 4).withUnsafeBytes {
            $0.load(as: Int32.self)
        }.bigEndian
        firstIndex += 4
        return result
    }

    private static func oscFloat(with buffer: Data, startIndex firstIndex: inout Int) -> Float32? {
        // An OSC Float is a 32-bit big-endian IEEE 754 floating point number.
        let result = buffer.subdata(in: firstIndex..<firstIndex + 4).withUnsafeBytes {
            CFConvertFloat32SwappedToHost($0.load(as: CFSwappedFloat32.self))
        }
        firstIndex += 4
        return result
    }

    private static func oscBlob(with buffer: Data, startIndex firstIndex: inout Int) -> Data? {
         // An int32 size count, followed by that many 8-bit bytes of arbitrary binary data,
         // followed by 0-3 additional zero bytes to make the total number of bits a multiple of 32, 4 bytes
        guard let size = oscInt(with: buffer, startIndex: &firstIndex) else { return nil }
        let intSize = Int(size)
        let result = buffer.subdata(in: firstIndex..<intSize)
        let total = firstIndex + intSize
        if total.isMultiple(of: 4) {
            firstIndex = total
        } else {
            let number = (Double(total) / 4.0).rounded(.up)
            firstIndex = Int(4.0 * number)
        }
        return result
    }

    private static func oscTimeTag(withData data: Data, startIndex firstIndex: inout Int) -> OSCTimeTag? {
        let oscTimeTagData = data[firstIndex..<firstIndex + 8]
        firstIndex += 8
        return OSCTimeTag(data: oscTimeTagData)
    }

}

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
