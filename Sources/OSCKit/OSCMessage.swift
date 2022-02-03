//
//  OSCMessage.swift
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

public class OSCMessage: OSCPacket {
    
    public private(set) var addressPattern: String
    public private(set) var addressParts: [String]  // Address Parts are components seperated by "/"
    public let arguments: [Any]
    public let typeTagString: String
    public let argumentTypes: [OSCArgument]
    public var replySocket: OSCSocket? = nil
    
    public init(with addressPattern: String, arguments: [Any] = []) {
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
            }
            newArguments.append(argument as Any)
        }
        self.arguments = newArguments
        self.typeTagString = newTypeTagString
        self.argumentTypes = types
    }
    
    public func readdress(to addressPattern: String) {
        if addressPattern.isEmpty || addressPattern.count == 0 || addressPattern.first != "/" {
            self.addressPattern = "/"
        } else {
            self.addressPattern = addressPattern
        }
        var parts = self.addressPattern.components(separatedBy: "/")
        parts.removeFirst()
        self.addressParts = parts
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
        var data = self.data(using: .utf8)!
        for _ in 1...4 - data.count % 4 {
            var null = UInt8(0)
            data.append(&null, count: 1)
        }
        return data
    }
}

extension Data {
    func oscBlobData()->Data {
        let length = UInt32(self.count)
        var data = Data()
        data.append(length.bigEndian.data)
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
        return Data(Int32(truncating: self).bigEndian.data)
    }
    
    func oscFloatData()->Data  {
        var float: CFSwappedFloat32 = CFConvertFloatHostToSwapped(Float32(truncating: self))
        let size: Int = MemoryLayout<CFSwappedFloat32>.size
        let result: [UInt8] = withUnsafePointer(to: &float) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                Array(UnsafeBufferPointer(start: $0, count: size))
            }
        }
        return Data(result)
    }
}


