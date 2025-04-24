//
//  VariableAccessorTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class VariableAccessorTests: XCTestCase {
    let rootAccessor = VariableAccessor(variable: "key")
    let nestedAccessor = VariableAccessor(variable: "key", path: ["somePath"])

    func test_toDataObject_on_nestedAccessor_returns_complete_object() {
        XCTAssertEqual(nestedAccessor.toDataObject(), [
            "variable": "key",
            "path": ["somePath"]
        ])
    }

    func test_toDataObject_on_rootAccessor_returns_object_without_path() {
        XCTAssertEqual(rootAccessor.toDataObject(), [
            "variable": "key"
        ])
    }

    func test_toDataInput_on_nestedAccessor_returns_complete_object() {
        XCTAssertEqual(nestedAccessor.toDataInput() as? [String: DataInput], [
            "variable": "key",
            "path": ["somePath"]
        ])
    }

    func test_toDataInput_on_rootAccessor_returns_object_without_path() {
        XCTAssertEqual(rootAccessor.toDataInput() as? [String: DataInput], [
            "variable": "key"
        ])
    }

    func test_init_from_converter_succeeds() {
        let result = VariableAccessor.converter.convert(dataItem: DataItem(value: ["variable": "key",
                                                                                   "path": ["somePath"]]))
        XCTAssertEqual(result?.variable, "key")
        XCTAssertEqual(result?.path, ["somePath"])
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = VariableAccessor.converter.convert(dataItem: item)
        XCTAssertNil(result)
    }

    func test_init_from_stringLiteral_creates_accessor_without_path() {
        let accessor: VariableAccessor = "key"
        XCTAssertEqual(accessor.variable, "key")
        XCTAssertNil(accessor.path)
    }
}
