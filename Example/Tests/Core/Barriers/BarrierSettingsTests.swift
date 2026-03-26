//
//  BarrierSettingsTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 09/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierSettingsTests: XCTestCase {

    func test_init_with_nil_scopes() {
        let settings = BarrierSettings(barrierId: "test", scopes: nil, configuration: [:])
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertNil(settings.scopes)
        XCTAssertEqual(settings.configuration, [:])
    }

    func test_init_with_scopes() {
        let scopes: [BarrierScope] = [.all, .dispatcher(id: "test")]
        let settings = BarrierSettings(barrierId: "test", scopes: scopes, configuration: [:])
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertEqual(settings.scopes, scopes)
    }

    func test_converter_with_nil_scopes() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.configuration: [:]
        ])
        let converter = BarrierSettings.converter
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.barrierId, "test")
        XCTAssertNil(settings?.scopes)
    }

    func test_converter_with_scopes() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scopes: ["all", "test-dispatcher"],
            BarrierSettings.Keys.configuration: [:]
        ])
        let converter = BarrierSettings.converter
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.barrierId, "test")
        XCTAssertEqual(settings?.scopes, [.all, .dispatcher(id: "test-dispatcher")])
    }

    func test_converter_with_invalid_data_returns_nil() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.scopes: ["all"],
            BarrierSettings.Keys.configuration: [:]
            // Missing barrierId
        ])
        let converter = BarrierSettings.converter
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertNil(settings)
    }

    func test_converter_with_empty_scopes_array() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scopes: [],
            BarrierSettings.Keys.configuration: [:]
        ])
        let converter = BarrierSettings.converter
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertEqual(settings?.barrierId, "test")
        XCTAssertEqual(settings?.scopes, [])
    }

    func test_toDataObject_with_nil_scope() {
        let settings = BarrierSettings(barrierId: "test", scopes: nil, configuration: [:])
        let expected: DataObject = ["barrier_id": "test", "scopes": NSNull(), "configuration": DataItem(value: [:])]
        XCTAssertEqual(settings.toDataObject(), expected)
    }

    func test_toDataObject_with_scopes() {
        let settings = BarrierSettings(barrierId: "test", scopes: [.all], configuration: [:])
        let expected: DataObject = ["barrier_id": "test", "scopes": ["all"], "configuration": DataItem(value: [:])]
        XCTAssertEqual(settings.toDataObject(), expected)
    }
}
