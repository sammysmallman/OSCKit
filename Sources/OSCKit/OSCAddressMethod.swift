//
//  OSCAddressMethod.swift
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

public enum OSCAddressPatternMatch {
    case string
    case different
    case wildcard
}

public struct OSCAddressMethod: Hashable, Equatable {
    
    public let addressPattern: String
    public let parts: [String]
    public let completion: (OSCMessage) -> ()
    
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
    public func match(part: String, atIndex index: Int) -> OSCAddressPatternMatch {
        guard parts.indices.contains(index) else { return .different }
        let match = parts[index]
        switch match {
        case part: return .string
        case "*": return .wildcard
        default: return .different
        }
    }

}
