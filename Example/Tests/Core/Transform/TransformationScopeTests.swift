//
//  TransformationScopeTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TransformationScopeTests: XCTestCase {
    let converter = TransformationScope.converter

    // MARK: - Converter: string inputs

    func test_converter_aftercollectors_lowercase_returns_afterCollectors() {
        let result = converter.convert(dataItem: DataItem(value: "aftercollectors"))
        XCTAssertEqual(result, .afterCollectors)
    }

    func test_converter_aftercollectors_uppercase_returns_afterCollectors() {
        let result = converter.convert(dataItem: DataItem(value: "AFTERCOLLECTORS"))
        XCTAssertEqual(result, .afterCollectors)
    }

    func test_converter_alldispatchers_lowercase_returns_allDispatchers() {
        let result = converter.convert(dataItem: DataItem(value: "alldispatchers"))
        XCTAssertEqual(result, .allDispatchers)
    }

    func test_converter_alldispatchers_uppercase_returns_allDispatchers() {
        let result = converter.convert(dataItem: DataItem(value: "ALLDISPATCHERS"))
        XCTAssertEqual(result, .allDispatchers)
    }

    func test_converter_unknown_string_returns_nil() {
        XCTAssertNil(converter.convert(dataItem: DataItem(value: "unknown")))
    }

    func test_converter_empty_string_returns_nil() {
        XCTAssertNil(converter.convert(dataItem: DataItem(value: "")))
    }

    func test_converter_dispatcher_id_string_returns_nil() {
        XCTAssertNil(converter.convert(dataItem: DataItem(value: "Collect")))
    }

    // MARK: - Converter: array inputs

    func test_converter_array_of_ids_returns_dispatchers() {
        let ids = ["Collect", "Facebook"] as [DataInput]
        let result = converter.convert(dataItem: DataItem(value: ids))
        XCTAssertEqual(result, .dispatchers(["Collect", "Facebook"]))
    }

    func test_converter_empty_array_returns_dispatchers_with_empty_ids() {
        let result = converter.convert(dataItem: DataItem(value: [] as [DataInput]))
        XCTAssertEqual(result, .dispatchers([]))
    }

    // MARK: - toDataInput

    func test_toDataInput_afterCollectors_returns_correct_string() {
        let input = TransformationScope.afterCollectors.toDataInput()
        XCTAssertEqual(DataItem(value: input).get(), "aftercollectors")
    }

    func test_toDataInput_allDispatchers_returns_correct_string() {
        let input = TransformationScope.allDispatchers.toDataInput()
        XCTAssertEqual(DataItem(value: input).get(), "alldispatchers")
    }

    func test_toDataInput_dispatchers_returns_array_of_ids() {
        let input = TransformationScope.dispatchers(["Collect", "Facebook"]).toDataInput()
        XCTAssertEqual(DataItem(value: input).getArray()?.compactMap { $0 }, ["Collect", "Facebook"])
    }

    // MARK: - matchesScope (via TransformationSettings)

    func test_afterCollectors_scope_matches_afterCollectors_dispatchScope() {
        let transformation = makeTransformation(scope: .afterCollectors)
        XCTAssertTrue(transformation.matchesScope(.afterCollectors))
    }

    func test_afterCollectors_scope_does_not_match_dispatcher_dispatchScope() {
        let transformation = makeTransformation(scope: .afterCollectors)
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "Collect")))
    }

    func test_allDispatchers_scope_matches_any_dispatcher_dispatchScope() {
        let transformation = makeTransformation(scope: .allDispatchers)
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "any_dispatcher")))
    }

    func test_allDispatchers_scope_does_not_match_afterCollectors_dispatchScope() {
        let transformation = makeTransformation(scope: .allDispatchers)
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }

    func test_dispatchers_scope_matches_listed_dispatcher_id() {
        let transformation = makeTransformation(scope: .dispatchers(["specific_dispatcher"]))
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "specific_dispatcher")))
    }

    func test_dispatchers_scope_does_not_match_unlisted_dispatcher_id() {
        let transformation = makeTransformation(scope: .dispatchers(["specific_dispatcher"]))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "other_dispatcher")))
    }

    func test_dispatchers_scope_does_not_match_afterCollectors_dispatchScope() {
        let transformation = makeTransformation(scope: .dispatchers(["specific_dispatcher"]))
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }

    func test_dispatchers_scope_matching_is_case_sensitive() {
        let transformation = makeTransformation(scope: .dispatchers(["Collect"]))
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "Collect")))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "collect")))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "COLLECT")))
    }

    func test_dispatchers_scope_matches_all_listed_dispatcher_ids() {
        let transformation = makeTransformation(scope: .dispatchers(["Collect", "Facebook"]))
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "Collect")))
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "Facebook")))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "Firebase")))
    }
}

// MARK: - Helpers

private extension TransformationScopeTests {
    func makeTransformation(scope: TransformationScope) -> TransformationSettings {
        TransformationSettings(id: "test", transformerId: "test", scope: scope)
    }
}
