//
//  ValueContainerTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 29/01/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ValueContainerTests: XCTestCase {
    let container = ValueContainer("someValue")

    func test_toDataObject_returns_object_with_value() {
        XCTAssertEqual(container.toDataObject(), [
            "value": "someValue"
        ])
    }

    func test_toDataInput_returns_object_with_value() {
        XCTAssertEqual(container.toDataInput() as? [String: DataInput], [
            "value": "someValue"
        ])
    }

    func test_init_from_converter_succeeds_with_string() {
        let result = ValueContainer.converter.convert(dataItem: DataItem(value: ["value": "someValue"]))
        XCTAssertEqual(result?.value.get(), "someValue")
    }

    func test_init_from_converter_succeeds_with_number() {
        let result = ValueContainer.converter.convert(dataItem: DataItem(value: ["value": 42]))
        XCTAssertEqual(result?.value.get(), 42)
    }

    func test_init_from_converter_succeeds_with_bool() {
        let result = ValueContainer.converter.convert(dataItem: DataItem(value: ["value": true]))
        XCTAssertEqual(result?.value.get(), true)
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = ValueContainer.converter.convert(dataItem: item)
        XCTAssertNil(result)
    }

    func test_init_from_converter_fails_if_value_key_is_missing() {
        let item = DataItem(value: ["otherKey": "value"])
        let result = ValueContainer.converter.convert(dataItem: item)
        XCTAssertNil(result)
    }
}
