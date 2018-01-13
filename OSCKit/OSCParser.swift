//
//  OSCParser.swift
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

import Foundation

// MARK: Parser

public class OSCParser {
    
    public enum streamFraming {
        case SLIP
        case PLH
    }
    
    public func process(OSCDate data: Data, for destination: OSCPacketDestination, with replySocket: Socket) {
        if !data.isEmpty {
            let firstCharacter = data.prefix(upTo: 1)
            guard let string = String(data: firstCharacter, encoding: .utf8) else { return }
            if string == "/" { // OSC Messages begin with /
                parseOSCMessage(with: data)
            } else if string == "#" { // OSC Bundles begin with #
                parseOSCBundle(with: data)
            } else {
                print("Unrecognized data \(data)")
            }
        }
    }
    
    public func translate(OSCData tcpData: Data, streamFraming: streamFraming, to data: NSMutableData, with state: NSMutableDictionary) {
        // There are two versions of OSC. OSC 1.1 frames messages using the SLIP protocol: http://www.rfc-editor.org/rfc/rfc1055.txt
        if streamFraming == .SLIP {
            
        }
    }
    
    private func parseOSCMessage(with data: Data) {
//        print("Parsing OSC Message: \(data)")
        var startIndex = 0
        guard let addressPattern = oscString(with: data, startIndex: &startIndex) else {
            print("Error: Unable to parse OSC Address Pattern.")
            return
        }
        print("Address Pattern: \(addressPattern)")
        guard let typeTagString = oscString(with: data, startIndex: &startIndex) else {
            print("Error: Unable to parse Type Tag String.")
            return
        }
        print("Type Tag String: \(typeTagString)")
        // If the Type Tag String starts with "," and has 1 or more characters after, we possibly have some arguments.
        var arguments: [Any] = []
        if typeTagString.first == "," && typeTagString.count > 1 {
            // Remove "," as we will iterate over the different type of tags.
            var typeTags = typeTagString
            typeTags.removeFirst()
            for tag in typeTags {
                switch tag {
                case "s":
                    guard let stringArgument = oscString(with: data, startIndex: &startIndex) else {
                        print("Error: Unable to parse String Argument.")
                        return
                    }
                    arguments.append(stringArgument)
                    print(stringArgument)
                case "i":
                    guard let intArgument = oscInt(with: data, startIndex: &startIndex) else {
                        print("Error: Unable to parse Int Argument.")
                        return
                    }
                    arguments.append(intArgument)
                    print(intArgument)
                case "f":
                    guard let floatArgument = oscFloat(with: data, startIndex: &startIndex) else {
                        print("Error: Unable to parse Float Argument.")
                        return
                    }
                    arguments.append(floatArgument)
                    print(floatArgument)
                case "b":
                    guard let blobArgument = oscBlob(with: data, startIndex: &startIndex) else {
                        print("Error: Unable to parse Blob Argument.")
                        return
                    }
                    arguments.append(blobArgument)
                    print(blobArgument)
                default:
                    break
                }
            }
        }
        print("Number of Arguments: \(arguments.count)")
    }
    
    private func parseOSCBundle(with data: Data) {
        print("Parsing OSC Bundle: \(data)")
    }
    
    // TODO: for in loops copy on write. It would be more efficient to move along the data, one index at a time.
    private func oscString(with buffer: Data, startIndex firstIndex: inout Int) -> String? {
        // Read the data from the start index until you hit a zero, the part before will be the string data.
        for (index, byte) in buffer[firstIndex...].enumerated() where byte == 0 {
            guard let result = String(data: buffer[firstIndex...(firstIndex + index)], encoding: .utf8) else { return nil }
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
    
}
