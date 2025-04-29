//
//  SettingsManagerTestCase.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 27/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class SettingsManagerTestCase: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let networkHelper = MockNetworkHelper()
    let onActivity = ReplaySubject<ApplicationStatus>()
    lazy var config = createConfig(url: "someUrl")
    func createConfig(url: String?) -> TealiumConfig {
        TealiumConfig(account: "test",
                      profile: "test",
                      environment: "dev",
                      modules: [],
                      settingsFile: "localSettings.json",
                      settingsUrl: url)
    }
    func createCacher() throws -> ResourceCacher<DataObject> {
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        return ResourceCacher<DataObject>(dataStore: dataStore,
                                          fileName: "settings")
    }
    func getManager(url: String? = nil) throws -> SettingsManager {
        if let url {
            config.settingsUrl = url
        }
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        return try SettingsManager(config: config,
                                   dataStore: dataStore,
                                   networkHelper: networkHelper,
                                   logger: MockLogger())
    }

    func localRules() throws -> DataItem {
        try DataItem(serializing: [
            "id": "localRule",
            "conditions": [
                "operator": "and",
                "children": [
                    [
                        "variable": "variable",
                        "operator": "defined"
                    ]
                ]
            ]
        ])
    }

    func localTransformation() throws -> DataItem {
        try DataItem(serializing: [
            "transformation_id": "transformationId",
            "transformer_id": "transformerId",
            "scopes": ["afterCollectors"],
            "configuration": [
                "key": "value"
            ],
            "conditions": [
                "variable": "pageName",
                "path": ["container"],
                "operator": "equals",
                "filter": "Home"
            ]
        ])
    }
}
