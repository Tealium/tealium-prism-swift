//
//  MockConfig.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 17/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

let mockConfig = createMockConfig()
func createMockConfig() -> TealiumConfig {
    var config = TealiumConfig(account: "mock_account",
                               profile: "mock_profile",
                               environment: "dev",
                               modules: [],
                               settingsFile: nil,
                               settingsUrl: nil)
    config.databaseName = nil
    return config
}

extension TealiumConfig {
    /// The database file location, resolved by `DatabaseProvider.databaseUrl(for:databaseName:)`: `nil` (in-memory) without a `databaseName`.
    func databaseUrl() throws -> URL? {
        guard let databaseName else { return nil }
        return try DatabaseProvider.databaseUrl(for: self, databaseName: databaseName)
    }
}
