//
//  DataLayerModuleTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 13/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

extension DataLayerModule {
    func put(key: String, value: DataInput) {
        self.put(key: key, value: value, expiry: .forever)
    }
    func put(data: DataObject) {
        self.put(data: data, expiry: .forever)
    }
}

final class DataLayerModuleTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: dbProvider,
                                                 modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
    var dataLayerModule: DataLayerModule!

    override func setUpWithError() throws {
        dataLayerModule = DataLayerModule(dataStore: try storeProvider.getModuleStore(name: DataLayerModule.id))
    }

    func test_put_and_remove_single_value() {
        dataLayerModule.put(key: "key", value: "value")
        XCTAssertEqual(dataLayerModule.get(key: "key"), "value")
        dataLayerModule.remove(key: "key")
        XCTAssertNil(dataLayerModule.getDataItem(key: "key"))
    }

    func test_put_and_remove_multiple_values() {
        dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        XCTAssertEqual(dataLayerModule.get(key: "key1"), "value1")
        XCTAssertEqual(dataLayerModule.get(key: "key2"), "value2")
        dataLayerModule.remove(keys: ["key1", "key2"])
        XCTAssertNil(dataLayerModule.getDataItem(key: "key1"))
        XCTAssertNil(dataLayerModule.getDataItem(key: "key2"))
    }

    func test_clear_removes_all_values() {
        dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        XCTAssertFalse(dataLayerModule.data.asDictionary().isEmpty, "DataLayer is not empty before remove all")
        dataLayerModule.clear()
        XCTAssertTrue(dataLayerModule.data.asDictionary().isEmpty, "DataLayer should be empty")
    }

    func test_data_retuns_all_data() {
        dataLayerModule.put(key: "key0", value: "value0")
        dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        XCTAssertEqual(dataLayerModule.data, ["key0": "value0", "key1": "value1", "key2": "value2"])
    }
}
