//
//  SetDataValuesConfigurationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SetDataValuesConfigurationTests: XCTestCase {

    func test_init_withEmptyDataObject_returnsNil() {
        let configuration = SetDataValuesConfiguration(dataObject: [:])
        XCTAssertNil(configuration)
    }

    func test_init_withMissingOperations_returnsNil() {
        let configuration = SetDataValuesConfiguration(dataObject: ["other_key": "value"])
        XCTAssertNil(configuration)
    }

    func test_init_withEmptyOperations_returnsNil() {
        let configuration = SetDataValuesConfiguration(dataObject: [
            SetDataValuesConfiguration.Keys.operations: DataItem(value: [])
        ])
        XCTAssertNil(configuration)
    }

    func test_init_withSingleOperation_returnsConfiguration() {
        let operation = SetDataValuesOperation(
            input: .reference(.key("source_key")),
            destination: .key("dest_key")
        )
        let dataObject: DataObject = [
            SetDataValuesConfiguration.Keys.operations: [operation.toDataObject()]
        ]
        let configuration = SetDataValuesConfiguration(dataObject: dataObject)
        XCTAssertEqual(configuration?.operations.count, 1)
        XCTAssertEqual(configuration?.operations.first?.destination, .key("dest_key"))
        guard case .reference(let ref) = configuration?.operations.first?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("source_key"))
    }

    func test_init_withMultipleOperations_returnsConfiguration() {
        let operation1 = SetDataValuesOperation(
            input: .reference(.key("source1")),
            destination: .key("dest1")
        )
        let operation2 = SetDataValuesOperation(
            input: .constant(ValueContainer("constant")),
            destination: .key("dest2")
        )
        let dataObject: DataObject = [
            SetDataValuesConfiguration.Keys.operations: [
                operation1.toDataObject(),
                operation2.toDataObject()
            ]
        ]
        let configuration = SetDataValuesConfiguration(dataObject: dataObject)
        XCTAssertEqual(configuration?.operations.count, 2)
    }

    func test_toDataObject_withEmptyOperations_returnsValidDataObject() {
        let configuration = SetDataValuesConfiguration(operations: [])
        let dataObject = configuration.toDataObject()
        XCTAssertEqual(dataObject.getDataArray(key: SetDataValuesConfiguration.Keys.operations)?.count, 0)
    }

    func test_toDataObject_withOperations_returnsValidDataObject() {
        let operation = SetDataValuesOperation(
            input: .reference(.key("source_key")),
            destination: .key("dest_key")
        )
        let configuration = SetDataValuesConfiguration(operations: [operation])
        let dataObject = configuration.toDataObject()
        let operationsArray = dataObject.getDataArray(key: SetDataValuesConfiguration.Keys.operations)
        XCTAssertEqual(operationsArray?.count, 1)
    }

    func test_roundTrip_withMultipleOperations_preservesData() {
        let operation1 = SetDataValuesOperation(
            input: .reference(.key("source1")),
            destination: .key("dest1")
        )
        let operation2 = SetDataValuesOperation(
            input: .constant(ValueContainer("constant")),
            destination: .key("dest2")
        )
        let original = SetDataValuesConfiguration(operations: [operation1, operation2])
        let dataObject = original.toDataObject()
        let restored = SetDataValuesConfiguration(dataObject: dataObject)
        XCTAssertEqual(restored?.operations.count, 2)
        XCTAssertEqual(restored?.operations[0].destination, .key("dest1"))
        XCTAssertEqual(restored?.operations[1].destination, .key("dest2"))
    }

    func test_init_withInvalidOperationData_filtersOutInvalidOperations() {
        let validOperation = SetDataValuesOperation(
            input: .reference(.key("source_key")),
            destination: .key("dest_key")
        )
        let dataObject: DataObject = [
            SetDataValuesConfiguration.Keys.operations: [
                validOperation.toDataObject(),
                DataObject()
            ]
        ]
        let configuration = SetDataValuesConfiguration(dataObject: dataObject)
        XCTAssertEqual(configuration?.operations.count, 1)
    }
}
