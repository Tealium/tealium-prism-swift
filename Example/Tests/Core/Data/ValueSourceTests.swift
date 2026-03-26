//
//  ValueSourceTests.swift
//  tealium-prism
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ValueSourceTests: XCTestCase {

    func test_converter_succeeds_with_reference() {
        let reference = ReferenceContainer.key("test_key")
        let dataItem = DataItem(converting: reference)
        let result = dataItem.getConvertible(converter: ValueSource.converter)
        guard case .reference(let ref) = result else {
            XCTFail("Expected reference value source")
            return
        }
        XCTAssertEqual(ref, .key("test_key"))
    }

    func test_converter_succeeds_with_constant() {
        let value = ValueContainer("test_value")
        let dataItem = DataItem(converting: value)
        let result = dataItem.getConvertible(converter: ValueSource.converter)
        guard case .constant(let container) = result else {
            XCTFail("Expected constant value source")
            return
        }
        XCTAssertEqual(container.value.get(), "test_value")
    }

    func test_converter_fails_with_invalid_data() {
        let dataItem = DataItem(value: "invalid_data")
        let result = dataItem.getConvertible(converter: ValueSource.converter)
        XCTAssertNil(result)
    }

    func test_toDataInput_reference_round_trips() {
        let original = ValueSource.reference(.path(JSONPath["test_key"]["nested"]))
        let dataItem = DataItem(value: original.toDataInput())
        let result = dataItem.getConvertible(converter: ValueSource.converter)
        guard case .reference(let ref) = result else {
            XCTFail("Expected reference value source")
            return
        }
        XCTAssertEqual(ref.path.render(), "test_key.nested")
    }

    func test_toDataInput_constant_round_trips() {
        let original = ValueSource.constant(ValueContainer("test_value"))
        let dataItem = DataItem(value: original.toDataInput())
        let result = dataItem.getConvertible(converter: ValueSource.converter)
        guard case .constant(let container) = result else {
            XCTFail("Expected constant value source")
            return
        }
        XCTAssertEqual(container.value.get(), "test_value")
    }
}
