//
//  MockConfig.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

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
