//
//  TransformationOperationTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TransformationOperationTests: XCTestCase {
    let converter = TransformationOperation.converter(parametersConverter: String.converter)
    let operation = TransformationOperation(output: VariableAccessor(variable: "key",
                                                                     path: nil),
                                                     parameters: "SomeParameter")

    func test_toDataObject_returns_complete_object() throws {
        XCTAssertEqual(operation.toDataObject(), [
            "output": ["variable": "key"],
            "parameters": "SomeParameter",
        ])
    }

    func test_toDataInput_returns_complete_object() {
        XCTAssertEqual(operation.toDataInput() as? [String: DataInput], [
            "output": ["variable": "key"],
            "parameters": "SomeParameter",
        ])
    }

    func test_init_from_converter_succeeds() {
        let item = DataItem(value: ["output": ["variable": "key"],
                                    "parameters": "SomeParameter"])
        let result = converter.convert(dataItem: item)
        XCTAssertEqual(result?.output.variable, "key")
        XCTAssertEqual(result?.parameters, "SomeParameter")
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = converter.convert(dataItem: item)
        XCTAssertNil(result)
    }

    func test_init_from_converter_fails_if_parameters_are_the_wrong_type() {
        let item = DataItem(value: ["output": ["variable": "key"],
                                    "parameters": ["SomeParameter"]])
        let result = converter.convert(dataItem: item)
        XCTAssertNil(result)
    }
}
