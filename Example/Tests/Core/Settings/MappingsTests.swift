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
        let builder = Mappings()
        builder.mapFrom("source", to: "destination")
        let operation = builder.build()[0]

        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["source"])
        XCTAssertEqual(operation.destination.path, JSONPath["destination"])
        XCTAssertNil(operation.parameters.filter)
        XCTAssertNil(operation.parameters.mapTo)
    }

    func test_ifValueEquals_adds_filter_when_IfInputEquals_is_called() {
        let filterValue = "testValue"
        let builder = Mappings()
        builder.mapFrom("source", to: "destination")
            .ifValueEquals(filterValue)
        let operation = builder.build()[0]

        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
        XCTAssertNil(operation.parameters.mapTo)
    }

    func test_constant_creates_mapTo_and_destination() {
        let destinationKey = JSONPath["target"]["destination"]
        let mapToValue = "mappedValue"
        let builder = Mappings()
        builder.mapConstant(mapToValue, to: destinationKey)
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["target"]["destination"])
        XCTAssertEqual(operation.parameters.mapTo?.value, mapToValue)
        XCTAssertNil(operation.parameters.filter)
        XCTAssertNil(operation.parameters.reference)
    }

    func test_ifValueIn_creates_complete_operation() {
        let sourceKey = JSONPath["nested"]["source"]
        let destinationKey = JSONPath["target"]["destination"]
        let filterValue = "originalValue"
        let mapToValue = "mappedValue"
        let builder = Mappings()
        builder.mapConstant(mapToValue, to: destinationKey)
            .ifValueIn(sourceKey, equals: filterValue)
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["target"]["destination"])
        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["nested"]["source"])
        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
        XCTAssertEqual(operation.parameters.mapTo?.value, mapToValue)
    }

    func test_keep_creates_same_key_and_destination() {
        let builder = Mappings()
        builder.keep("source")
        let operation = builder.build()[0]

        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["source"])
        XCTAssertEqual(operation.destination.path, JSONPath["source"])
    }

    func test_mapCommand_creates_command_mapping() {
        let commandName = "track_purchase"
        let builder = Mappings()
        builder.mapCommand(commandName)
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["command_name"])
        XCTAssertEqual(operation.parameters.mapTo?.value, commandName)
        XCTAssertNil(operation.parameters.reference)
        XCTAssertNil(operation.parameters.filter)
    }

    func test_mapCommand_forAllEvents_adds_event_filter() {
        let commandName = "track_event"
        let builder = Mappings()
        builder.mapCommand(commandName)
            .forAllEvents()
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["command_name"])
        XCTAssertEqual(operation.parameters.mapTo?.value, commandName)
        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["tealium_event_type"])
        XCTAssertEqual(operation.parameters.filter?.value, "event")
    }

    func test_mapCommand_forAllViews_adds_view_filter() {
        let commandName = "track_view"
        let builder = Mappings()
        builder.mapCommand(commandName)
            .forAllViews()
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["command_name"])
        XCTAssertEqual(operation.parameters.mapTo?.value, commandName)
        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["tealium_event_type"])
        XCTAssertEqual(operation.parameters.filter?.value, "view")
    }

    func test_mapCommand_ifValueIn_with_key_adds_filter() {
        let commandName = "purchase_command"
        let filterKey = "event_name"
        let filterValue = "purchase"
        let builder = Mappings()
        builder.mapCommand(commandName)
            .ifValueIn(filterKey, equals: filterValue)
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["command_name"])
        XCTAssertEqual(operation.parameters.mapTo?.value, commandName)
        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["event_name"])
        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
    }

    func test_mapCommand_ifValueIn_with_path_adds_filter() {
        let commandName = "nested_command"
        let filterPath = JSONPath["user"]["type"]
        let filterValue = "premium"
        let builder = Mappings()
        builder.mapCommand(commandName)
            .ifValueIn(filterPath, equals: filterValue)
        let operation = builder.build()[0]

        XCTAssertEqual(operation.destination.path, JSONPath["command_name"])
        XCTAssertEqual(operation.parameters.mapTo?.value, commandName)
        XCTAssertEqual(operation.parameters.reference?.path, JSONPath["user"]["type"])
        XCTAssertEqual(operation.parameters.filter?.value, filterValue)
    }
}
