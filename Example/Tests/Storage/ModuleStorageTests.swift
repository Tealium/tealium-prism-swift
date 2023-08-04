//
//  DatabaseHelperTests.swift
//  tealium-swift_Example
//
//  Created by Tyler Rister on 30/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class ModuleStorageTests: XCTestCase {
    var databaseHelper: DatabaseHelper?
    var moduleStorage: ModuleStorage?

    override func setUp() {
        super.setUp()
        self.databaseHelper = try? DatabaseHelper(databaseName: nil,
                                                  coreSettings: CoreSettings(coreDictionary: ["account": "test", "profile": "test"]))
        guard let database = databaseHelper?.getDatabase() else {
            return
        }
        self.moduleStorage = try? ModuleStorage(database: database, moduleName: "test_module")
    }

    override func tearDown() {
        self.databaseHelper?.deleteDatabase()
        self.moduleStorage = nil
        super.tearDown()
    }
    func test_data_layer_builder_gets_commited() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        try? moduleStorage.edit().add(key: "key_to_remove_later", value: "value_to_remove_later").commit()
        // Test Key exists before bulk transaction
        XCTAssertEqual(moduleStorage.get(key: "key_to_remove_later") as? String, "value_to_remove_later")
        try? moduleStorage.edit()
            .add(key: "test_bulk_add1", value: "test_bulk_add_value1")
            .add(key: "test_bulk_add2", value: "test_bulk_add_value2")
            .remove(key: "key_to_remove_later")
            .commit()
        XCTAssertEqual(moduleStorage.get(key: "test_bulk_add1") as? String, "test_bulk_add_value1")
        XCTAssertEqual(moduleStorage.get(key: "test_bulk_add2") as? String, "test_bulk_add_value2")
        XCTAssertNil(moduleStorage.get(key: "key_to_remove_later"))
    }

    func test_data_layer_get_all() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        try? moduleStorage.edit()
            .add(key: "key1", value: "value1")
            .add(key: "key2", value: "value2")
            .add(key: "key3", value: "value3")
            .add(key: "key4", value: "value4")
            .commit()
        let dictionary = moduleStorage.getAll()
        XCTAssertEqual(dictionary["key1"] as? String, "value1")
        XCTAssertEqual(dictionary["key2"] as? String, "value2")
        XCTAssertEqual(dictionary["key3"] as? String, "value3")
        XCTAssertEqual(dictionary["key4"] as? String, "value4")
    }

    func test_data_layer_count() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        try? moduleStorage.edit()
            .add(key: "key1", value: "value1")
            .add(key: "key2", value: "value2")
            .add(key: "key3", value: "value3")
            .add(key: "key4", value: "value4")
            .commit()
        XCTAssertEqual(moduleStorage.count(), 4)
    }

    func test_data_layer_keys() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        try? moduleStorage.edit()
            .add(key: "key1", value: "value1")
            .add(key: "key2", value: "value2")
            .add(key: "key3", value: "value3")
            .add(key: "key4", value: "value4")
            .commit()
        let keys = moduleStorage.keys()
        XCTAssertEqual(keys, ["key1", "key2", "key3", "key4"])
    }

    func test_data_layer_add_all() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        var dictionary: TealiumDictionary = TealiumDictionary()
        dictionary["dictionary_key1"] = "dictionary_value1"
        dictionary["dictionary_key2"] = "dictionary_value2"
        dictionary["dictionary_key3"] = "dictionary_value3"
        dictionary["dictionary_key4"] = "dictionary_value4"
        try? moduleStorage.edit()
            .addAll(values: dictionary)
            .commit()
        let databaseDictionary = moduleStorage.getAll()
        XCTAssertEqual(databaseDictionary["dictionary_key1"] as? String, "dictionary_value1")
        XCTAssertEqual(databaseDictionary["dictionary_key2"] as? String, "dictionary_value2")
        XCTAssertEqual(databaseDictionary["dictionary_key3"] as? String, "dictionary_value3")
        XCTAssertEqual(databaseDictionary["dictionary_key4"] as? String, "dictionary_value4")
    }

    func test_expired_item_not_returned() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        try? moduleStorage.edit()
            .add(key: "test_valid_key1", value: "test_valid_value1", expiry: Expiry.afterCustom((TimeUnit.minutes, 5)))
            .add(key: "test_expired_key1", value: "test_expired_value1", expiry: Expiry.after(Date()))
            .commit()
        let databaseDictionary = moduleStorage.getAll()
        XCTAssertEqual(databaseDictionary["test_valid_key1"] as? String, "test_valid_value1")
        XCTAssertNil(databaseDictionary["test_expired_key1"])
    }

    func test_existing_row_gets_updated() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        try? moduleStorage.edit()
            .add(key: "test_key_that_will_be_updated", value: "Test Value 1")
            .commit()
        let currentKey = moduleStorage.get(key: "test_key_that_will_be_updated")
        XCTAssertEqual(currentKey as? String, "Test Value 1")
        try? moduleStorage.edit()
            .add(key: "test_key_that_will_be_updated", value: "Test Value 2")
            .commit()
        let newUpdate = moduleStorage.get(key: "test_key_that_will_be_updated")
        XCTAssertEqual(newUpdate as? String, "Test Value 2")
    }

    func test_insert_different_types() {
        guard let moduleStorage = moduleStorage else {
            XCTFail("Failed to create data layer storage")
            return
        }
        let string = "String"
        let int: Int = 4
        let double: Double = 3.1415
        let bool: Bool = false
        let tealiumArray: [TealiumDataValue] = ["test", 1, 3.2]
        let tealiumDictionary: TealiumDictionaryOptionals = ["test_key_1": "test_value_1", "test_int_key": 4, "test_nested": ["test_sub_key1": "test_sub_value_1"]]
        try? moduleStorage.edit()
            .add(key: "string_value", value: string)
            .add(key: "int_value", value: int)
            .add(key: "double_value", value: double)
            .add(key: "bool_value", value: bool)
            .add(key: "array_value", value: tealiumArray)
            .add(key: "dictionary_value", value: tealiumDictionary)
            .commit()
        let grabbedString = moduleStorage.get(key: "string_value") as? String
        let grabbedInt = moduleStorage.get(key: "int_value") as? Int
        let grabbedDouble = moduleStorage.get(key: "double_value") as? Double
        let grabbedBool = moduleStorage.get(key: "bool_value") as? Bool
        let grabbedArray = moduleStorage.get(key: "array_value") as? [Any]
        let grabbedDictionary = moduleStorage.get(key: "dictionary_value") as? [String: Any?]
        XCTAssertEqual(grabbedString, "String")
        XCTAssertEqual(grabbedInt, 4)
        XCTAssertEqual(grabbedDouble, 3.1415)
        XCTAssertEqual(grabbedBool, false)
        XCTAssertEqual(grabbedArray?[0] as? String, "test")
        XCTAssertEqual(grabbedArray?[1] as? Int, 1)
        XCTAssertEqual(grabbedArray?[2] as? Double, 3.2)
        XCTAssertEqual(grabbedDictionary?["test_key_1"] as? String, "test_value_1")
    }

    func test_getOrCreateModule_creates_module() {
        guard let database = databaseHelper?.getDatabase() else {
            XCTFail("Could not get database.")
            return
        }
        XCTAssertNoThrow(try database.run("DELETE FROM module;"))
        do {
            let count = try database.scalar(ModuleSchema.table.count)
            XCTAssertNoThrow(try database.run("UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='module';"))
            if count > 0 {
                XCTFail("Failed to clear all modules")
            }
            let moduleId = try? moduleStorage?.getOrCreateModule()
            XCTAssertEqual(moduleId, 1)
            let secondModuleId = try? moduleStorage?.getOrCreateModule()
            XCTAssertEqual(secondModuleId, 1)
        } catch {
            XCTFail("Failed to get module count.")
            return
        }
    }

    func test_getType_functions() {
        let intValue = 4
        let stringValue = "test_string_value"
        let doubleValue = 5.2
        let arrayValue: [TealiumDataValue] = ["test1", "test2", "test3"]
        let dictionaryValue: [String: TealiumDataValue?] = ["key1": "value1", "key2": "value2"]
        try? moduleStorage?.edit()
            .add(key: "int_value", value: intValue)
            .add(key: "string_value", value: stringValue)
            .add(key: "double_value", value: doubleValue)
            .add(key: "array_value", value: arrayValue)
            .add(key: "dictionary_value", value: dictionaryValue)
            .commit()
        XCTAssertEqual(moduleStorage?.getInt(key: "int_value"), 4)
        XCTAssertEqual(moduleStorage?.getString(key: "string_value"), "test_string_value")
        XCTAssertEqual(moduleStorage?.getDouble(key: "double_value"), 5.2)

        let arrayBack = moduleStorage?.getArray(key: "array_value")
        XCTAssertEqual(arrayBack?[0] as? String, "test1")
        XCTAssertEqual(arrayBack?[1] as? String, "test2")
        XCTAssertEqual(arrayBack?[2] as? String, "test3")

        let dictionaryBack = moduleStorage?.getDictionary(key: "dictionary_value")
        XCTAssertEqual(dictionaryBack?["key1"] as? String, "value1")
        XCTAssertEqual(dictionaryBack?["key2"] as? String, "value2")
    }
}
