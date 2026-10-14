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
extension StringContainer: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension StringContainer: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension StringContainer: @retroactive ExpressibleByStringLiteral, @retroactive ExpressibleByStringInterpolation {
    /// Creates a `StringContainer` from a string literal.
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

    let dispatch = Dispatch(payload: MappingsEngineTests.payload(), id: "dispatch_id", timestamp: 123)

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

    private func expectedPayload(mergingWith changes: DataObject) -> DataObject {
        dispatch.payload.deepMerge(with: changes)
    }

    func test_map_selects_mappings_with_correct_dispatcherId() {
        let result = engine.map(dispatcherId: "dispatcherId",
                                dispatch: dispatch)
        XCTAssertNotNil(result.payload.getDataItem(key: "dest_key"))
        XCTAssertNotNil(result.payload.getDataItem(key: "key"))
    }

    func test_map_leaves_dispatch_unaffected_if_dispatcherId_not_found() {
        let result = engine.map(dispatcherId: "missing_dispatcherId",
                                dispatch: dispatch)
        XCTAssertEqual(dispatch.payload, result.payload)
    }

    func test_map_operation_keeps_all_non_mapped_data() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest_key": "value"]))
    }

    func test_map_operation_maps_values_from_objects() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: JSONPath["container"]["key"],
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest_key": "container.value"]))
    }

    func test_map_operation_maps_values_into_objects() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["containerDest"]["container.dest_key"],
                             parameters: MappingParameters(reference: "key",
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["containerDest": ["container.dest_key": "value"]]))
    }

    func test_map_operation_maps_nested_values_into_objects() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["containerDest"]["container.dest_key"],
                             parameters: MappingParameters(reference: JSONPath["container"]["nested"]["key"],
                                                           filter: nil,
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["containerDest": ["container.dest_key": "container.nested.value"]]))
    }

    func test_map_operation_doesnt_apply_if_filter_doesnt_match() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "someOtherValue",
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, dispatch.payload)
    }

    func test_map_operation_doesnt_apply_if_filter_doesnt_match_due_to_missing_key() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "missing_key",
                                                           filter: "value",
                                                           mapTo: ValueContainer("someConstant")))
        ])
        XCTAssertEqual(result.payload, dispatch.payload)
    }

    func test_map_operation_applies_if_filter_matches() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "value",
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest": "value"]))
    }

    func test_map_operation_applies_mapTo_constant_if_filter_matches() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "value",
                                                           mapTo: ValueContainer("otherValue")))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest": "otherValue"]))
    }

    func test_map_operation_doesnt_apply_mapTo_constant_if_filter_doesnt_match() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "non_matching",
                                                           mapTo: ValueContainer("otherValue")))
        ])
        XCTAssertEqual(result.payload, dispatch.payload)
    }

    func test_map_operation_applies_mapTo_constant_if_no_filter_is_provided() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: nil,
                                                           filter: nil,
                                                           mapTo: ValueContainer("otherValue")))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest": "otherValue"]))
    }

    func test_map_multiple_operations_applies_all_mappings() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key1",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key2",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: [
            "dest_key1": "value",
            "dest_key2": "value"
        ]))
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
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: [
            "dest_key": "container.value"
        ]))
    }

    func test_map_operation_overwrites_existing_array_index_without_shifting() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: "array", filter: nil, mapTo: nil)),
            MappingOperation(destination: JSONPath["dest"][1],
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: [
            "dest": ["1", "value", "3"]
        ]))
    }

    func test_map_operation_with_empty_mappings_leaves_payload_unchanged() {
        let result = engine.map(dispatch: dispatch, mappings: [])
        XCTAssertEqual(result.payload, dispatch.payload)
    }

    func test_map_operation_overwrites_existing_payload_value_with_constant() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("constant")))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["key": "constant"]))
    }

    func test_map_operation_overwrites_existing_payload_array_with_value() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "array",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["array": "value"]))
    }

    func test_map_operation_skipped_by_filter_leaves_existing_payload_value_intact() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "container",
                             parameters: MappingParameters(reference: "key",
                                                           filter: "non_matching",
                                                           mapTo: nil))
        ])
        XCTAssertEqual(result.payload, dispatch.payload)
    }

    func test_map_operation_with_missing_source_leaves_existing_payload_value_intact() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "key",
                             parameters: MappingParameters(reference: "missing_key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, dispatch.payload)
    }

    func test_map_operation_to_nested_destination_keeps_sibling_payload_values() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["container"]["other"],
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.extractDataItem(path: JSONPath["container"]["key"])?.get(), "container.value")
        XCTAssertEqual(result.payload.extractDataItem(path: JSONPath["container"]["other"])?.get(), "value")
        XCTAssertNotNil(result.payload.extractDataItem(path: JSONPath["container"]["nested"]["key"]))
    }

    func test_map_operation_to_array_index_destination_keeps_other_payload_array_elements() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["array"][1],
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        var expected = dispatch.payload
        expected.set(converting: ["1", "value", "3"], key: "array")
        XCTAssertEqual(result.payload, expected)
    }

    func test_map_operations_dont_chain() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "container",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "chained",
                             parameters: MappingParameters(reference: "container", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.extractDataItem(path: JSONPath["chained"]["key"])?.get(), "container.value")
        XCTAssertEqual(result.payload.getDataItem(key: "container")?.get(), "value")
    }

    func test_map_operations_read_the_original_value_regardless_of_order() {
        let aToB = MappingOperation(destination: "b", parameters: MappingParameters(reference: "a", filter: nil, mapTo: nil))
        let bToC = MappingOperation(destination: "c", parameters: MappingParameters(reference: "b", filter: nil, mapTo: nil))
        let input = Dispatch(payload: ["a": "original_a", "b": "original_b"], id: "dispatch_id", timestamp: 123)
        let expected = input.payload.deepMerge(with: ["b": "original_a", "c": "original_b"])

        XCTAssertEqual(engine.map(dispatch: input, mappings: [aToB, bToC]).payload, expected)
        XCTAssertEqual(engine.map(dispatch: input, mappings: [bToC, aToB]).payload, expected)
    }

    func test_map_operations_swapping_two_keys_swaps_their_values() {
        let input = Dispatch(payload: ["a": "original_a", "b": "original_b"], id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: input, mappings: [
            MappingOperation(destination: "b", parameters: MappingParameters(reference: "a", filter: nil, mapTo: nil)),
            MappingOperation(destination: "a", parameters: MappingParameters(reference: "b", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, input.payload.deepMerge(with: ["a": "original_b", "b": "original_a"]))
    }

    func test_map_operation_filter_sees_the_original_value_of_a_key_overwritten_by_a_previous_mapping() {
        let input = Dispatch(payload: ["a": "original_a", "b": "original_b"], id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: input, mappings: [
            MappingOperation(destination: "b", parameters: MappingParameters(reference: "a", filter: nil, mapTo: nil)),
            MappingOperation(destination: "c", parameters: MappingParameters(reference: "b", filter: "original_a", mapTo: nil)),
            MappingOperation(destination: "d", parameters: MappingParameters(reference: "b", filter: "original_b", mapTo: nil))
        ])
        XCTAssertEqual(result.payload, input.payload.deepMerge(with: ["b": "original_a", "d": "original_b"]))
    }

    func test_map_variable_from_command_name_reads_the_original_value_not_the_appended_array() {
        let input = Dispatch(payload: ["command_name": "a"], id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: input, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("b"))),
            MappingOperation(destination: "copy",
                             parameters: MappingParameters(reference: JSONPath[TealiumDataKey.commandName], filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.getDataItem(key: "copy")?.get(), "a")
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["a", "b"])
    }

    func test_map_operation_pads_array_at_new_index_while_filtered_out_mapping_leaves_existing_index_intact() {
        var payload = dispatch.payload
        payload.set(converting: [1, 2], key: "a")
        let result = engine.map(dispatch: Dispatch(payload: payload, id: "dispatch_id", timestamp: 123), mappings: [
            MappingOperation(destination: JSONPath["a"][2],
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: JSONPath["a"][0],
                             parameters: MappingParameters(reference: "key", filter: "non_matching", mapTo: nil))
        ])
        var expected = payload
        expected.set(converting: DataItem(value: [1, 2, "value"]), key: "a")
        XCTAssertEqual(result.payload, expected)
    }

    func test_map_operation_keeps_lone_array_constant_as_array() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer(["1", "2"])))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest": DataItem(value: ["1", "2"])]))
    }

    func test_map_multiple_constants_to_the_same_destination_keep_the_last_one() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("first"))),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("second")))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest_key": "second"]))
    }

    func test_map_variable_then_constant_to_the_same_destination_keeps_the_constant() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("someConstant")))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest_key": "someConstant"]))
    }

    func test_map_constant_then_variable_to_the_same_destination_keeps_the_variable() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("someConstant"))),
            MappingOperation(destination: "dest_key",
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["dest_key": "value"]))
    }

    func test_map_multiple_constants_to_the_same_array_index_replace_instead_of_nesting() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["array"][2],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("first"))),
            MappingOperation(destination: JSONPath["array"][2],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("second")))
        ])
        XCTAssertEqual(result.payload, expectedPayload(mergingWith: ["array": ["1", "2", "second"]]))
    }

    func test_map_constants_to_command_name_are_appended() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("first"))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("second"))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("third")))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["first", "second", "third"])
    }

    func test_map_variable_to_command_name_is_appended() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: JSONPath["container"]["key"], filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["value", "container.value"])
    }

    func test_map_variable_then_constant_to_command_name_are_appended() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil)),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("constant")))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["value", "constant"])
    }

    func test_map_constant_then_variable_to_command_name_are_appended() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("constant"))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["constant", "value"])
    }

    func test_map_to_command_name_is_appended_after_existing_string_in_payload() {
        var payload = dispatch.payload
        payload.set(converting: "existing", key: TealiumDataKey.commandName)
        let payloadDispatch = Dispatch(payload: payload, id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: payloadDispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("constant"))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["existing", "constant", "value"])
    }

    func test_map_to_command_name_is_appended_after_existing_array_in_payload() {
        var payload = dispatch.payload
        payload.set(converting: ["a", "b"], key: TealiumDataKey.commandName)
        let payloadDispatch = Dispatch(payload: payload, id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: payloadDispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("constant")))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["a", "b", "constant"])
    }

    func test_map_mixed_scalar_and_array_constants_to_command_name_are_flattened_in_mapping_order() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("3"))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer(["1", "2"]))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer(["4", "5"]))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("6")))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["3", "1", "2", "4", "5", "6"])
    }

    func test_map_array_variable_to_command_name_is_flattened_with_constants() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "array", filter: nil, mapTo: nil)),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("constant")))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["1", "2", "3", "constant"])
    }

    func test_map_to_nested_command_name_replaces_instead_of_combining() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath["obj"][TealiumDataKey.commandName],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("first"))),
            MappingOperation(destination: JSONPath["obj"][TealiumDataKey.commandName],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("second")))
        ])
        XCTAssertEqual(result.payload.extractDataItem(path: JSONPath["obj"][TealiumDataKey.commandName])?.get(), "second")
    }

    func test_map_to_command_name_array_index_replaces_instead_of_combining() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: JSONPath[TealiumDataKey.commandName][0],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("first"))),
            MappingOperation(destination: JSONPath[TealiumDataKey.commandName][0],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("second")))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["second"])
    }

    func test_map_skipped_mapping_to_command_name_leaves_payload_value_unchanged() {
        var payload = dispatch.payload
        payload.set(converting: "existing", key: TealiumDataKey.commandName)
        let payloadDispatch = Dispatch(payload: payload, id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: payloadDispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "key", filter: "non_matching", mapTo: ValueContainer("constant"))),
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "missing_key", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload, payloadDispatch.payload)
    }

    func test_map_variable_to_container_then_constant_to_child_gives_the_constant() {
        let result = engine.map(dispatch: dispatch, mappings: [
            MappingOperation(destination: "obj",
                             parameters: MappingParameters(reference: "container", filter: nil, mapTo: nil)),
            MappingOperation(destination: JSONPath["obj"]["key"],
                             parameters: MappingParameters(reference: nil, filter: nil, mapTo: ValueContainer("c")))
        ])
        XCTAssertEqual(result.payload.extractDataItem(path: JSONPath["obj"]["key"])?.get(), "c")
    }

    func test_map_operation_with_object_path_destination_replaces_non_object_parent_with_object() {
        var payload = dispatch.payload
        payload.set(converting: "bob", key: "user")
        let payloadDispatch = Dispatch(payload: payload, id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: payloadDispatch, mappings: [
            MappingOperation(destination: JSONPath["user"]["id"],
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        var expected = payload
        expected.set(converting: ["id": "value"], key: "user")
        XCTAssertEqual(result.payload, expected)
    }

    func test_map_operation_with_array_path_destination_replaces_non_array_parent_with_array() {
        var payload = dispatch.payload
        payload.set(converting: ["x": 1], key: "a")
        let payloadDispatch = Dispatch(payload: payload, id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: payloadDispatch, mappings: [
            MappingOperation(destination: JSONPath["a"][0],
                             parameters: MappingParameters(reference: "key", filter: nil, mapTo: nil))
        ])
        var expected = payload
        expected.set(converting: ["value"], key: "a")
        XCTAssertEqual(result.payload, expected)
    }

    func test_map_array_variable_to_command_name_is_appended_after_existing_string_in_payload() {
        var payload = dispatch.payload
        payload.set(converting: "a", key: TealiumDataKey.commandName)
        payload.set(converting: ["b", "c"], key: "commands")
        let payloadDispatch = Dispatch(payload: payload, id: "dispatch_id", timestamp: 123)
        let result = engine.map(dispatch: payloadDispatch, mappings: [
            MappingOperation(destination: TealiumDataKey.commandName,
                             parameters: MappingParameters(reference: "commands", filter: nil, mapTo: nil))
        ])
        XCTAssertEqual(result.payload.getArray(key: TealiumDataKey.commandName), ["a", "b", "c"])
    }
}
