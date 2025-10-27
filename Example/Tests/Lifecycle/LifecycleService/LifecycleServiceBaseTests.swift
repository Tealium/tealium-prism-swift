//
//  LifecycleServiceBaseTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 02/12/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class LifecycleServiceBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var modulesRepository = SQLModulesRepository(dbProvider: dbProvider)
    lazy var dataStoreProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: modulesRepository)
    var dataStore: (any DataStore)!
    lazy var lifecycleStorage = LifecycleStorage(dataStore: dataStore)
    lazy var lifecycleService = LifecycleService(lifecycleStorage: lifecycleStorage, bundle: Bundle(for: type(of: self)))

    let launchTimestamp: Int64 = 1_731_061_966_000
    var launchDateString: String { Date(unixMilliseconds: launchTimestamp).iso8601String }
    var launchMmDdYyyyString: String { Date(unixMilliseconds: launchTimestamp).mmDDYYYYString }
    let millisecondsPerDay: Int64 = 86_400_000
    let millisecondsPerHour: Int64 = 3_600_000
    var secondsPerDay: Int64 { millisecondsPerDay / 1000 }
    var secondsPerHour: Int64 { millisecondsPerHour / 1000 }

    var lifecycleEventState: DataObject = [:]
    var customEventState: DataObject = [:]

    override func setUpWithError() throws {
        dataStore = try dataStoreProvider.getModuleStore(name: "Lifecycle")
    }
}
