//
//  MappingOperationBuilderTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 22/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class MappingOperationBuilderTests: XCTestCase {

    func test_build_creates_key_and_destination() {
        let builder = MappingOperationBuilder(key: "source", destination: "destination")
        let operation = builder.build()

        XCTAssertEqual(operation.parameters.key.variable, "source")
        XCTAssertEqual(operation.destination.variable, "destination")
        XCTAssertNil(operation.parameters.filter)
        XCTAssertNil(operation.parameters.mapTo)
    }

    func test_build_adds_filter_when_IfInputEquals_is_called() {
        let filterValue = "testValue"
        let builder = MappingOperationBuilder(key: "source", destination: "destination")
            .ifInputEquals(filterValue)
        let operation = builder.build()

        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
        XCTAssertNil(operation.parameters.mapTo)
    }

    func test_build_adds_mapTo_when_mapTo_is_called() {
        let mapToValue = "mappedValue"
        let builder = MappingOperationBuilder(key: "source", destination: "destination")
            .mapTo(mapToValue)
        let operation = builder.build()

        XCTAssertEqual(operation.parameters.mapTo?.value, mapToValue)
        XCTAssertNil(operation.parameters.filter)
    }

    func test_build_creates_complete_operation() {
        let sourceKey = VariableAccessor(variable: "source", path: ["nested"])
        let destinationKey = VariableAccessor(variable: "destination", path: ["target"])
        let filterValue = "originalValue"
        let mapToValue = "mappedValue"

        let builder = MappingOperationBuilder(key: sourceKey, destination: destinationKey)
            .ifInputEquals(filterValue)
            .mapTo(mapToValue)
        let operation = builder.build()

        XCTAssertEqual(operation.destination.variable, "destination")
        XCTAssertEqual(operation.destination.path, ["target"])
        XCTAssertEqual(operation.parameters.key.variable, "source")
        XCTAssertEqual(operation.parameters.key.path, ["nested"])
        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
        XCTAssertEqual(operation.parameters.mapTo?.value, mapToValue)
    }
}
