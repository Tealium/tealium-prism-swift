//
//  DatabaseErrors.swift
//  tealium-swift
//
//  Created by Tyler Rister on 14/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

enum DatabaseErrors: Error {
    case unsupportedDowgrade
    case databaseNil
    case moduleIdCreationFailed
}
