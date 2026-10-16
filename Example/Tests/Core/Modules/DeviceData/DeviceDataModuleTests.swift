//
//  DeviceDataModuleTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 30/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeviceDataModuleTests: DeviceDataModuleBaseTests {
    typealias Keys = DeviceDataModuleConfiguration.Keys
    @StateSubject([:])
    var configuration: ObservableState<DataObject>
    lazy var deviceDataCollector = DeviceDataModule(deviceDataProvider: DeviceDataProvider(),
                                                    configuration: DeviceDataModuleConfiguration(configuration: configuration.value),
                                                    networkHelper: networkHelper,
                                                    storeProvider: context.moduleStoreProvider,
                                                    transformerRegistrar: transformerCoordinator,
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
        XCTAssertEqual(collected.count, 9)
        XCTAssertNotNil(collected[DeviceDataKey.architecture])
        XCTAssertNotNil(collected[DeviceDataKey.cpuType])
        XCTAssertNotNil(collected[DeviceDataKey.deviceOrigin])
        XCTAssertNotNil(collected[DeviceDataKey.manufacturer])
        XCTAssertNotNil(collected[DeviceDataKey.osBuild])
        XCTAssertNotNil(collected[DeviceDataKey.osName])
        XCTAssertNotNil(collected[DeviceDataKey.osVersion])
        XCTAssertNotNil(collected[DeviceDataKey.platform])
        XCTAssertNotNil(collected[DeviceDataKey.language])
    }

    func test_collect_returns_data_with_memory_usage_when_enabled() {
        _configuration.value = [Keys.memoryReportingEnabled: true]
        let collected = deviceDataCollector.collect(dispatchContext).asDictionary()
        XCTAssertEqual(collected.count, 15)
        XCTAssertNotNil(collected[DeviceDataKey.memoryActive])
        XCTAssertNotNil(collected[DeviceDataKey.memoryCompressed])
        XCTAssertNotNil(collected[DeviceDataKey.memoryFree])
        XCTAssertNotNil(collected[DeviceDataKey.memoryInactive])
        XCTAssertNotNil(collected[DeviceDataKey.memoryWired])
        XCTAssertNotNil(collected[DeviceDataKey.physicalMemory])
    }

    func test_applyTransformation_enriches_dispatch_with_model_and_screen_and_battery_info() throws {
        let transformationExpectation = expectation(description: "Transformation completed")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scope: .afterCollectors)
        try networkHelper.encodeResult(modelsDataObject)
        deviceDataCollector.applyTransformation(transformation, to: dispatch, scope: .afterCollectors) { result in
            guard let result else {
                XCTFail("Transformation result should not be nil")
                return
            }
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceType))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceModel))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.device))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.modelVariant))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.isCharging))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.batteryPercent))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.orientation))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.extendedOrientation))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.resolution))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.logicalResolution))
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

    func test_applyTransformation_returns_disposed_disposable_once_completed() throws {
        let completion = expectation(description: "Completes exactly once")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scope: .afterCollectors)
        try networkHelper.encodeResult(modelsDataObject)
        let disposable = deviceDataCollector.applyTransformation(transformation, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNotNil(result)
            completion.fulfill()
        }
        waitForDefaultTimeout()
        XCTAssertTrue(disposable.isDisposed)
    }

    func test_applyTransformation_skips_adding_screen_info_when_screen_reporting_disabled() throws {
        _configuration.value = [Keys.screenReportingEnabled: false]
        let transformationExpectation = expectation(description: "Transformation completed")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scope: .afterCollectors)
        try networkHelper.encodeResult(modelsDataObject)
        deviceDataCollector.applyTransformation(transformation, to: dispatch, scope: .afterCollectors) { result in
            guard let result else {
                XCTFail("Transformation result should not be nil")
                return
            }
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceType))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceModel))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.device))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.modelVariant))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.isCharging))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.batteryPercent))
            XCTAssertNil(result.payload.getDataItem(key: DeviceDataKey.orientation))
            XCTAssertNil(result.payload.getDataItem(key: DeviceDataKey.extendedOrientation))
            XCTAssertNil(result.payload.getDataItem(key: DeviceDataKey.resolution))
            XCTAssertNil(result.payload.getDataItem(key: DeviceDataKey.logicalResolution))
            transformationExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_skips_adding_battery_info_when_battery_reporting_disabled() throws {
        _configuration.value = [Keys.batteryReportingEnabled: false]
        let transformationExpectation = expectation(description: "Transformation completed")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scope: .afterCollectors)
        try networkHelper.encodeResult(modelsDataObject)
        deviceDataCollector.applyTransformation(transformation, to: dispatch, scope: .afterCollectors) { result in
            guard let result else {
                XCTFail("Transformation result should not be nil")
                return
            }
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceType))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.deviceModel))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.device))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.modelVariant))
            XCTAssertNil(result.payload.getDataItem(key: DeviceDataKey.isCharging))
            XCTAssertNil(result.payload.getDataItem(key: DeviceDataKey.batteryPercent))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.orientation))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.extendedOrientation))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.resolution))
            XCTAssertNotNil(result.payload.getDataItem(key: DeviceDataKey.logicalResolution))
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
            Keys.memoryReportingEnabled: true,
            Keys.deviceNamesUrl: "example.com/device-names.json"
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
        let transformerId = transformerCoordinator.getTransformations(for: .afterCollectors)[0].transformerId
        XCTAssertEqual(transformerId, DeviceDataModule.moduleType)
    }

    #if os(iOS)
    func test_configuration_change_doesnt_trigger_resource_refresher_update_if_data_is_present() throws {
        try networkHelper.encodeResult(modelsDataObject)
        let defaultRequestSent = expectation(description: "Request for default resource sent")
        networkHelper.requests.subscribe { request in
            guard case let .get(url, _, _) = request else {
                XCTFail("Unexpected request type: \(request)")
                return
            }
            guard (try? url.asUrl()) != nil else {
                XCTFail("Unexpected URL: \(url)")
                return
            }
            defaultRequestSent.fulfill()
        }.addTo(disposer)
        let newConfig: DataObject = [Keys.deviceNamesUrl: "https://test.url"]
        deviceDataCollector.updateConfiguration(newConfig)
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNil(self.deviceDataCollector.updateResourceRefresher())
        }
    }
    #endif

    func test_instantiating_another_instance_with_same_configuration_gets_cached_models_data() {
        let modelsRequestSent = expectation(description: "Models info request sent")
        networkHelper.requests.subscribeOnce { request in
            guard case let .get(url, _, _) = request else {
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
                             transformerRegistrar: transformerCoordinator,
                             queue: .main,
                             logger: context.logger)
        waitForLongTimeout()
    }

    func test_default_model_info_is_added_on_apply_transformation_when_no_info_downloaded() {
        let transformationExpectation = expectation(description: "Transformation completed")
        let dispatch = Dispatch(name: "test_event", data: [:])
        let transformation = TransformationSettings(id: "model-info-and-orientation",
                                                    transformerId: DeviceDataModule.moduleType,
                                                    scope: .afterCollectors)
        _configuration.value = [Keys.deviceNamesUrl: ""]
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

// MARK: - Device-names file cache

extension DeviceDataModuleTests {
    func test_readModelInfo_returns_nil_when_store_only_holds_the_cached_device_names_file() throws {
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        try dataStore.edit()
            .put(key: "device-models", value: "{\"iPhone12,8\":{\"device_model\":\"iPhone SE\",\"model_variant\":\"\"}}", expiry: .forever)
            .put(key: "device-models_etag", value: "\"etag\"", expiry: .forever)
            .commit()
        XCTAssertNil(deviceDataCollector.readModelInfo(dataStore: dataStore))
    }

    func test_readModelInfo_returns_only_the_model_keys() throws {
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        let modelInfo: DataObject = [
            DeviceDataKey.deviceType: "iPhone14,3",
            DeviceDataKey.deviceModel: "iPhone 13 Pro Max",
            DeviceDataKey.device: "iPhone 13 Pro Max",
            DeviceDataKey.modelVariant: "A2484"
        ]
        try dataStore.edit()
            .putAll(dataObject: modelInfo, expiry: .forever)
            .put(key: "device-models", value: "{}", expiry: .forever)
            .commit()
        XCTAssertEqual(deviceDataCollector.readModelInfo(dataStore: dataStore), modelInfo)
    }

    private static let transformation = TransformationSettings(id: "model-info",
                                                               transformerId: DeviceDataModule.moduleType,
                                                               scope: .afterCollectors)

    private func makeLaunch(modelInfoTimeoutMs: Int = DeviceDataModule.defaultModelInfoTimeoutMs) -> DeviceDataModule {
        DeviceDataModule(deviceDataProvider: DeviceDataProvider(),
                         configuration: DeviceDataModuleConfiguration(configuration: [:]),
                         networkHelper: networkHelper,
                         storeProvider: context.moduleStoreProvider,
                         transformerRegistrar: transformerCoordinator,
                         queue: .main,
                         logger: context.logger,
                         modelInfoTimeoutMs: modelInfoTimeoutMs)
    }

    private func deviceFile(model: String) -> DataObject {
        [DeviceDataProvider.basicModel: ["device_model": model, "model_variant": "Variant"] as DataObject]
    }

    private var fileWithoutThisDevice: DataObject {
        ["iPhone12,8": ["device_model": "iPhone SE 2nd Generation", "model_variant": ""] as DataObject]
    }

    /// The URLs requested so far (the mock replays its latest requests) limited to 10.
    private var requestedUrls: [String] {
        var urls = [String]()
        networkHelper.requests.subscribe { request in
            if case let .get(url, _, _) = request, let url = url as? URL {
                urls.append(url.absoluteString)
            }
        }.dispose()
        return urls
    }

    /// Applies the transformation and waits for its completion, asserting the model in the payload and that no file keys leak in it.
    private func assertDeviceModel(_ expectedModel: String, of module: DeviceDataModule, description: String) {
        let completed = expectation(description: description)
        module.applyTransformation(Self.transformation, to: Dispatch(name: "test_event", data: [:]), scope: .afterCollectors) { result in
            XCTAssertNil(result?.payload.getDataItem(key: "device-models"))
            XCTAssertNil(result?.payload.getDataItem(key: "device-models_etag"))
            XCTAssertEqual(result?.payload.get(key: DeviceDataKey.deviceModel), expectedModel)
            completed.fulfill()
        }
        wait(for: [completed], timeout: Self.longTimeout)
    }

    /// Stores the file in the module store as the device-names file a previous launch downloaded.
    private func cacheDeviceNamesFile(_ file: DataObject) throws -> any DataStore {
        // swiftlint:disable:next optional_data_string_conversion
        let fileString = String(decoding: try Tealium.jsonEncoder.encode(file), as: UTF8.self)
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        try dataStore.edit()
            .put(key: "device-models", value: fileString, expiry: .forever)
            .put(key: "device-models_etag", value: "\"etag\"", expiry: .forever)
            .commit()
        return dataStore
    }

    /// Returns an expectation fulfilled when the store is updated with the given key.
    private func expectStoreUpdate(of key: String, in dataStore: any DataStore) -> XCTestExpectation {
        let updated = expectation(description: "Store updated with \(key)")
        updated.assertForOverFulfill = false
        dataStore.onDataUpdated.subscribe { data in
            if data.getDataItem(key: key) != nil {
                updated.fulfill()
            }
        }.addTo(disposer)
        return updated
    }

    func test_device_missing_from_device_names_file_gets_fallback_model_info_on_next_launch() throws {
        try networkHelper.encodeResult(fileWithoutThisDevice)
        assertDeviceModel(DeviceDataProvider.basicModel, of: makeLaunch(), description: "First launch completed")
        assertDeviceModel(DeviceDataProvider.basicModel, of: makeLaunch(), description: "Next launch completed")
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        XCTAssertNil(makeLaunch().readModelInfo(dataStore: dataStore), "Model info should never be saved for a missing device")
    }

    func test_first_install_refresh_error_gets_fallback_model_info() {
        networkHelper.setError(.urlError(URLError(.notConnectedToInternet)))
        assertDeviceModel(DeviceDataProvider.basicModel, of: makeLaunch(), description: "Launch completed")
    }

    func test_device_missing_from_cached_file_gets_fallback_model_info_when_file_is_not_modified() throws {
        try networkHelper.encodeResult(fileWithoutThisDevice)
        assertDeviceModel(DeviceDataProvider.basicModel, of: makeLaunch(), description: "First launch completed")
        // A 304 emits no resource, so the fallback must come from the cached file alone.
        networkHelper.setError(.non200Status(304, nil))
        let requestsBeforeNextLaunch = requestedUrls.count
        assertDeviceModel(DeviceDataProvider.basicModel, of: makeLaunch(), description: "Next launch completed")
        XCTAssertEqual(requestedUrls.count, requestsBeforeNextLaunch + 1)
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        XCTAssertNotNil(dataStore.getDataItem(key: "device-models"), "A 304 keeps the cached file")
        XCTAssertNil(makeLaunch().readModelInfo(dataStore: dataStore))
    }

    func test_first_install_download_slower_than_timeout_gets_fallback_then_model_info() throws {
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        networkHelper.delay = 300
        try networkHelper.encodeResult(deviceFile(model: "Test Device"))
        let modelSaved = expectStoreUpdate(of: DeviceDataKey.deviceModel, in: dataStore)
        let module = makeLaunch(modelInfoTimeoutMs: 10)

        assertDeviceModel(DeviceDataProvider.basicModel, of: module, description: "Timed out to the fallback")
        wait(for: [modelSaved], timeout: Self.longTimeout)
        assertDeviceModel("Test Device", of: module, description: "Download completed")
    }

    func test_first_install_download_faster_than_timeout_gets_model_info_without_fallback() throws {
        networkHelper.delay = 0 // Asynchronous, so the transformation has to wait for it
        try networkHelper.encodeResult(deviceFile(model: "Test Device"))
        let module = makeLaunch(modelInfoTimeoutMs: 5000)

        assertDeviceModel("Test Device", of: module, description: "Download completed before the timeout")
    }

    func test_cached_device_names_file_containing_device_cancels_the_fallback_timer() throws {
        _ = try cacheDeviceNamesFile(deviceFile(model: "Test Device"))
        let module = makeLaunch(modelInfoTimeoutMs: 10)

        // If the timer weren't cancelled, its nil would replace the model info well before this runs.
        let timerElapsed = expectation(description: "Fallback timeout elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            timerElapsed.fulfill()
        }
        wait(for: [timerElapsed], timeout: Self.longTimeout)

        assertDeviceModel("Test Device", of: module, description: "Model info still applied")
    }

    func test_cached_device_names_file_containing_device_gets_model_info_on_next_launch() throws {
        let file = deviceFile(model: "Test Device")
        let dataStore = try cacheDeviceNamesFile(file)
        try networkHelper.encodeResult(file)

        let nextLaunch = makeLaunch()
        assertDeviceModel("Test Device", of: nextLaunch, description: "Launch transformation completed")

        XCTAssertEqual(requestedUrls, [], "The cached file has the device, so no download is needed")
        let modelInfo = nextLaunch.readModelInfo(dataStore: dataStore)
        XCTAssertEqual(modelInfo?.count, 4)
        XCTAssertEqual(modelInfo?.get(key: DeviceDataKey.deviceType), DeviceDataProvider.basicModel)
        XCTAssertEqual(modelInfo?.get(key: DeviceDataKey.deviceModel), "Test Device")
        XCTAssertEqual(modelInfo?.get(key: DeviceDataKey.device), "Test Device")
        XCTAssertEqual(modelInfo?.get(key: DeviceDataKey.modelVariant), "Variant")
        XCTAssertNil(dataStore.getDataItem(key: "device-models"))
        XCTAssertNil(dataStore.getDataItem(key: "device-models_etag"))
    }

    func test_updated_device_names_file_fixes_missing_device_in_the_same_session() throws {
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        networkHelper.delay = 0 // Serve the files asynchronously, like a real network

        // Launch 1: the served file doesn't contain this device.
        try networkHelper.encodeResult(fileWithoutThisDevice)
        let firstCached = expectStoreUpdate(of: "device-models", in: dataStore)
        let firstLaunch = makeLaunch()
        wait(for: [firstCached], timeout: Self.longTimeout)
        assertDeviceModel(DeviceDataProvider.basicModel, of: firstLaunch, description: "First launch completed")

        // Launch 2: the download includes the device, so it recovers without waiting for another launch.
        try networkHelper.encodeResult(deviceFile(model: "Test Device"))
        let modelSaved = expectStoreUpdate(of: DeviceDataKey.deviceModel, in: dataStore)
        let secondLaunch = makeLaunch()
        assertDeviceModel(DeviceDataProvider.basicModel, of: secondLaunch, description: "Before download completed")
        wait(for: [modelSaved], timeout: Self.longTimeout)
        assertDeviceModel("Test Device", of: secondLaunch, description: "After download completed")
        XCTAssertEqual(secondLaunch.readModelInfo(dataStore: dataStore)?.count, 4)

        // Launch 3: the model info is already stored, nothing more to download.
        let requestsBeforeThirdLaunch = requestedUrls.count
        assertDeviceModel("Test Device", of: makeLaunch(), description: "Third launch completed")
        XCTAssertEqual(requestedUrls.count, requestsBeforeThirdLaunch)
    }

    func test_device_names_url_change_while_in_fallback_recovers_model_info() throws {
        try networkHelper.encodeResult(fileWithoutThisDevice)
        let module = makeLaunch()
        assertDeviceModel(DeviceDataProvider.basicModel, of: module, description: "Fallback applied")

        try networkHelper.encodeResult(deviceFile(model: "Test Device"))
        let newUrl = "https://test.url"
        module.updateConfiguration([Keys.deviceNamesUrl: newUrl])

        assertDeviceModel("Test Device", of: module, description: "Recovered after url change")
        XCTAssertEqual(requestedUrls.last, newUrl)
    }

    func test_shutdown_cancels_in_flight_download() throws {
        networkHelper.delay = 0 // Keep the download in flight until the main queue runs it
        try networkHelper.encodeResult(deviceFile(model: "Test Device"))
        let module = makeLaunch()
        module.shutdown()

        // The mock enqueued its response on the main queue before this, so it has run by the time this block does.
        let drained = expectation(description: "Pending download handled")
        DispatchQueue.main.async {
            drained.fulfill()
        }
        wait(for: [drained], timeout: Self.longTimeout)

        XCTAssertEqual(requestedUrls, [], "The download was cancelled before it ran")
        let dataStore = try context.moduleStoreProvider.getModuleStore(name: DeviceDataModule.moduleType)
        XCTAssertNil(module.readModelInfo(dataStore: dataStore))
        XCTAssertNil(dataStore.getDataItem(key: "device-models"))
    }
}
