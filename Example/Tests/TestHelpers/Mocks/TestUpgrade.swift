//
//  TestUpgrade.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism

/// A `DatabaseUpgrade` whose body is supplied by the test.
struct TestUpgrade: DatabaseUpgrade {
    let targetVersion: Int
    let body: (Connection) throws -> Void

    init(targetVersion: Int, body: @escaping (Connection) throws -> Void = { _ in }) {
        self.targetVersion = targetVersion
        self.body = body
    }

    func upgrade(_ database: Connection) throws {
        try body(database)
    }
}

/// The error a failing `TestUpgrade` throws.
struct StepError: Error { }
