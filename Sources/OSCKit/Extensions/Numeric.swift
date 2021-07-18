//
//  Numeric.swift
//  OSCKit
//
//  Created by Sam Smallman on 13/07/2021.
//

import Foundation

internal extension Numeric {
    
    var data: Data {
        var source = self
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
    
}
