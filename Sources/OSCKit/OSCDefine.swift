//
//  File.swift
//  
//
//  Created by Sam Smallman on 25/10/2020.
//

import Foundation

// http://www.rfc-editor.org/rfc/rfc1055.txt

internal let SLIP_END: UInt8 = 0o0300         /* indicates end of packet */
internal let SLIP_ESC: UInt8 = 0o0333         /* indicates byte stuffing */
internal let SLIP_ESC_END: UInt8 = 0o0334     /* ESC ESC_END means END data byte */
internal let SLIP_ESC_ESC: UInt8 = 0o0335     /* ESC ESC_ESC means ESC data byte */

public enum OSCTCPStreamFraming {
    case SLIP
    case PLH
}
