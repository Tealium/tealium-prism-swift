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
    let converter = BarrierSettings.converter

    func test_init_with_nil_scope() {
        let settings = BarrierSettings(barrierId: "test")
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertNil(settings.scope)
        XCTAssertEqual(settings.configuration, [:])
    }

    func test_init_with_all_scope() {
        let settings = BarrierSettings(barrierId: "test", scope: .all, configuration: [:])
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertEqual(settings.scope, .all)
        XCTAssertEqual(settings.configuration, [:])
    }

    func test_init_with_dispatchers_scope() {
        let settings = BarrierSettings(barrierId: "test", scope: .dispatchers(["a", "b"]))
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertEqual(settings.scope, .dispatchers(["a", "b"]))
    }

    func test_converter_with_all_scope_string() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scope: "all",
            BarrierSettings.Keys.configuration: [:]
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertEqual(settings.scope, .all)
    }

    func test_converter_with_dispatchers_scope_array() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scope: ["collect", "trace"],
            BarrierSettings.Keys.configuration: [:]
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertEqual(settings.scope, .dispatchers(["collect", "trace"]))
    }

    func test_converter_missing_barrier_id_returns_nil() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.scope: "all",
            BarrierSettings.Keys.configuration: [:]
        ])
        XCTAssertNil(converter.convert(dataItem: dataItem))
    }

    func test_converter_missing_scope_returns_settings_with_nil_scope() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.configuration: [:]
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertNil(settings.scope)
    }

    func test_converter_unknown_scope_string_returns_settings_with_nil_scope() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scope: "unknown_scope",
            BarrierSettings.Keys.configuration: [:]
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertNil(settings.scope)
    }

    func test_converter_nsnull_scope_returns_settings_with_nil_scope() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scope: NSNull(),
            BarrierSettings.Keys.configuration: [:]
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertNil(settings.scope)
    }

    func test_converter_empty_dispatchers_array_returns_settings() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scope: [DataInput](),
            BarrierSettings.Keys.configuration: [:]
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.barrierId, "test")
        XCTAssertEqual(settings.scope, .dispatchers([]))
    }

    func test_converter_missing_configuration_defaults_to_empty() {
        let dataItem = DataItem(value: [
            BarrierSettings.Keys.barrierId: "test",
            BarrierSettings.Keys.scope: "all"
        ])
        guard let settings = converter.convert(dataItem: dataItem) else {
            XCTFail("Expected settings"); return
        }
        XCTAssertEqual(settings.configuration, [:])
    }

    func test_toDataObject_with_all_scope() {
        let settings = BarrierSettings(barrierId: "test", scope: .all, configuration: ["configKey": "configValue"])
        let dataObject = settings.toDataObject()
        XCTAssertEqual(dataObject.get(key: BarrierSettings.Keys.barrierId), "test")
        XCTAssertEqual(dataObject.get(key: BarrierSettings.Keys.scope), "all")
        let configuration = dataObject.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: "configKey"), "configValue")
    }

    func test_toDataObject_with_nil_scope_omits_scope_key() {
        let settings = BarrierSettings(barrierId: "test", configuration: [:])
        let dataObject = settings.toDataObject()
        XCTAssertFalse(dataObject.keys.contains(BarrierSettings.Keys.scope))
    }

    func test_toDataObject_with_dispatchers_scope() {
        let settings = BarrierSettings(barrierId: "test", scope: .dispatchers(["collect"]), configuration: [:])
        let dataObject = settings.toDataObject()
        XCTAssertEqual(dataObject.getArray(key: BarrierSettings.Keys.scope), ["collect"])
        XCTAssertTrueOptional(dataObject.getDataDictionary(key: BarrierSettings.Keys.configuration)?.keys.isEmpty)
    }
}
