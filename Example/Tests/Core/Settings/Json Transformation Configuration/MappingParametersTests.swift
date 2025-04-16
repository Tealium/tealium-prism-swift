//
//  MappingParametersTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class MappingParametersTests: XCTestCase {

    let basicParameters = MappingParameters(key: VariableAccessor(variable: "key", path: nil),
                                            filter: nil,
                                            mapTo: nil)
    let detailedParameters = MappingParameters(key: VariableAccessor(variable: "key", path: ["somePath"]),
                                               filter: ValueContainer("someFilter"),
                                               mapTo: ValueContainer("someMapValue"))

    func test_toDataObject_on_detailedParameters_returns_complete_object() throws {
        XCTAssertEqual(detailedParameters.toDataObject(), [
            "key": try DataItem(serializing: ["variable": "key", "path": ["somePath"]]),
            "filter": ["value": "someFilter"],
            "map_to": ["value": "someMapValue"],
        ])
    }

    func test_toDataObject_on_basicParameters_returns_object_without_nils() {
        XCTAssertEqual(basicParameters.toDataObject(), [
            "key": ["variable": "key"],
        ])
    }

    func test_toDataInput_on_detailedParameters_returns_complete_object() {
        XCTAssertEqual(detailedParameters.toDataInput() as? [String: DataInput], [
            "key": ["variable": "key", "path": ["somePath"]],
            "filter": ["value": "someFilter"],
            "map_to": ["value": "someMapValue"],
        ])
    }

    func test_toDataInput_on_basicParameters_returns_object_without_nils() {
        XCTAssertEqual(basicParameters.toDataInput() as? [String: DataInput], [
            "key": ["variable": "key"],
        ])
    }

    func test_init_from_converter_succeeds() {
        let item = DataItem(value: ["key": ["variable": "key", "path": ["somePath"]],
                                    "filter": ["value": "someFilter"],
                                    "map_to": ["value": "someMapValue"]])
        let result = MappingParameters.converter.convert(dataItem: item)
        XCTAssertEqual(result?.key.variable, "key")
        XCTAssertEqual(result?.key.path, ["somePath"])
        XCTAssertEqual(result?.filter?.value, "someFilter")
        XCTAssertEqual(result?.mapTo?.value, "someMapValue")
    }

    func test_init_from_converter_fails_if_item_is_not_an_object() {
        let item = DataItem(value: [])
        let result = MappingParameters.converter.convert(dataItem: item)
        XCTAssertNil(result)
    }
}
