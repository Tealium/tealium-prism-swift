//
//  DeviceDataModuleTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 30/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeviceDataModuleTests: DeviceDataModuleBaseTests {
    @StateSubject([:])
    var configuration: ObservableState<DataObject>
    lazy var deviceDataCollector = DeviceDataModule(deviceDataProvider: DeviceDataProvider(),
                                                    configuration: DeviceDataModuleConfiguration(configuration: configuration.value),
                                                    networkHelper: networkHelper,
                                                    storeProvider: context.moduleStoreProvider,
                                                    transformerRegistry: transformerRegistry,
                                                    queue: .main,
                                                    logger: context.logger)
    let modelsDataObject: DataObject = [
        "x86_64": [
            "device_model": "Simulator",
            "model_variant": "64-bit"
        ],
        "arm64": [
            "device_model": "Simulator",
            "model_variant": "64-bit"
        ]
    ]

    func test_the_module_id_is_correct() {
        _ = deviceDataCollector
        XCTAssertNotNil(context.moduleStoreProvider.modulesRepository.getModules()[DeviceDataModule.moduleType])
    }

    func test_collect_returns_constant_data_plus_track_time_data_without_memory_usage_by_default() {
        let collected = deviceDataCollector.collect(dispatchContext).asDictionary()
        XCTAssertEqual(collected.count, 13)
        XCTAssertNotNil(collected[DeviceDataKey.architecture])
        XCTAssertNotNil(collected[DeviceDataKey.cpuType])
        XCTAssertNotNil(collected[DeviceDataKey.deviceOrigin])
        XCTAssertNotNil(collected[DeviceDataKey.manufacturer])
        XCTAssertNotNil(collected[DeviceDataKey.osBuild])
        XCTAssertNotNil(collected[DeviceDataKey.osName])
        XCTAssertNotNil(collected[DeviceDataKey.osVersion])
        XCTAssertNotNil(collected[DeviceDataKey.platform])
        XCTAssertNotNil(collected[DeviceDataKey.resolution])
        XCTAssertNotNil(collected[DeviceDataKey.logicalResolution])
        XCTAssertNotNil(collected[DeviceDataKey.batteryPercent])
        XCTAssertNotNil(collected[DeviceDataKey.isCharging])
        XCTAssertNotNil(collected[DeviceDataKey.language])
    }

    func test_collect_returns_data_with_memory_usage_when_enabled() {
        _configuration.value = [
            DeviceDataModuleConfiguration.Keys.memoryReportingEnabled: true
        ]
        let collected = deviceDataCollector.collect(dispatchContext).asDictionary()
        XCTAssertEqual(collected.count, 20)
        XCTAssertNotNil(collected[DeviceDataKey.appMemoryUsage])
        XCTAssertNotNil(collected[DeviceDataKey.memoryActive])
        XCTAssertNotNil(collected[DeviceDataKey.memoryCompressed])
        XCTAssertNotNil(collected[DeviceDataKey.memoryFree])
        XCTAssertNotNil(collected[DeviceDataKey.memoryInactive])
        XCTAssertNotNil(collected[DeviceDataKey.memoryWired])
        XCTAssertNotNil(collected[DeviceDataKey.physicalMemory])
    }

    func test_applyTransformation_enriches_dispatch_with_model_info_and_orientation() {
        let transformationExpectation = expectation(description: "Transformation completed")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scopes: [.afterCollectors])
        networkHelper.codableResult = ObjectResult.success(.successful(object: (modelsDataObject)))
        deviceDataCollector.applyTransformation(transformation, to: dispatch, scope: .afterCollectors) { result in
            guard let result else {
                XCTFail("Transformation result should not be nil")
                return
            }
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceType))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceModel))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.device))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.modelVariant))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.orientation))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.extendedOrientation))
            #if os(iOS)
            XCTAssertEqual(result.payload.get(key: DeviceDataKey.deviceType), DeviceDataProvider.basicModel)
            XCTAssertNotEqual(result.payload.get(key: DeviceDataKey.deviceModel), DeviceDataProvider.basicModel)
            XCTAssertEqual(result.payload.get(key: DeviceDataKey.device, as: String.self), result.payload.get(key: DeviceDataKey.deviceModel, as: String.self))
            XCTAssertNotEqual(result.payload.get(key: DeviceDataKey.modelVariant), "")
            #endif
            transformationExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_saveModelInfo_saves_data_to_store() throws {
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        let modelInfo: DataObject = [
            DeviceDataKey.deviceType: "iPhone14,3",
            DeviceDataKey.deviceModel: "iPhone 13 Pro Max",
            DeviceDataKey.device: "iPhone 13 Pro Max",
            DeviceDataKey.modelVariant: "A2484"
        ]
        deviceDataCollector.saveModelInfo(modelInfo, dataStore: dataStore)
        let savedData = deviceDataCollector.readModelInfo(dataStore: dataStore)
        XCTAssertNotNil(savedData)
        XCTAssertEqual(savedData, modelInfo)
    }

    func test_readModelInfo_returns_nil_when_no_data_stored() throws {
        let newDataStore = try context.moduleStoreProvider.getModuleStore(name: "new")
        let modelInfo = deviceDataCollector.readModelInfo(dataStore: newDataStore)
        XCTAssertNil(modelInfo)
    }

    func test_convenience_init_creates_module_with_valid_configuration() {
        let moduleConfiguration: DataObject = [
            DeviceDataModuleConfiguration.Keys.memoryReportingEnabled: true,
            DeviceDataModuleConfiguration.Keys.deviceNamesUrl: "example.com/device-names.json"
        ]
        let module = DeviceDataModule(context: context,
                                      moduleConfiguration: moduleConfiguration)
        guard let module else {
            XCTFail("Module not initialized correctly")
            return
        }
        XCTAssertTrue(module.configuration.memoryReportingEnabled)
        XCTAssertEqual(module.configuration.deviceNamesUrl, "example.com/device-names.json")
    }

    func test_module_registers_transformation_on_init() {
        _ = deviceDataCollector
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformerId = transformerRegistry.getTransformations(for: dispatch, .afterCollectors)[0].transformerId
        XCTAssertEqual(transformerId, DeviceDataModule.moduleType)
    }

    #if os(iOS)
    func test_configuration_change_doesnt_trigger_resource_refresher_update_if_data_is_present() {
        networkHelper.codableResult = ObjectResult.success(.successful(object: (modelsDataObject)))
        let defaultRequestSent = expectation(description: "Request for default resource sent")
        networkHelper.requests.subscribe { request in
            guard case let .get(url, _) = request else {
                XCTFail("Unexpected request type: \(request)")
                return
            }
            guard (try? url.asUrl()) != nil else {
                XCTFail("Unexpected URL: \(url)")
                return
            }
            defaultRequestSent.fulfill()
        }.addTo(disposer)
        let newConfig: DataObject = [DeviceDataModuleConfiguration.Keys.deviceNamesUrl: "https://test.url"]
        deviceDataCollector.updateConfiguration(newConfig)
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNil(self.deviceDataCollector.updateResourceRefresher())
        }
    }
    #endif

    func test_instantiating_another_instance_with_same_configuration_gets_cached_models_data() {
        let modelsRequestSent = expectation(description: "Models info request sent")
        networkHelper.requests.subscribeOnce { request in
            guard case let .get(url, _) = request else {
                XCTFail("Unexpected request type: \(request)")
                return
            }
            guard let url = url as? URL else {
                XCTFail("Unexpected URL: \(url)")
                return
            }
            if url.absoluteString == DeviceDataModuleConfiguration.Defaults.deviceNamesUrl {
                modelsRequestSent.fulfill()
            }
        }
        _ = DeviceDataModule(deviceDataProvider: DeviceDataProvider(),
                             configuration: DeviceDataModuleConfiguration(configuration: [:]),
                             networkHelper: networkHelper,
                             storeProvider: context.moduleStoreProvider,
                             transformerRegistry: transformerRegistry,
                             queue: .main,
                             logger: context.logger)
        waitForLongTimeout()
    }

    func test_default_model_info_is_added_on_apply_transformation_when_no_info_downloaded() {
        let transformationExpectation = expectation(description: "Transformation completed")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info-and-orientation",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scopes: [.afterCollectors])
        _configuration.value = [
            DeviceDataModuleConfiguration.Keys.deviceNamesUrl: ""
        ]
        deviceDataCollector.applyTransformation(transformation, to: dispatch, scope: .afterCollectors) { result in
            guard let result else {
                XCTFail("Transformation result should not be nil")
                return
            }
            XCTAssertEqual(result.payload.get(key: DeviceDataKey.deviceType), DeviceDataProvider.basicModel)
            XCTAssertEqual(result.payload.get(key: DeviceDataKey.deviceModel), DeviceDataProvider.basicModel)
            XCTAssertEqual(result.payload.get(key: DeviceDataKey.device), DeviceDataProvider.basicModel)
            XCTAssertEqual(result.payload.get(key: DeviceDataKey.modelVariant), "")
            transformationExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }
}
