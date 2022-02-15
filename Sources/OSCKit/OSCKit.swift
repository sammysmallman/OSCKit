//
//  OSCKit.swift
//  OSCKit
//
//  Created by Sam Smallman on 22/07/2021.
//  Copyright © 2022 Sam Smallman. https://github.com/SammySmallman
//
//  This file is part of OSCKit
//
//  OSCKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OSCKit is distributed in the hope that it will be useful
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

// Export all submodules so they all import
// when importing the top-level module OSCKit
@_exported import CoreOSC

import Foundation

public enum OSCKit {
    
    /// This package's semantic version number, mirrored also in git history as a `git tag`.
    static let version: String = "3.1.0"
    
    /// The license agreement this repository is licensed under.
    static let license: String = {
        let url = Bundle.module.url(forResource: "LICENSE", withExtension: "md")
        let data = try! Data(contentsOf: url!)
        return String(decoding: data, as: UTF8.self)
    }()
    
    /// An address pattern for retrieving the sdk's version.
    static let oscKitVersion: String = "/sdk/osckit/version"
    /// An address pattern for retrieving the sdk's license.
    static let oscKitLicense: String = "/sdk/osckit/license"
    /// An address pattern for retrieving the sdk's version.
    static let coreOscVersion: String = "/sdk/coreosc/version"
    /// An address pattern for retrieving the sdk's license.
    static let coreOscLicense: String = "/sdk/coreosc/license"

    /// Returns an `OSCMessage` response corresponding to the given packet.
    static func message(for packet: OSCPacket) -> OSCMessage? {
        guard let message = packet as? OSCMessage else { return nil }
        switch message.addressPattern.fullPath {
        case OSCKit.oscKitVersion:
            return try! OSCMessage(with: OSCKit.oscKitVersion, arguments: [OSCKit.version])
        case OSCKit.oscKitLicense:
            return try! OSCMessage(with: OSCKit.oscKitLicense, arguments: [OSCKit.license])
        case OSCKit.coreOscVersion:
            return try! OSCMessage(with: OSCKit.coreOscVersion, arguments: [CoreOSC.version])
        case OSCKit.coreOscLicense:
            return try! OSCMessage(with: OSCKit.coreOscLicense, arguments: [CoreOSC.license])
        default:
            return nil
        }
    }
    
    /// Returns a boolean value indicating whether a packet should be listened to.
    static func listening(for packet: OSCPacket) -> Bool {
        guard let message = packet as? OSCMessage else { return true }
        switch message.addressPattern.fullPath {
        case OSCKit.oscKitVersion,  OSCKit.oscKitLicense,
             OSCKit.coreOscVersion, OSCKit.coreOscLicense:
            return false
        default:
            return true
        }
    }

}
