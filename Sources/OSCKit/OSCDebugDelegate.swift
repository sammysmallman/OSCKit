//
//  OSCDebugDelegate.swift
//  OSCKit
//
//  Created by Sam Smallman on 11/01/2021.
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

/// Notifies observers when new messages are received, and provides debug information.
public protocol OSCDebugDelegate: AnyObject {
    
    /// Notifies the delegate of a new debug log entry.
    /// - Parameter logMessage: A human-readable log message.
    func debugLog(_ logMessage: String)
    
}
