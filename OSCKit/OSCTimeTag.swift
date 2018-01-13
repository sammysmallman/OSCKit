//
//  OSCTimeTag.swift
//  OSCKit
//
//  Created by Sam Smallman on 13/01/2018.
//  Copyright © 2018 artificeindustries. All rights reserved.
//

import Foundation

public class OSCTimeTag {
    
    private let seconds: UInt32
    private let fraction: UInt32
    
    /// seconds between 1900 and 1970
    //    private let SecondsSince1900: Double = 2208988800
    
    public init(withDate date: Date) {
        // WORK ON THIS!!!
        let secondsSince1900 = date.timeIntervalSince1970 + 2208988800
        self.seconds = UInt32(secondsSince1900 * 0x1_0000_0000)
        let fractionsPerSecond = Double(0x1_0000_0000)
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

