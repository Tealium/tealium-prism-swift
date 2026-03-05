//
//  SetDataValuesTransformerTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SetDataValuesTransformerTests: XCTestCase {

    let transformer = SetDataValuesTransformer()

    func test_id_returnsCorrectValue() {
        XCTAssertEqual(transformer.id, Modules.Types.setDataValuesTransformer)
    }

    func test_version_returnsCorrectValue() {
        XCTAssertEqual(transformer.version, TealiumConstants.libraryVersion)
    }

    func test_applyTransformation_withInvalidConfiguration_completesWithOriginalDispatch() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = TransformationSettings(
            id: "test",
            transformerId: Modules.Types.setDataValuesTransformer,
            scopes: [.afterCollectors],
            configuration: [:] // invalid - no operations inside
        )
        let expectation = expectation(description: "Transformation completes with original dispatch when configuration is invalid")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload, dispatch.payload)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_withEmptyOperations_completesWithOriginalDispatch() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = SetDataValuesSettingsBuilder(id: "test").build()
        let expectation = expectation(description: "Transformation completes with original dispatch")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload, dispatch.payload)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_withReferenceOperation_copiesValue() {
        let dispatch = Dispatch(name: "test", data: ["source_key": "source_value"])
        let settings = SetDataValuesSettingsBuilder(id: "test")
            .addOperation(input: .key("source_key"), destination: .key("destination_key"))
            .build()
        let expectation = expectation(description: "Value is copied from source to destination")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "destination_key"), "source_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_withConstantOperation_setsValue() {
        let dispatch = Dispatch(name: "test", data: ["existing_key": "existing_value"])
        let settings = SetDataValuesSettingsBuilder(id: "test")
            .addOperation(input: ValueContainer("constant_value"), destination: .key("destination_key"))
            .build()
        let expectation = expectation(description: "Constant value is set to destination")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "destination_key"), "constant_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_withMultipleOperations_appliesAll() {
        let dispatch = Dispatch(name: "test", data: [
            "source1": "value1",
            "source2": "value2"
        ])
        let settings = SetDataValuesSettingsBuilder(id: "test")
            .addOperation(input: .key("source1"), destination: .key("dest1"))
            .addOperation(input: ValueContainer("constant"), destination: .key("dest2"))
            .build()
        let expectation = expectation(description: "All operations are applied")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            let dest1Value: String? = result?.payload.get(key: "dest1")
            let dest2Value: String? = result?.payload.get(key: "dest2")
            XCTAssertEqual(dest1Value, "value1")
            XCTAssertEqual(dest2Value, "constant")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_withMissingSourceReference_skipsOperation() {
        let dispatch = Dispatch(name: "test", data: ["existing_key": "existing_value"])
        let settings = SetDataValuesSettingsBuilder(id: "test")
            .addOperation(input: .key("missing_key"), destination: .key("destination_key"))
            .build()

        let expectation = expectation(description: "Operation is skipped for missing source")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNil(result?.payload.getDataItem(key: "destination_key"))
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }
}
