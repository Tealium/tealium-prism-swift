//
//  DataObject+VariableAccessorTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 15/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DataObjectVariableAccessorTests: XCTestCase {

    func test_extract_without_path_returns_root_item() {
        let dataObject: DataObject = [
            "key": "value"
        ]
        XCTAssertEqual(dataObject.extract("key")?.get(), "value")
    }

    func test_extract_with_empty_path_returns_root_item() {
        let dataObject: DataObject = [
            "key": "value"
        ]
        XCTAssertEqual(dataObject.extract(VariableAccessor(path: [], variable: "key"))?.get(), "value")
    }

    func test_extract_with_path_returns_nested_item() {
        let dataObject: DataObject = [
            "container": [
                "key": "value"
            ]
        ]
        XCTAssertEqual(dataObject.extract(VariableAccessor(path: ["container"], variable: "key"))?.get(), "value")
    }

    func test_extract_with_multiple_path_components_returns_nested_item() {
        let dataObject: DataObject = [
            "container1": [
                "container2": [
                    "key": "value"
                ]
            ]
        ]
        XCTAssertEqual(dataObject.extract(VariableAccessor(path: ["container1", "container2"], variable: "key"))?.get(), "value")
    }

    func test_extract_with_wrong_path_components_returns_nil() {
        let dataObject: DataObject = [
            "container1": [
                "container2": [
                    "key": "value"
                ]
            ]
        ]
        XCTAssertNil(dataObject.extract(VariableAccessor(path: ["container1", "wrong", "container2"], variable: "key")))
    }

    func test_extract_with_wrong_key_components_returns_nil() {
        let dataObject: DataObject = [
            "container1": [
                "container2": [
                    "key": "value"
                ]
            ]
        ]
        XCTAssertNil(dataObject.extract(VariableAccessor(path: ["container1", "container2"], variable: "wrong")))
    }

    func test_buildPathAndSet_sets_root_object_if_path_is_nil() {
        var dataObject = DataObject()
        dataObject.buildPathAndSet(accessor: "key", item: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["key": "value"])
    }

    func test_buildPathAndSet_sets_root_object_if_path_is_empty() {
        var dataObject = DataObject()
        dataObject.buildPathAndSet(accessor: VariableAccessor(path: [], variable: "key"),
                                   item: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["key": "value"])
    }

    func test_buildPathAndSet_sets_in_container_object_if_path_non_empty() {
        var dataObject = DataObject()
        dataObject.buildPathAndSet(accessor: VariableAccessor(path: ["container"], variable: "key"),
                                   item: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": ["key": "value"]])
    }

    func test_buildPathAndSet_sets_nested_objects_if_path_contains_mupltiple_containers() {
        var dataObject = DataObject()
        dataObject.buildPathAndSet(accessor: VariableAccessor(path: ["container1", "container2"], variable: "key"),
                                   item: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container1": ["container2": ["key": "value"]]])
    }

    func test_buildPathAndSet_merges_containers_when_already_present() {
        var dataObject: DataObject = ["container": ["existingKey": "existingValue"]]
        dataObject.buildPathAndSet(accessor: VariableAccessor(path: ["container"], variable: "key"),
                                   item: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": [
            "existingKey": "existingValue",
            "key": "value"
        ]])
    }

    func test_buildPathAndSet_replaces_non_containers_when_already_present() {
        var dataObject: DataObject = ["container": "not_a_container"]
        dataObject.buildPathAndSet(accessor: VariableAccessor(path: ["container"], variable: "key"),
                                   item: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": ["key": "value"]])
    }
}
