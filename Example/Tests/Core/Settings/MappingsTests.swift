//
//  MappingsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MappingsTests: XCTestCase {

    func test_from_creates_key_and_destination() {
        let builder = Mappings.from("source", to: "destination")
        let operation = builder.build()

        XCTAssertEqual(operation.parameters.key?.variable, "source")
        XCTAssertEqual(operation.destination.variable, "destination")
        XCTAssertNil(operation.parameters.filter)
        XCTAssertNil(operation.parameters.mapTo)
    }

    func test_ifValueEquals_adds_filter_when_IfInputEquals_is_called() {
        let filterValue = "testValue"
        let builder = Mappings.from("source", to: "destination")
            .ifValueEquals(filterValue)
        let operation = builder.build()

        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
        XCTAssertNil(operation.parameters.mapTo)
    }

    func test_constant_creates_mapTo_and_destination() {
        let destinationKey = VariableAccessor(path: ["target"], variable: "destination")
        let mapToValue = "mappedValue"

        let builder = Mappings.constant(mapToValue, to: destinationKey)

        let operation = builder.build()

        XCTAssertEqual(operation.destination.variable, "destination")
        XCTAssertEqual(operation.destination.path, ["target"])
        XCTAssertEqual(operation.parameters.mapTo?.value, mapToValue)
        XCTAssertNil(operation.parameters.filter)
        XCTAssertNil(operation.parameters.key)
    }

    func test_ifValueIn_creates_complete_operation() {
        let sourceKey = VariableAccessor(path: ["nested"], variable: "source")
        let destinationKey = VariableAccessor(path: ["target"], variable: "destination")
        let filterValue = "originalValue"
        let mapToValue = "mappedValue"

        let builder = Mappings.constant(mapToValue, to: destinationKey)
            .ifValueIn(sourceKey, equals: filterValue)

        let operation = builder.build()

        XCTAssertEqual(operation.destination.variable, "destination")
        XCTAssertEqual(operation.destination.path, ["target"])
        XCTAssertEqual(operation.parameters.key?.variable, "source")
        XCTAssertEqual(operation.parameters.key?.path, ["nested"])
        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
        XCTAssertEqual(operation.parameters.mapTo?.value, mapToValue)
    }

    func test_keep_creates_same_key_and_destination() {
        let builder = Mappings.keep("source")
        let operation = builder.build()

        XCTAssertEqual(operation.parameters.key?.variable, "source")
        XCTAssertEqual(operation.destination.variable, "source")
    }
}
