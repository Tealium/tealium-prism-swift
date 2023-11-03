//
//  MockDatabaseProvider.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite
@testable import TealiumSwift

class MockDatabaseProvider: DatabaseProviderProtocol {
    let database: Connection
    init() {
        guard let database = try? DatabaseProvider.getInMemoryDatabase(settings: CoreSettings(coreDictionary: [:])) else {
            fatalError("Failed to create MockDatabaseProvider")
        }
        self.database = database
    }
}
