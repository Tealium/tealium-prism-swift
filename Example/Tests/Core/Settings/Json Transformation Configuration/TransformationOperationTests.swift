//
//  TransformationOperationTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TransformationOperationTests: XCTestCase {
    let converter = TransformationOperation.converter(parametersConverter: String.converter)
    let operation = TransformationOperation(destination: "key",
                                            parameters: "SomeParameter")

    func test_toDataObject_returns_complete_object() throws {
        XCTAssertEqual(operation.toDataObject(), [
            "destination": ["key": "key"],
            "parameters": "SomeParameter",
        ])
    }

    func test_toDataInput_returns_complete_object() {
        XCTAssertEqual(operation.toDataInput() as? [String: DataInput], [
            "destination": ["key": "key"],
            "parameters": "SomeParameter",
        ])
    }

    func test_init_from_converter_succeeds() {
        let item = DataItem(value: ["destination": ["key": "key"],
                                    "parameters": "SomeParameter"])
        let result = converter.convert(dataItem: item)
        XCTAssertEqual(result?.destination.path, JSONPath["key"])
        XCTAssertEqual(result?.parameters, "SomeParameter")
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = converter.convert(dataItem: item)
        XCTAssertNil(result)
    }

    func test_init_from_converter_fails_if_parameters_are_the_wrong_type() {
        let item = DataItem(value: ["destination": ["key": "key"],
                                    "parameters": ["SomeParameter"]])
        let result = converter.convert(dataItem: item)
        XCTAssertNil(result)
    }
}
