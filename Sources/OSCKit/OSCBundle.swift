//
//  OSCBundle.swift
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

public class OSCBundle: OSCPacket {
    
    public var timeTag: OSCTimeTag = OSCTimeTag()
    public var elements: [OSCPacket] = []
    public var replySocket: OSCSocket?
    
    public init(with elements: [OSCPacket] = []) {
        bundle(with: elements, timeTag: OSCTimeTag.init())
    }
    
    public init(with elements: [OSCPacket] = [], timeTag: OSCTimeTag) {
        bundle(with: elements, timeTag: timeTag)
    }
    
    public init(with elements: [OSCPacket] = [], timeTag: OSCTimeTag, replySocket: OSCSocket?) {
        bundle(with: elements, timeTag: timeTag, replySocket: replySocket)
    }
    
    private func bundle(with elements: [OSCPacket] = [], timeTag: OSCTimeTag, replySocket: OSCSocket? = nil) {
        self.timeTag = timeTag
        self.elements = elements
        self.replySocket = replySocket
    }
    
    public func packetData()->Data {
        var result = "#bundle".oscStringData()
        let timeTagData = self.timeTag.oscTimeTagData()
        result.append(timeTagData)
        for element in elements {
            if element is OSCMessage {
                let data = (element as! OSCMessage).packetData()
                let size = withUnsafeBytes(of: Int32(data.count).bigEndian) { Data($0) }
                result.append(size)
                result.append(data)
            }
            if element is OSCBundle {
                let data = (element as! OSCBundle).packetData()
                let size = withUnsafeBytes(of: Int32(data.count).bigEndian) { Data($0) }
                result.append(size)
                result.append(data)
            }
        }
        return result
    }
    
}

