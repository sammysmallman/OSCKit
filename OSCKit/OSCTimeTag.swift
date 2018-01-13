//
//  OSCTimeTag.swift
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

// MARK: TimeTag

public class OSCTimeTag {
    
    private let seconds: UInt32
    private let fraction: UInt32
    
    public init(withDate date: Date) {
        // OSCTimeTags uses 1900 as it's marker. We need to get the seconds from 1900 not 1970 which Apple's Date Object gets.
        // Seconds between 1900 and 1970 = 2208988800
        let secondsSince1900 = date.timeIntervalSince1970 + 2208988800
        // Bitwise AND operator to get the first 32 bits of secondsSince1900 which is cast from a double to UInt64
        self.seconds = UInt32(UInt64(secondsSince1900) & 0xffffffff)
        
        let fractionsPerSecond = Double(0xffffffff)
        self.fraction = UInt32(fmod(secondsSince1900, 1.0) * fractionsPerSecond)
    }
    
    // immediate Time Tag
    public init() {
        self.seconds = 0
        self.fraction = 1
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

