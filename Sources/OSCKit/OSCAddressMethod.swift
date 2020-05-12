//
//  File.swift
//  
//
//  Created by Sam Smallman on 12/05/2020.
//

import Foundation

struct OSCAddressMethod: Hashable, Equatable {
    
    let addressPattern: String
    let parts: [String]
    let completion: (OSCMessage) -> ()
    
    init(with addressPattern: String, andCompletionHandler completion: @escaping (OSCMessage) -> ()) {
        self.addressPattern = addressPattern
        var addressParts = addressPattern.components(separatedBy: "/")
        addressParts.removeFirst()
        self.parts = addressParts
        self.completion = completion
    }
    
    static func == (lhs: SKCallback, rhs: SKCallback) -> Bool {
        return lhs.addressPattern == rhs.addressPattern
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(addressPattern)
    }
    
    // "/a/b/c/d/e" is equal to "/a/b/c/d/e" or "/a/b/c/d/*".
    func matches(part: String, atIndex index: Int) -> Bool {
        guard parts.indices.contains(index) else { return false }
        return parts[index] == part || parts[index] == "*"
    }

}
