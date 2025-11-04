//
//  ValueContainerTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ReferenceContainerTests: XCTestCase {
    let key = ReferenceContainer(key: "someKey")
    let path = ReferenceContainer(path: JSONPath["container"]["key"])

    func test_toDataObject_returns_object_with_key() {
        XCTAssertEqual(key.toDataObject(), [
            "key": "someKey"
        ])
    }

    func test_toDataObject_returns_object_with_path() {
        XCTAssertEqual(path.toDataObject(), [
            "path": "container.key"
        ])
    }

    func test_toDataInput_returns_object_with_key() {
        XCTAssertEqual(key.toDataInput() as? [String: DataInput], [
            "key": "someKey"
        ])
    }

    func test_toDataInput_returns_object_with_path() {
        XCTAssertEqual(path.toDataInput() as? [String: DataInput], [
            "path": "container.key"
        ])
    }

    func test_init_from_converter_succeeds() {
        let result1 = ReferenceContainer.converter.convert(dataItem: DataItem(value: ["key": "someKey"]))
        XCTAssertEqual(result1?.path, JSONPath["someKey"])
        let result2 = ReferenceContainer.converter.convert(dataItem: DataItem(value: ["path": "container.key"]))
        XCTAssertEqual(result2?.path, JSONPath["container"]["key"])
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = ReferenceContainer.converter.convert(dataItem: item)
        XCTAssertNil(result)
    }
}
