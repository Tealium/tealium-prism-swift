//
//  UnsupportedSchemaVersionError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/// The stored database version can't be opened by this SDK, so the file is deleted and recreated.
/// Internal: the provider handles it, so apps never see it. Kotlin: `UnsupportedSchemaVersionException`.
enum UnsupportedSchemaVersionError: Error {
    /// The stored version is newer than this SDK's `current` one.
    case newer(stored: Int, current: Int)
    /// The stored version is below `DatabaseHelper.MIN_SUPPORTED_VERSION`.
    case belowMinimum(stored: Int)
}
