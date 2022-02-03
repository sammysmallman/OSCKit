//
//  OSCDefine.swift
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

// Integer literals can be written as an octal number with a 0o prefix.
internal let slipEnd: UInt8 = 0o0300         /* indicates end of packet */
internal let slipEsc: UInt8 = 0o0333         /* indicates byte stuffing */
internal let slipEscEnd: UInt8 = 0o0334     /* ESC ESC_END means END data byte */
internal let slipEscEsc: UInt8 = 0o0335     /* ESC ESC_ESC means ESC data byte */

internal let version: String = "/sdk/osckit/version"
internal let license: String = "/sdk/osckit/license"

public enum OSCTCPStreamFraming {
    case SLIP   // http://www.rfc-editor.org/rfc/rfc1055.txt
    case PLH    // Packet Length Headers
}
