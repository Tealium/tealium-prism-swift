//
//  MappingsEngineTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

// Just added to make testing easier
extension ValueContainer: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension ValueContainer: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension ValueContainer: @retroactive ExpressibleByStringLiteral, @retroactive ExpressibleByStringInterpolation {
    /// Creates a `ValueContainer` from a string literal.
    /// - Parameter value: The string literal to use as the variable name.
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

final class MappingsEngineTests: XCTestCase {
    @StateSubject([
        "dispatcherId": [MappingOperation(destination: "dest_key",
                                          parameters: MappingParameters(reference: "key",
                                                                        filter: nil,
                                                                        mapTo: nil))]
    ])
    var mappings: ObservableState<[String: [MappingOperation]]>
    lazy var engine = MappingsEngine(mappings: mappings)

    let dispatch = Dispatch(payload: payload(), id: "dispatch_id", timestamp: 123)

    static private func payload() -> DataObject {
        [
            "key": "value",
            "container": [
                "key": DataItem(converting: "container.value"),
                "nested": DataItem(converting: [
                    "key": "container.nested.value"
                ])
            ],
            "array": ["1", "2", "3"]
        ]
    }

    func test_map_selects_mappings_with_correct_dispatcherId() {
        let result = engine.map(dispatcherId: "dispatcherId",
                                dispatch: dispatch)
        XCTAssertNotNil(result.payload.getDataItem(key: "dest_key"))
        XCTAssertNil(result.payload.getDataItem(key: "key"))
    }

    func test_map_leaves_dispatch_unaffected_if_dispatcherId_not_found() {
        let result = engine.map(dispatcherId: "missing_dispatcherId",
                                dispatch: dispatch)
        XCTAssertEqual(dispatch.payload, result.payload)
    }

    func test_map_operation_removes_all_non_mapped_data() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, ["dest_key": "value"])
    }

    func test_map_operation_maps_values_from_objects() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: JSONPath["container"]["key"],
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, ["dest_key": "container.value"])
    }

    func test_map_operation_maps_values_into_objects() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["containerDest"]["container.dest_key"],
                             parameters: MappingParameters(reference: "key",
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, ["containerDest": ["container.dest_key": "value"]])
    }

    func test_map_operation_maps_nested_values_into_objects() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["containerDest"]["container.dest_key"],
                             parameters: MappingParameters(reference: JSONPath["container"]["nested"]["key"],
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, ["containerDest": ["container.dest_key": "container.nested.value"]])
    }

    func test_map_operation_doesnt_apply_if_filter_doesnt_match() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "someOtherValue",
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, [:])
    }

    func test_map_operation_doesnt_apply_if_filter_doesnt_match_due_to_missing_key() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "missing_key",
                                                           filter: "value",
                                                           mapTo: "someConstant"))
        ])
        XCTAssertEqual(result.payload, [:])
    }

    func test_map_operation_applies_if_filter_matches() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "value",
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, ["dest": "value"])
    }

    func test_map_operation_applies_mapTo_constant_if_filter_matches() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "value",
                                                           mapTo: "otherValue"))
        ])
        XCTAssertEqual(result.payload, ["dest": "otherValue"])
    }

    func test_map_operation_doesnt_apply_mapTo_constant_if_filter_doesnt_match() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "non_matching",
                                                           mapTo: "otherValue"))
        ])
        XCTAssertEqual(result.payload, [:])
    }

    func test_map_operation_applies_mapTo_constant_if_no_filter_is_provided() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: nil,
                                                           filter: nil,
                                                           mapTo: "otherValue"))
        ])
        XCTAssertEqual(result.payload, ["dest": "otherValue"])
    }

    func test_map_multiple_operations_applies_all_mappings() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key1",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key2",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, [
            "dest_key1": "value",
            "dest_key2": "value"
        ])
    }

    func test_map_multiple_operations_overrides_previous_mappings_if_destination_is_the_same() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: JSONPath["container"]["key"],
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, [
            "dest_key": "container.value"
        ])
    }

    func test_map_multiple_operations_combines_previous_mappings_in_an_array_when_mapTo_is_provided() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: "someConstant"))
        ])
        XCTAssertEqual(result.payload, [
            "dest_key": ["value", "someConstant"]
        ])
    }

    func test_map_multiple_operations_overrides_previous_mappings_in_an_array_when_mapTo_is_not_provided() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: "someConstant")),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
        ])
        XCTAssertEqual(result.payload, [
            "dest_key": "value"
        ])
    }

    func test_map_multiple_operations_combines_previous_mappings_in_existing_array_when_mapTo_is_provided() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "array", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: "someConstant"))
        ])
        XCTAssertEqual(result.payload, [
            "dest_key": ["1", "2", "3", "someConstant"]
        ])
    }
}
