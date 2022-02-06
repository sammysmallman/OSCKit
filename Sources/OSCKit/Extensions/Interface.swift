//
//  Interface.swift
//  OSCKit
//
//  Created by Sam Smallman on 29/10/2017.
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

import Foundation
import SystemConfiguration
import NetUtils

extension Interface {
    #if os(OSX)
    open var displayName: String {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else {
            return ""
        }
        for interface in interfaces where SCNetworkInterfaceGetBSDName(interface) as String? == self.name {
            return SCNetworkInterfaceGetLocalizedDisplayName(interface)! as String
        }
        return ""
    }

    open var displayText: String {
        "\(self.displayName) (\(self.name)) - \(self.address ?? "")"
    }
    #endif
}
