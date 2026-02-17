//
//  SetDataValuesParametersTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SetDataValuesParametersTests: XCTestCase {
    let converter = SetDataValuesParameters.converter

    func test_toDataInput_withReference_roundTrips() {
        let params = SetDataValuesParameters(input: .reference(.key("test_key")))
        let dataItem = DataItem(value: params.toDataInput())
        let result = dataItem.getConvertible(converter: converter)
        guard case .reference(let ref) = result?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("test_key"))
    }

    func test_toDataInput_withConstant_roundTrips() {
        let params = SetDataValuesParameters(input: .constant(ValueContainer("test_value")))
        let dataItem = DataItem(value: params.toDataInput())
        let result = dataItem.getConvertible(converter: converter)
        guard case .constant(let value) = result?.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.get(), "test_value")
    }

    func test_converter_withReferenceContainer() {
        let reference = ReferenceContainer.key("test_key")
        let dataItem = DataItem(converting: reference)
        let result = dataItem.getConvertible(converter: converter)
        guard case .reference(let ref) = result?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("test_key"))
    }

    func test_converter_withValueContainer() {
        let value = ValueContainer("test_value")
        let dataItem = DataItem(converting: value)
        let result = dataItem.getConvertible(converter: converter)
        guard case .constant(let container) = result?.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(container.value.get(), "test_value")
    }

    func test_converter_withInvalidDataItem_returnsNil() {
        let dataItem = DataItem(value: "invalid_data")
        let result = dataItem.getConvertible(converter: converter)
        XCTAssertNil(result)
    }

    func test_roundTrip_withReference_preservesData() {
        let original = SetDataValuesParameters(input: .reference(.key("test_reference")))
        let dataItem = DataItem(value: original.toDataInput())
        let result = dataItem.getConvertible(converter: converter)
        guard case .reference(let ref) = result?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("test_reference"))
    }

    func test_roundTrip_withConstant_preservesData() {
        let original = SetDataValuesParameters(input: .constant(ValueContainer("constant_test_value")))
        let dataItem = DataItem(value: original.toDataInput())
        let result = dataItem.getConvertible(converter: converter)
        guard case .constant(let value) = result?.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.get(), "constant_test_value")
    }

    func test_converter_withEmptyKey() {
        let reference = ReferenceContainer.key("")
        let dataItem = DataItem(converting: reference)
        let result = dataItem.getConvertible(converter: converter)
        guard case .reference(let ref) = result?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key(""))
    }
}
