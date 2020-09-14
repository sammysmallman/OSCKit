//
//  OSCAddressSpace.swift
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

public class OSCAddressSpace {
    
    var methods: Set<OSCAddressMethod> = []
    
    public init(addressSpace: Set<OSCAddressMethod> = []) {
        self.methods = addressSpace
    }
    
    // MARK:- Pattern Matching
    private func matches(for addressPattern: String) -> Set<OSCAddressMethod> {
        var parts = addressPattern.components(separatedBy: "/")
        parts.removeFirst()
        var matchedAddresses: Set<OSCAddressMethod> = methods
        // 1. The OSC Address and the OSC Address Pattern contain the same number of parts; and
        matchedAddresses = matchedAddresses.filter({ parts.count == $0.parts.count })
        // 2. Each part of the OSC Address Pattern matches the corresponding part of the OSC Address.
        for (index, part) in parts.enumerated() {
            matchedAddresses = matchedAddresses.filter({ $0.matches(part: part, atIndex: index) })
        }
        return matchedAddresses
    }
    
    public func complete(with message: OSCMessage) -> Bool {
        let methods = matches(for: message.addressPattern)
        guard !methods.isEmpty else { return false }
        methods.forEach({ $0.completion(message) })
        return true
    }
    
}


