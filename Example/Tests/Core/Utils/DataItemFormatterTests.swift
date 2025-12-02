//
//  DataItemFormatterTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/11/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DataItemFormatterTests: XCTestCase {
    let formatter = DataItemFormatter.self

    func test_format_string_returns_string_without_quotes() {
        XCTAssertEqual(formatter.format(dataItem: DataItem(value: "value")), "value")
    }

    func test_format_number_returns_number_string() {
        XCTAssertEqual(formatter.format(dataItem: DataItem(value: 123)), "123")
    }

    func test_format_number_returns_big_number_without_scientific_notation() {
        XCTAssertEqual(formatter.format(dataItem: DataItem(value: 100_000_000_000_000_000.0)), "100000000000000000")
    }

    func test_format_bool_returns_bool_string() {
        XCTAssertEqual(formatter.format(dataItem: DataItem(value: true)), "true")
    }

    func test_format_null_returns_nil() {
        XCTAssertNil(formatter.format(dataItem: DataItem(value: NSNull())))
    }

    func test_format_json_objects_returns_json_serialization_with_scientific_notation() {
        let dataObject: DataObject = ["bigDouble": 100_000_000_000_000_000.0]
        XCTAssertEqual(formatter.format(dataItem: dataObject.toDataItem()),
                       "{\"bigDouble\":1e+17}")
    }

    func test_format_json_objects_returns_json_serialization_with_strings_with_quotes() {
        let dataObject: DataObject = ["key": "value"]
        XCTAssertEqual(formatter.format(dataItem: dataObject.toDataItem()),
                       "{\"key\":\"value\"}")
    }

    func test_format_json_objects_returns_json_serialization_with_nulls() {
        let dataObject: DataObject = ["key": NSNull()]
        XCTAssertEqual(formatter.format(dataItem: dataObject.toDataItem()),
                       "{\"key\":null}")
    }

    func test_format_array_returns_json_serialization() {
        let array = DataItem(converting: [
            DataItem(value: "value"),
            DataItem(value: 100_000_000_000_000_000.0),
            DataItem(value: NSNull())
        ])
        XCTAssertEqual(formatter.format(dataItem: array),
                       "[\"value\",1e+17,null]")
    }
}
