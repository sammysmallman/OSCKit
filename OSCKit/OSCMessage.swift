//
//  OSCMessage.swift
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

// MARK: Message

public class OSCMessage: OSCPacket {
    
    public var addressPattern: String = "/"
    public var addressParts: [String] { // Address Parts are components seperated by "/"
        get {
            var parts = self.addressPattern.components(separatedBy: "/")
            parts.removeFirst()
            return parts
        }
    }
    public var arguments: [Any] = []
    public var typeTagString: String = ","
    public var replySocket: Socket?
    
    public init(messageWithAddressPattern addressPattern: String, arguments: [Any]) {
        message(with: addressPattern, arguments: arguments, replySocket: nil)
    }
    
    public init(messageWithAddressPattern addressPattern: String, arguments: [Any], replySocket: Socket?) {
        message(with: addressPattern, arguments: arguments, replySocket: replySocket)
    }
    
    private func message(with addressPattern: String, arguments: [Any], replySocket: Socket?) {
        set(addressPattern: addressPattern)
        set(arguments: arguments)
        self.replySocket = replySocket
    }
    
    private func set(addressPattern: String) {
        if addressPattern.isEmpty || addressPattern.count == 0 || addressPattern.first != "/" {
            self.addressPattern = "/"
        } else {
            self.addressPattern = addressPattern
        }
    }
    
    private func set(arguments: [Any]) {
        var newArguments: [Any] = []
        var newTypeTagString: String = ","
        for argument in arguments {
            if argument is String {
                newTypeTagString.append("s")
            } else if argument is Data {
                newTypeTagString.append("b")
            } else if argument is NSNumber {
                guard let number = argument as? NSNumber else {
                    break
                }
                let numberType = CFNumberGetType(number)
                switch numberType {
                case CFNumberType.sInt8Type,CFNumberType.sInt16Type,CFNumberType.sInt32Type,CFNumberType.sInt64Type,CFNumberType.charType,CFNumberType.shortType,CFNumberType.intType,CFNumberType.longType,CFNumberType.longLongType,CFNumberType.nsIntegerType:
                    newTypeTagString.append("i")
                case CFNumberType.float32Type, CFNumberType.float64Type, CFNumberType.floatType, CFNumberType.doubleType, CFNumberType.cgFloatType:
                    newTypeTagString.append("f")
                default:
                    debugPrint("Number with unrecognised type: \(argument)")
                    continue
                }
            }
            newArguments.append(argument)
        }
        self.arguments = newArguments
        self.typeTagString = newTypeTagString
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


