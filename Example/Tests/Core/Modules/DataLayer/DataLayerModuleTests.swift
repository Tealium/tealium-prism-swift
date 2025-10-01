//
//  DataLayerModuleTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

extension DataLayerModule {
    func put(key: String, value: DataInput) throws {
        try self.put(key: key, value: value, expiry: .forever)
    }
    func put(data: DataObject) throws {
        try self.put(data: data, expiry: .forever)
    }
}

final class DataLayerModuleTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: dbProvider,
                                                 modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
    var dataLayerModule: DataLayerModule!

    override func setUpWithError() throws {
        dataLayerModule = DataLayerModule(dataStore: try storeProvider.getModuleStore(name: DataLayerModule.moduleType))
    }

    func test_the_module_id_is_correct() {
        XCTAssertNotNil(storeProvider.modulesRepository.getModules()[DataLayerModule.moduleType])
    }

    func test_put_and_remove_single_value() throws {
        try dataLayerModule.put(key: "key", value: "value")
        XCTAssertEqual(dataLayerModule.get(key: "key"), "value")
        try dataLayerModule.remove(key: "key")
        XCTAssertNil(dataLayerModule.getDataItem(key: "key"))
    }

    func test_put_and_remove_multiple_values() throws {
        try dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        XCTAssertEqual(dataLayerModule.get(key: "key1"), "value1")
        XCTAssertEqual(dataLayerModule.get(key: "key2"), "value2")
        try dataLayerModule.remove(keys: ["key1", "key2"])
        XCTAssertNil(dataLayerModule.getDataItem(key: "key1"))
        XCTAssertNil(dataLayerModule.getDataItem(key: "key2"))
    }

    func test_clear_removes_all_values() throws {
        try dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        let dispatchContext = DispatchContext(source: .module(DataLayerModule.self), initialData: Dispatch(name: "datalayer").payload)
        XCTAssertFalse(dataLayerModule.collect(dispatchContext).asDictionary().isEmpty, "DataLayer is not empty before remove all")
        try dataLayerModule.clear()
        XCTAssertTrue(dataLayerModule.collect(dispatchContext).asDictionary().isEmpty, "DataLayer should be empty")
    }

    func test_collect_returns_all_data() throws {
        try dataLayerModule.put(key: "key0", value: "value0")
        try dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        let dispatchContext = DispatchContext(source: .module(DataLayerModule.self), initialData: Dispatch(name: "datalayer").payload)
        XCTAssertEqual(dataLayerModule.collect(dispatchContext), ["key0": "value0", "key1": "value1", "key2": "value2"])
    }

    func test_getAll_returns_all_data() throws {
        try dataLayerModule.put(key: "key0", value: "value0")
        try dataLayerModule.put(data: ["key1": "value1", "key2": "value2"])
        XCTAssertEqual(dataLayerModule.getAll(), ["key0": "value0", "key1": "value1", "key2": "value2"])
    }
}
