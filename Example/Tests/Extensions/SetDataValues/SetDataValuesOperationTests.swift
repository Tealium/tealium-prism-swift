//
//  SetDataValuesOperationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 31/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SetDataValuesOperationTests: XCTestCase {

    let destination = ReferenceContainer.key("destination_key")

    func test_toDataObject_and_round_trip_with_reference() {
        let inputReference = ReferenceContainer.key("test_key")
        let operation = SetDataValuesOperation(input: .reference(inputReference), destination: destination)
        guard let result = SetDataValuesOperation(dataObject: operation.toDataObject()) else {
            XCTFail("Expected non-nil result")
            return
        }
        guard case .reference(let ref) = result.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, inputReference)
        XCTAssertEqual(result.destination, destination)
    }

    func test_toDataObject_and_round_trip_with_constant() {
        let inputValue = ValueContainer("test_value")
        let operation = SetDataValuesOperation(input: .constant(inputValue), destination: destination)
        guard let result = SetDataValuesOperation(dataObject: operation.toDataObject()) else {
            XCTFail("Expected non-nil result")
            return
        }
        guard case .constant(let value) = result.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.get(), "test_value")
        XCTAssertEqual(result.destination, destination)
    }

    func test_init_with_empty_data_returns_nil() {
        let result = SetDataValuesOperation(dataObject: [:])
        XCTAssertNil(result)
    }

    func test_reference_input_with_empty_key() {
        let reference = ReferenceContainer.key("")
        let operation = SetDataValuesOperation(input: .reference(reference), destination: destination)
        guard let result = SetDataValuesOperation(dataObject: operation.toDataObject()) else {
            XCTFail("Expected non-nil result")
            return
        }
        guard case .reference(let ref) = result.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, ReferenceContainer.key(""))
        XCTAssertEqual(result.destination, destination)
    }
}
