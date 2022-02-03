//
//  OSCKit.swift
//  OSCKit
//
//  Created by Sam Smallman on 03/02/2022.
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

public enum OSCKit {
    
    /// This package's semantic version number, mirrored also in git history as a `git tag`.
    static let version: String = "2.2.0"
    
    /// The license agreement this repository is licensed under.
    static let license: String = {
        let url = Bundle.module.url(forResource: "LICENSE", withExtension: "md")
        let data = try! Data(contentsOf: url!)
        return String(decoding: data, as: UTF8.self)
    }()

}
