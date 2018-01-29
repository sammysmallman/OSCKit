//
//  OSCTimeTag.swift
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

// MARK: TimeTag

public class OSCTimeTag {
    
    private let seconds: UInt32
    private let fraction: UInt32
    
    public private(set) var immediate: Bool
    
    public init?(withData data: Data) {
        if data.count == 8 {
            let secondsNumber = data.subdata(in: data.startIndex ..< data.startIndex + 4).withUnsafeBytes { (pointer: UnsafePointer<UInt32>) -> UInt32 in
                return pointer.pointee.byteSwapped
            }
            let fractionNumber = data.subdata(in: data.startIndex + 4 ..< data.startIndex + 8 ).withUnsafeBytes { (pointer: UnsafePointer<UInt32>) -> UInt32 in
                return pointer.pointee.byteSwapped
            }
            self.seconds = secondsNumber
            self.fraction = fractionNumber
            if secondsNumber == 0 && fractionNumber == 1 {
                self.immediate = true
            } else {
                self.immediate = false
            }

        } else {
            debugPrint("OSC TimeTag Data with incorrect number of bytes.")
            return nil
        }
    }
    
    public init(withDate date: Date) {
        // OSCTimeTags uses 1900 as it's marker. We need to get the seconds from 1900 not 1970 which Apple's Date Object gets.
        // Seconds between 1900 and 1970 = 2208988800
        let secondsSince1900 = date.timeIntervalSince1970 + 2208988800
        // Bitwise AND operator to get the first 32 bits of secondsSince1900 which is cast from a double to UInt64
        self.seconds = UInt32(UInt64(secondsSince1900) & 0xffffffff)
        let fractionsPerSecond = Double(0xffffffff)
        self.fraction = UInt32(fmod(secondsSince1900, 1.0) * fractionsPerSecond)
        self.immediate = false
    }
    
    // immediate Time Tag
    public init() {
        self.seconds = 0
        self.fraction = 1
        self.immediate = true
    }
    
    public func date()->Date {
        let date1900 = Date(timeIntervalSince1970: -2208988800)
        var interval = TimeInterval(self.seconds)
        interval += TimeInterval(Double(self.fraction) / 0xffffffff)
        return date1900.addingTimeInterval(interval)
    }
    
    public func hex()->String {
        return "\(self.seconds.byteArray().map{String(format: "%02X", $0)}.joined())\(self.fraction.byteArray().map{String(format: "%02X", $0)}.joined())"
    }
    

    func oscTimeTagData()->Data {
        var data = Data()
        var variableSeconds = seconds.bigEndian
        let secondsBuffer = UnsafeBufferPointer(start: &variableSeconds, count: 1)
        data.append(Data(buffer: secondsBuffer))
        var variableFraction = fraction.bigEndian
        let fractionBuffer = UnsafeBufferPointer(start: &variableFraction, count: 1)
        data.append(Data(buffer: fractionBuffer))
        return data
    }
}

extension UInt32 {
    func byteArray() -> [UInt8]{
        var bigEndian = self.bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
}

extension Date {
    func oscTimeTag()->OSCTimeTag {
        return OSCTimeTag(withDate: self)
    }
}

