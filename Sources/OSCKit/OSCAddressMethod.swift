//
//  OSCAddressMethod.swift
//  OSCKit
//
//  Created by Sam Smallman on 12/05/2020.
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

public struct OSCAddressMethod: Hashable, Equatable {
    
    let addressPattern: String
    let parts: [String]
    let completion: (OSCMessage) -> ()
    
    public init(with addressPattern: String, andCompletionHandler completion: @escaping (OSCMessage) -> ()) {
        self.addressPattern = addressPattern
        var addressParts = addressPattern.components(separatedBy: "/")
        addressParts.removeFirst()
        self.parts = addressParts
        self.completion = completion
    }
    
    public static func == (lhs: OSCAddressMethod, rhs: OSCAddressMethod) -> Bool {
        return lhs.addressPattern == rhs.addressPattern
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(addressPattern)
    }
    
    // "/a/b/c/d/e" is equal to "/a/b/c/d/e" or "/a/b/c/d/*".
    public func matches(part: String, atIndex index: Int) -> Bool {
        guard parts.indices.contains(index) else { return false }
        return parts[index] == part || parts[index] == "*"
    }

}
