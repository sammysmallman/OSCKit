//
//  OSCMessage.swift
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

// MARK: Message

public class OSCMessage: OSCPacket {
    
    public let addressPattern: String
    public let addressParts: [String]  // Address Parts are components seperated by "/"
    public let arguments: [Any]
    public let typeTagString: String
    public let argumentTypes: [OSCArgument]
    public var replySocket: Socket? = nil
    
    public init(messageWithAddressPattern addressPattern: String, arguments: [Any]) {
//        self.replySocket = replySocket
        if addressPattern.isEmpty || addressPattern.count == 0 || addressPattern.first != "/" {
            self.addressPattern = "/"
        } else {
            self.addressPattern = addressPattern
        }
        var parts = self.addressPattern.components(separatedBy: "/")
        parts.removeFirst()
        self.addressParts = parts
        var newArguments: [Any] = []
        var newTypeTagString: String = ","
        var types: [OSCArgument] = []
        for argument in arguments {
            if argument is String {
                newTypeTagString.append("s")
                types.append(.oscString)
            } else if argument is Data {
                newTypeTagString.append("b")
                types.append(.oscBlob)
            } else if argument is NSNumber {
                guard let number = argument as? NSNumber else {
                    break
                }
                let numberType = CFNumberGetType(number)
                switch numberType {
                case CFNumberType.sInt8Type,CFNumberType.sInt16Type,CFNumberType.sInt32Type,CFNumberType.sInt64Type,CFNumberType.charType,CFNumberType.shortType,CFNumberType.intType,CFNumberType.longType,CFNumberType.longLongType,CFNumberType.nsIntegerType:
                    newTypeTagString.append("i")
                    types.append(.oscInt)
                case CFNumberType.float32Type, CFNumberType.float64Type, CFNumberType.floatType, CFNumberType.doubleType, CFNumberType.cgFloatType:
                    newTypeTagString.append("f")
                    types.append(.oscFloat)
                default:
                    debugPrint("Number with unrecognised type: \(String(describing: argument))")
                    continue
                }
            } else if argument is OSCTimeTag {
                newTypeTagString.append("t")
                types.append(.oscTimetag)
            } else if argument is OSCArgument {
                guard let oscArgument = argument as? OSCArgument else {
                    break
                }
                switch oscArgument {
                case .oscTrue:
                    newTypeTagString.append("T")
                    types.append(.oscTrue)
                case .oscFalse:
                    newTypeTagString.append("F")
                    types.append(.oscFalse)
                case .oscNil:
                    newTypeTagString.append("N")
                    types.append(.oscNil)
                case .oscImpulse:
                    newTypeTagString.append("I")
                    types.append(.oscImpulse)
                default: break
                }
                continue
            }
            newArguments.append(argument as Any)
        }
        self.arguments = newArguments
        self.typeTagString = newTypeTagString
        self.argumentTypes = types
    }
    
    public func packetData()->Data {
        var result = self.addressPattern.oscStringData()
        result.append(self.typeTagString.oscStringData())
        for argument in arguments {
            if argument is String {
                guard let stringArgument = argument as? String else {
                    break
                }
                result.append(stringArgument.oscStringData())
            } else if argument is Data {
                guard let blobArgument = argument as? Data else {
                    break
                }
                result.append(blobArgument.oscBlobData())
            } else if argument is NSNumber {
                guard let number = argument as? NSNumber else {
                    break
                }
                let numberType = CFNumberGetType(number)
                switch numberType {
                case CFNumberType.sInt8Type,CFNumberType.sInt16Type,CFNumberType.sInt32Type,CFNumberType.sInt64Type,CFNumberType.charType,CFNumberType.shortType,CFNumberType.intType,CFNumberType.longType,CFNumberType.longLongType,CFNumberType.nsIntegerType:
                    result.append(number.oscIntData())
                case CFNumberType.float32Type, CFNumberType.float64Type, CFNumberType.floatType, CFNumberType.doubleType, CFNumberType.cgFloatType:
                    result.append(number.oscFloatData())
                default:
                    debugPrint("Number with unrecognised type: \(argument)")
                    continue
                }
            } else if argument is OSCTimeTag {
                guard let timeTag = argument as? OSCTimeTag else {
                    break
                }
                result.append(timeTag.oscTimeTagData())
            } else if argument is OSCArgument {
                // OSC Arguments T,F,N,I, have no data within the arguements.
                continue
            }
        }
        return result
    }
}

extension String {
    func oscStringData()->Data {
        var data = self.data(using: String.Encoding.utf8)!
        for _ in 1...4-data.count%4 {
            var null = UInt8(0)
            data.append(&null, count: 1)
        }
        return data
    }
}

extension Data {
    func oscBlobData()->Data {
        let length = UInt32(self.count)
        var int = length.bigEndian
        let buffer = UnsafeBufferPointer(start: &int, count: 1)
        let sizeCount = Data(buffer: buffer)
        var data = Data()
        data.append(sizeCount)
        data.append(self)
        while data.count % 4 != 0 {
            var null = UInt8(0)
            data.append(&null, count: 1)
        }
        return data
    }
}

extension NSNumber {
    func oscIntData()->Data {
        var int = Int32(truncating: self).bigEndian
        let buffer = UnsafeBufferPointer(start: &int, count: 1)
        return Data(buffer: buffer)
    }
    
    func oscFloatData()->Data  {
        var float = CFConvertFloatHostToSwapped(Float32(truncating: self))
        let buffer = UnsafeBufferPointer(start: &float , count: 1)
        return Data(buffer: buffer)
    }
}


