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
    let onActivity = ReplaySubject<ApplicationStatus>()
    lazy var config = createConfig(url: "someUrl")
    func createConfig(url: String?) -> TealiumConfig {
        TealiumConfig(account: "test",
                      profile: "test",
                      environment: "dev",
                      modules: [],
                      settingsFile: "localSettings.json",
                      settingsUrl: url)
    }
    func createCacher() throws -> ResourceCacher<DataObject> {
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        return ResourceCacher<DataObject>(dataStore: dataStore,
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
                                   logger: MockLogger())
    }
    func test_init_fills_current_settings_with_programmatic() throws {
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        let expected = SDKSettings(modules: [
            MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
        ])
        XCTAssertEqual(modulesSettings, expected)
    }

    func test_init_fills_current_settings_with_local_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        XCTAssertEqual(modulesSettings, SDKSettings(modules: [
            MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
            "localModule": ["configuration": ["localKey": "localValue"]], // Local file settings
        ]))
    }

    func test_init_fills_current_settings_with_local_cached_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        let cacher = try createCacher()
        try cacher.saveResource(["modules": ["cached": ["configuration": ["key": "value"]]]],
                                etag: nil)
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        XCTAssertEqual(modulesSettings, SDKSettings(modules: [
            MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
            "localModule": ["configuration": ["localKey": "localValue"]], // Local file settings
            "cached": ["configuration": ["key": "value"]] // Cached settings
        ]))
    }

    func test_init_without_url_fills_current_settings_with_local_and_programmatic() throws {
        config = createConfig(url: nil)
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        let cacher = try createCacher()
        try cacher.saveResource(["modules": ["cached": ["configuration": ["key": "value"]]]],
                                etag: nil)
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        XCTAssertEqual(modulesSettings, SDKSettings(modules: [
            MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
            "localModule": ["configuration": ["localKey": "localValue"]], // Local file settings
        ]))
    }

    func test_refresh_fills_merged_settings_with_local_remote_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        networkHelper.codableResult = .success(.successful(object: DataObject(dictionary: ["modules": ["remote": ["configuration": ["key": "value"]]]])))
        let manager = try getManager(url: "someUrl")
        manager.startRefreshing(onActivity: onActivity.asObservable())
        XCTAssertEqual(manager.settings.value, SDKSettings(modules: [
            MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
            "localModule": ["configuration": ["localKey": "localValue"]], // Local file settings
            "remote": ["configuration": ["key": "value"]] // Remote settings
        ]))
    }

    func test_failed_refresh_doesnt_fill_merged_settings_with_local_remote_and_programmatic() throws {
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        networkHelper.codableResult = .failure(.non200Status(404))
        let manager = try getManager(url: "someUrl")
        XCTAssertEqual(manager.settings.value, SDKSettings(modules: [
            MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
            "localModule": ["configuration": ["localKey": "localValue"]], // Local file settings
        ]))
    }

    func test_onNewSettingsMerged_doesnt_publish_merged_settings_without_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings should not be refreshed")
        settingsRefreshed.isInverted = true
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
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
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        networkHelper.codableResult = .success(.successful(object: DataObject(dictionary: ["modules": ["remote": ["configuration": ["key": "value"]]]])))
        let manager = try getManager(url: "someUrl")
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { settings in
                XCTAssertEqual(settings, ["modules": [
                    MockDispatcher.id: ["configuration": ["key": "value"]], // Programmatic settings
                    "localModule": ["configuration": ["localKey": "localValue"]], // Local file settings
                    "remote": ["configuration": ["key": "value"]] // Remote settings
                ]])
                settingsRefreshed.fulfill()
            }
        manager.startRefreshing(onActivity: onActivity.asObservable())
        waitForDefaultTimeout()
    }

    func test_onNewSettingsMerged_doesnt_publish_merged_settings_on_failed_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings should not be refreshed")
        settingsRefreshed.isInverted = true
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
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
        waitForDefaultTimeout()
    }

    func test_onNewRefreshInterval_publishes_new_interval_when_it_changes() throws {
        let refreshIntervalUpdated = expectation(description: "RefreshInterval is updated")
        refreshIntervalUpdated.expectedFulfillmentCount = 2
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        networkHelper.codableResult = .success(.successful(object: DataObject(dictionary: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(100)]])))
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
        manager.startRefreshing(onActivity: onActivity.asObservable())
        waitForDefaultTimeout()
    }

    func test_onNewRefreshInterval_doesnt_publish_new_interval_when_it_doesnt_change() throws {
        let refreshIntervalUpdated = expectation(description: "RefreshInterval is updated only once")
        config.bundle = Bundle(for: type(of: self))
        config.addModule(TealiumModules.customDispatcher(MockDispatcher.self, enforcedSettings: ["configuration": ["key": "value"]]))
        let manager = try getManager(url: "someUrl")
        let sdkSettings: DataObject = ["modules": [
            CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: CoreSettings.Defaults.refreshInterval]
        ]]
        networkHelper.codableResult = .success(.successful(object: sdkSettings))
        _ = manager.onNewRefreshInterval().subscribe { newInterval in
            XCTAssertEqual(newInterval, 900)
            refreshIntervalUpdated.fulfill()
        }
        manager.startRefreshing(onActivity: onActivity.asObservable())
        waitForDefaultTimeout()
    }

    func test_onShouldRequestRefresh_requests_refreshes_on_launch_and_foreground() {
        let refreshShouldBeRequested = expectation(description: "Refresh should be requested")
        refreshShouldBeRequested.expectedFulfillmentCount = 2
        let publisher = BasePublisher<ApplicationStatus>()
        _ = SettingsManager.onShouldRequestRefresh(publisher.asObservable())
            .subscribe {
                refreshShouldBeRequested.fulfill()
            }
        publisher.publish(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_onShouldRequestRefresh_doesnt_request_refreshes_on_background() {
        let refreshShouldNotBeRequestedOnBackground = expectation(description: "Refresh should be requested on launch but not on background")
        let publisher = BasePublisher<ApplicationStatus>()
        _ = SettingsManager.onShouldRequestRefresh(publisher.asObservable())
            .subscribe {
                refreshShouldNotBeRequestedOnBackground.fulfill()
            }
        publisher.publish(ApplicationStatus(type: .backgrounded))
        waitForDefaultTimeout()
    }

    func test_loadLocalSettings_returns_bundled_settings() {
        config.bundle = Bundle(for: type(of: self))
        let localSettings = SettingsManager.loadLocalSettings(config: config)
        XCTAssertNotNil(localSettings)
        XCTAssertEqual(localSettings, [
            "modules": [
                "localModule": ["configuration": ["localKey": "localValue"]]
            ]
        ])
    }

    func test_startRefreshing_only_starts_once() throws {
        let settingsUpdatedOnlyOnce = expectation(description: "Settings are updated only at init and on one refresh even if we start refreshing multiple times")
        settingsUpdatedOnlyOnce.expectedFulfillmentCount = 2
        let settings: DataObject = [
            "modules": [
                CoreSettings.id: [
                    "configuration": [CoreSettings.Keys.refreshIntervalSeconds: Double(0)]
                ]
            ]
        ]
        networkHelper.codableResult = .success(.successful(object: settings))
        let manager = try getManager(url: "someUrl")
        _ = manager.settings.subscribe { _ in
            settingsUpdatedOnlyOnce.fulfill()
        }
        func newSettings(count: Int) -> DataObject {
            SettingsManager.merge(orderedSettings: [settings, ["modules": ["remote": ["configuration": ["key": count]]]]])
        }
        for count in 0..<3 {
            networkHelper.codableResult = .success(.successful(object: newSettings(count: count)))
            manager.startRefreshing(onActivity: .Empty())
        }
        waitForDefaultTimeout()
    }
}
