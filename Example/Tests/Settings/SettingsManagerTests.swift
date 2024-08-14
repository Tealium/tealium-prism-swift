//
//  SettingsManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class SettingsManagerTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let networkHelper = MockNetworkHelper()
    let onActivity = ReplaySubject<LifecycleActivity>()
    var config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [],
                               settingsFile: "localSettings.json",
                               settingsUrl: nil)
    func createCacher() throws -> ResourceCacher<SDKSettings> {
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        return ResourceCacher<SDKSettings>(dataStore: dataStore,
                                           fileName: "settings")
    }
    func getManager(url: String? = nil) throws -> SettingsManager {
        if let url {
            config.settingsUrl = url
        }
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        return try SettingsManager(config: config,
                                   dataStore: dataStore,
                                   networkHelper: networkHelper,
                                   onLogger: .Just(verboseLogger),
                                   onActivity: onActivity.asObservable())
    }
    func test_init_fills_current_settings_with_programmatic() throws {
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        let manager = try getManager()
        let modulesSettings = manager.settings.value.modulesSettings
        XCTAssertEqual(modulesSettings, [
            MockDispatcher.id: ["key": "value"], // Programmatic settings
        ])
    }

    func test_init_fills_current_settings_with_local_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        let manager = try getManager()
        let modulesSettings = manager.settings.value.modulesSettings
        XCTAssertEqual(modulesSettings, [
            MockDispatcher.id: ["key": "value"], // Programmatic settings
            "localModule": ["localKey": "localValue"], // Local file settings
        ])
    }

    func test_init_fills_current_settings_with_local_cached_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        let cacher = try createCacher()
        try cacher.saveResource(SDKSettings(modulesSettings: ["cached": ["key": "value"]]), etag: nil)
        let manager = try getManager()
        let modulesSettings = manager.settings.value.modulesSettings
        XCTAssertEqual(modulesSettings, [
            MockDispatcher.id: ["key": "value"], // Programmatic settings
            "localModule": ["localKey": "localValue"], // Local file settings
            "cached": ["key": "value"] // Cached settings
        ])
    }

    func test_refresh_fills_merged_settings_with_local_remote_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        networkHelper.codableResult = .success(.successful(object: SDKSettings(modulesSettings: ["remote": ["key": "value"]])))
        let manager = try getManager(url: "someUrl")
        onActivity.publish(.launch(Date()))
        XCTAssertEqual(manager.settings.value.modulesSettings, [
            MockDispatcher.id: ["key": "value"], // Programmatic settings
            "localModule": ["localKey": "localValue"], // Local file settings
            "remote": ["key": "value"] // Remote settings
        ])
    }

    func test_failed_refresh_doesnt_fill_merged_settings_with_local_remote_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        networkHelper.codableResult = .failure(.non200Status(404))
        let manager = try getManager(url: "someUrl")
        XCTAssertEqual(manager.settings.value.modulesSettings, [
            MockDispatcher.id: ["key": "value"], // Programmatic settings
            "localModule": ["localKey": "localValue"], // Local file settings
        ])
    }

    func test_onNewSettingsMerged_doesnt_publish_merged_settings_without_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings should not be refreshed")
        settingsRefreshed.isInverted = true
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        let manager = try getManager(url: "someUrl")
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { _ in
                settingsRefreshed.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_onNewSettingsMerged_publishes_merged_settings_on_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings are refreshed")
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        let manager = try getManager(url: "someUrl")
        networkHelper.codableResult = .success(.successful(object: SDKSettings(modulesSettings: ["remote": ["key": "value"]])))
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { settings in
                XCTAssertEqual(settings.modulesSettings, [
                    MockDispatcher.id: ["key": "value"], // Programmatic settings
                    "localModule": ["localKey": "localValue"], // Local file settings
                    "remote": ["key": "value"] // Remote settings
                ])
                settingsRefreshed.fulfill()
            }
        onActivity.publish(.launch(Date()))
        waitForDefaultTimeout()
    }

    func test_onNewSettingsMerged_doesnt_publish_merged_settings_on_failed_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings should not be refreshed")
        settingsRefreshed.isInverted = true
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        networkHelper.codableResult = .failure(.non200Status(404))
        let manager = try getManager(url: "someUrl")
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { _ in
                settingsRefreshed.fulfill()
            }
        onActivity.publish(.launch(Date()))
        waitForDefaultTimeout()
    }

    func test_onNewRefreshInterval_publishes_new_interval_when_it_changes() throws {
        let refreshIntervalUpdated = expectation(description: "RefreshInterval is updated")
        refreshIntervalUpdated.expectedFulfillmentCount = 2
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        networkHelper.codableResult = .success(.successful(object: SDKSettings(modulesSettings: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(100)]])))
        let manager = try getManager(url: "someUrl")
        var firstInterval = true
        _ = manager.onNewRefreshInterval().subscribe { newInterval in
            if firstInterval {
                firstInterval = false
                XCTAssertEqual(newInterval, 900)
            } else {
                XCTAssertEqual(newInterval, 100)
            }
            refreshIntervalUpdated.fulfill()
        }
        onActivity.publish(.launch(Date()))
        waitForDefaultTimeout()
    }

    func test_onNewRefreshInterval_doesnt_publish_new_interval_when_it_doesnt_change() throws {
        let refreshIntervalUpdated = expectation(description: "RefreshInterval is updated only once")
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["key": "value"]))
        let manager = try getManager(url: "someUrl")
        let sdkSettings = SDKSettings(modulesSettings: [
            CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: CoreSettings.Defaults.refreshIntervalSeconds]
        ])
        networkHelper.codableResult = .success(.successful(object: sdkSettings))
        _ = manager.onNewRefreshInterval().subscribe { newInterval in
            XCTAssertEqual(newInterval, 900)
            refreshIntervalUpdated.fulfill()
        }
        onActivity.publish(.launch(Date()))
        waitForDefaultTimeout()
    }

    func test_onShouldRequestRefresh_requests_refreshes_on_launch_and_foreground() {
        let refreshShouldBeRequested = expectation(description: "Refresh should be requested")
        refreshShouldBeRequested.expectedFulfillmentCount = 2
        let publisher = BasePublisher<LifecycleActivity>()
        _ = SettingsManager.onShouldRequestRefresh(publisher.asObservable())
            .subscribe {
                refreshShouldBeRequested.fulfill()
            }
        publisher.publish(.launch(Date()))
        publisher.publish(.foreground(Date()))
        waitForDefaultTimeout()
    }

    func test_onShouldRequestRefresh_doesnt_request_refreshes_on_background() {
        let refreshShouldNotBeRequested = expectation(description: "Refresh should not be requested")
        refreshShouldNotBeRequested.isInverted = true
        let publisher = BasePublisher<LifecycleActivity>()
        _ = SettingsManager.onShouldRequestRefresh(publisher.asObservable())
            .subscribe {
                refreshShouldNotBeRequested.fulfill()
            }
        publisher.publish(.background(Date()))
        waitForDefaultTimeout()
    }

    func test_loadLocalSettings_returns_bundled_settings() {
        config.bundle = Bundle(for: type(of: self))
        let localSettings = SettingsManager.loadLocalSettings(config: config)
        XCTAssertNotNil(localSettings)
        XCTAssertEqual(localSettings?.modulesSettings, ["localModule": ["localKey": "localValue"]])
    }
}
