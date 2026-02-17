//
//  StringContainerTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class StringContainerTests: XCTestCase {
    let container = StringContainer("someValue")
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

    func test_init_from_converter_succeeds() {
        let result = StringContainer.converter.convert(dataItem: DataItem(value: ["value": "someValue"]))
        XCTAssertEqual(result?.value, "someValue")
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = StringContainer.converter.convert(dataItem: item)
        XCTAssertNil(result)
    }
}
