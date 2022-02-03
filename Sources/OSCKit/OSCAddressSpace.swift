//
//  OSCAddressSpace.swift
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

public class OSCAddressMethodMatch: Equatable {
    
    public static func == (lhs: OSCAddressMethodMatch, rhs: OSCAddressMethodMatch) -> Bool {
        return lhs.method.addressPattern == rhs.method.addressPattern
    }
    
    let method: OSCAddressMethod
    var strings: Int
    var wildcards: Int
    
    init(method: OSCAddressMethod, strings: Int = 0, wildcards: Int = 0) {
        self.method = method
        self.strings = strings
        self.wildcards = wildcards
    }
}

public enum OSCAddressSpaceMatchPriority {
    case string
    case wildcard
    case none
}

public class OSCAddressSpace {
    
    public var methods: Set<OSCAddressMethod> = []
    
    public init(addressSpace: Set<OSCAddressMethod> = []) {
        self.methods = addressSpace
    }
    
    // MARK:- Pattern Matching
    private func matches(for addressPattern: String, priority: OSCAddressSpaceMatchPriority = .none) -> Set<OSCAddressMethod> {
        var parts = addressPattern.components(separatedBy: "/")
        parts.removeFirst()
        var matchedAddresses: [OSCAddressMethodMatch] = methods.map { OSCAddressMethodMatch(method: $0) }
        // 1. The OSC Address and the OSC Address Pattern contain the same number of parts; and
        let matchedAddressesWithEqualPartsCount = matchedAddresses.filter({ parts.count == $0.method.parts.count })
        matchedAddresses = matchedAddressesWithEqualPartsCount
        // 2. Each part of the OSC Address Pattern matches the corresponding part of the OSC Address.
        for (index, part) in parts.enumerated() {
            matchedAddressesWithEqualPartsCount.forEach { match in
                switch match.method.match(part: part, atIndex: index) {
                case .string: match.strings += 1
                case .wildcard: match.wildcards += 1
                case .different:
                    matchedAddresses = matchedAddresses.filter { match != $0 } 
                }
            }
        }
        switch priority {
        case .none: return Set(matchedAddresses.map { $0.method })
        case .string:
            let sorted = matchedAddresses.sorted { $0.strings > $1.strings }.map { $0.method }
            guard let first = sorted.first else { return [] }
            return [first]
        case .wildcard:
            let sorted = matchedAddresses.sorted { $0.wildcards > $1.wildcards }.map { $0.method }
            guard let first = sorted.first else { return [] }
            return [first]
        }
    }
    
    public func complete(with message: OSCMessage, priority: OSCAddressSpaceMatchPriority = .none) -> Bool {
        let methods = matches(for: message.addressPattern, priority: priority)
        guard !methods.isEmpty else { return false }
        methods.forEach({ $0.completion(message) })
        return true
    }
    
}
