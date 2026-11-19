//
//  MockDatabaseProvider.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite
@testable import TealiumPrism

class MockDatabaseProvider: DatabaseProviderProtocol {
    let database: DatabaseConnection
    init() {
        guard let connection = try? DatabaseProvider.getInMemoryDatabase() else {
            fatalError("Failed to create MockDatabaseProvider")
        }
        self.database = DatabaseConnection(connection: connection, onCorruption: { _ in })
    }

    /// Wraps an existing connection, e.g. an upgraded database file.
    init(database: Connection) {
        self.database = DatabaseConnection(connection: database, onCorruption: { _ in })
    }
}
