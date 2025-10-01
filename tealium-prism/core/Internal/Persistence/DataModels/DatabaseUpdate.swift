//
//  DatabaseUpdate.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

struct DatabaseUpgrade {
    let version: Int
    let upgrade: (Connection) throws -> Void
}
