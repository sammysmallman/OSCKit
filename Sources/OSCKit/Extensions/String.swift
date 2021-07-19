//
//  String.swift
//  OSCKit
//
//  Created by Sam Smallman on 18/07/2021.
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

extension String {

    /// An `NSRange` that represents the full range of the string.
    internal var nsrange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }

    internal var doubleValue: Double? {
        return Double(self)
    }

    internal var floatValue: Float? {
        return Float(self)
    }

    internal var integerValue: Int? {
        return Int(self)
    }

    internal var isNumber: Bool {
        if Double(self) != nil {
            return true
        } else {
            return false
        }
    }

    internal func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }

    internal func oscStringData() -> Data {
        var data = self.data(using: .utf8)!
        for _ in 1...4 - data.count % 4 {
            var null = UInt8(0)
            data.append(&null, count: 1)
        }
        return data
    }

}
