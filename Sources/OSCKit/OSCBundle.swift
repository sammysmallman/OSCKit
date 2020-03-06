//
//  OSCBundle.swift
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

// MARK: Bundle

public class OSCBundle: OSCPacket {
    
    public var timeTag: OSCTimeTag = OSCTimeTag()
    public var elements: [OSCPacket] = []
    public var replySocket: Socket?
    
    public init(bundleWithMessages messages: [OSCMessage]) {
        // Bundle made with messages and a immediate OSC Time Tag.
        bundle(withElements: messages, timeTag: OSCTimeTag.init(), replySocket: nil)
    }
    
    public init(bundleWithElements elements: [OSCPacket], timeTag: OSCTimeTag) {
        bundle(withElements: elements, timeTag: timeTag, replySocket: nil)
    }
    
    public init(bundleWithElements elements: [OSCPacket], timeTag: OSCTimeTag, replySocket: Socket?) {
        bundle(withElements: elements, timeTag: timeTag, replySocket: replySocket)
    }
    
    private func bundle(withElements elements: [OSCPacket], timeTag: OSCTimeTag, replySocket: Socket?) {
        self.timeTag = timeTag
        self.elements = elements
        self.replySocket = replySocket
    }
    
    public func packetData()->Data {
        var result = "#bundle".oscStringData()
        result.append(self.timeTag.oscTimeTagData())
        for element in elements {
            result.append(element.packetData())
        }
        return result
    }
    
}

