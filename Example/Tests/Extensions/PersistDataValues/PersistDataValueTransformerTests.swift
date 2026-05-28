//
//  PersistDataValueTransformerTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 19/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class PersistDataValueTransformerTests: ExtensionsBaseTests {
    let databaseProvider = MockDatabaseProvider()
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                 modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
    var dataLayer: (any DataStore)!
    var transformer: PersistDataValueTransformer!

    override func setUpWithError() throws {
        dataLayer = try storeProvider.getModuleStore(name: "testPDV")
        transformer = PersistDataValueTransformer(logger: nil,
                                                  dataLayer: dataLayer)
    }

    func test_id_returns_correct_value() {
        XCTAssertEqual(transformer.id, Modules.Types.persistDataValueTransformer)
    }

    func test_version_returns_correct_value() {
        XCTAssertEqual(transformer.version, TealiumConstants.libraryVersion)
    }

    func test_applyTransformation_with_invalid_configuration_completes_with_original_dispatch() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = TransformationSettings(
            id: "test",
            transformerId: Modules.Types.persistDataValueTransformer,
            scope: .afterCollectors,
            configuration: [:] // invalid - missing required fields
        )
        let expectation = expectation(description: "Completes with original dispatch")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload, dispatch.payload)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_reference_input_persists_value_to_data_layer() throws {
        let dispatch = Dispatch(name: "test", data: ["source_key": "source_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Value persisted to data layer")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { [weak self] _ in
            let stored: String? = self?.dataLayer.extract(path: JSONPath["dest_key"])
            XCTAssertEqual(stored, "source_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_reference_input_adds_value_to_dispatch_payload() throws {
        let dispatch = Dispatch(name: "test", data: ["source_key": "source_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Value added to dispatch payload")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            let value: String? = result?.payload.get(key: "dest_key")
            XCTAssertEqual(value, "source_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_constant_input_persists_value_to_data_layer() throws {
        let dispatch = Dispatch(name: "test")
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistConstant("constant_value", to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Constant value persisted to data layer")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { [weak self] _ in
            let stored: String? = self?.dataLayer.extract(path: JSONPath["dest_key"])
            XCTAssertEqual(stored, "constant_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_constant_input_adds_value_to_dispatch_payload() throws {
        let dispatch = Dispatch(name: "test")
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistConstant("constant_value", to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Constant value added to dispatch payload")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            let value: String? = result?.payload.get(key: "dest_key")
            XCTAssertEqual(value, "constant_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_missing_source_reference_completes_with_original_dispatch() throws {
        let dispatch = Dispatch(name: "test", data: ["existing_key": "existing_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("missing_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Completes with original dispatch for missing source")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { [weak self] result in
            XCTAssertEqual(result?.payload, dispatch.payload)
            XCTAssertNil(self?.dataLayer.extractDataItem(path: JSONPath["dest_key"]))
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_keepFirstValue_with_existing_value_skips_update() throws {
        // Pre-populate data layer
        try? dataLayer.buildPath(
            JSONPath["dest_key"],
            andSet: DataItem(value: "original_value"),
            expiry: .session
        )
        let dispatch = Dispatch(name: "test", data: ["source_key": "new_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.keepFirstValue))

        let expectation = expectation(description: "Existing value is not overwritten")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { [weak self] result in
            let stored: String? = self?.dataLayer.extract(path: JSONPath["dest_key"])
            XCTAssertEqual(stored, "original_value")
            XCTAssertEqual(result?.payload, dispatch.payload)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_keepFirstValue_with_no_existing_value_persists_value() throws {
        let dispatch = Dispatch(name: "test", data: ["source_key": "source_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.keepFirstValue))

        let expectation = expectation(description: "Value persisted when no existing value")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { [weak self] _ in
            let stored: String? = self?.dataLayer.extract(path: JSONPath["dest_key"])
            XCTAssertEqual(stored, "source_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_allowUpdate_with_existing_value_overwrites_value() throws {
        // Pre-populate data layer
        try? dataLayer.buildPath(
            JSONPath["dest_key"],
            andSet: DataItem(value: "original_value"),
            expiry: .session
        )
        let dispatch = Dispatch(name: "test", data: ["source_key": "new_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Existing value is overwritten")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { [weak self] _ in
            let stored: String? = self?.dataLayer.extract(path: JSONPath["dest_key"])
            XCTAssertEqual(stored, "new_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_when_buildPath_fails_completes_with_original_dispatch() throws {
        let mockDataLayer = FailingMockDataStore()
        let transformer = PersistDataValueTransformer(logger: nil, dataLayer: mockDataLayer)
        let dispatch = Dispatch(name: "test", data: ["source_key": "source_value"])
        let settings = try makeSettings(PersistDataValueSettingsBuilder(id: "test")
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .setExpiryPolicy(.session)
            .setUpdatePolicy(.allowUpdate))

        let expectation = expectation(description: "Completes with original dispatch on buildPath failure")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            guard let result else {
                XCTFail("Result should not be nil")
                return
            }
            XCTAssertEqual(result.payload, dispatch.payload)
            let value: String? = result.payload.get(key: "dest_key")
            XCTAssertNil(value, "Destination key should not be in payload when buildPath fails")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }
}
