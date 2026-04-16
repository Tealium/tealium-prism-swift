//
//  LowerCaseTransformerTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 06/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LowerCaseTransformerTests: ExtensionsBaseTests {

    let transformer = LowerCaseTransformer()

    func test_id_returns_correct_value() {
        XCTAssertEqual(transformer.id, Modules.Types.lowerCaseTransformer)
    }

    func test_version_returns_correct_value() {
        XCTAssertEqual(transformer.version, TealiumConstants.libraryVersion)
    }

    func test_applyTransformation_with_all_variables_lowercases_string_values() throws {
        let dispatch = Dispatch(name: "test", data: ["key1": "HELLO", "key2": "WORLD"])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test"))
        let expectation = expectation(description: "String values are lowercased")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "key1"), "hello")
            XCTAssertEqual(result?.payload.get(key: "key2"), "world")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_all_variables_preserves_non_string_values() throws {
        let dispatch = Dispatch(name: "test", data: ["count": 42, "flag": true])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test"))
        let expectation = expectation(description: "Non-string values are preserved")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "count"), 42)
            XCTAssertEqual(result?.payload.get(key: "flag"), true)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_all_variables_lowercases_nested_array_strings() throws {
        let dispatch = Dispatch(name: "test", data: ["tags": ["FOO", "BAR"]])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test"))
        let expectation = expectation(description: "Nested array strings are lowercased")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.getArray(key: "tags"), ["foo", "bar"])
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_all_variables_lowercases_nested_dict_strings() throws {
        let dispatch = Dispatch(name: "test", data: ["nested": ["inner_key": "UPPER_VALUE"]])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test"))
        let expectation = expectation(description: "Nested dict strings are lowercased")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            let nested = result?.payload.getDataDictionary(key: "nested")
            XCTAssertEqual(nested?.get(key: "inner_key"), "upper_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_all_variables_preserves_visitor_id() throws {
        let visitorId = "ABC-123-UUID"
        let dispatch = Dispatch(name: "test", data: [TealiumDataKey.visitorId: visitorId, "other": "UPPERCASE"])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test"))
        let expectation = expectation(description: "Visitor ID is preserved unchanged")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: TealiumDataKey.visitorId), visitorId)
            XCTAssertEqual(result?.payload.get(key: "other"), "uppercase")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_specific_operations_lowercases_visitor_id_when_explicitly_targeted() throws {
        let visitorId = "ABC-123-UUID"
        let dispatch = Dispatch(name: "test", data: [TealiumDataKey.visitorId: visitorId])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test")
            .setAllVariables(false)
            .addVariable(.key(TealiumDataKey.visitorId)))
        let expectation = expectation(description: "Visitor ID is lowercased")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: TealiumDataKey.visitorId), visitorId.lowercased())
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_empty_configuration_lowercases_all_variables() {
        let dispatch = Dispatch(name: "test", data: ["key": "VALUE"])
        let settings = TransformationSettings(
            id: "test",
            transformerId: Modules.Types.lowerCaseTransformer,
            scopes: [.afterCollectors],
            configuration: [:]
        )
        let expectation = expectation(description: "Lowercases all variables when configuration is empty")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "key"), "value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_specific_operations_lowercases_targeted_key() throws {
        let dispatch = Dispatch(name: "test", data: ["email": "User@Example.COM", "name": "ALICE"])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test")
            .setAllVariables(false)
            .addVariable(.key("email")))
        let expectation = expectation(description: "Only targeted key is lowercased")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "email"), "user@example.com")
            XCTAssertEqual(result?.payload.get(key: "name"), "ALICE")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_specific_operations_skips_missing_source_key() throws {
        let dispatch = Dispatch(name: "test", data: ["existing": "VALUE"])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test")
            .setAllVariables(false)
            .addVariable(.key("missing_key")))
        let expectation = expectation(description: "Missing source key is silently skipped")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNil(result?.payload.getDataItem(key: "missing_key"))
            XCTAssertEqual(result?.payload.get(key: "existing"), "VALUE")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_specific_operations_skips_non_string_source() throws {
        let dispatch = Dispatch(name: "test", data: ["count": 99])
        let settings = try makeSettings(LowerCaseSettingsBuilder(id: "test")
            .setAllVariables(false)
            .addVariable(.key("count")))
        let expectation = expectation(description: "Non-string source is silently skipped")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload, dispatch.payload)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }
}
