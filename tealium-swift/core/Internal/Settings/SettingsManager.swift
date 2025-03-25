//
//  SettingsManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The manager for settings responsible for getting local, remote and programmatic settings and merging them to always provide the most updated verstion to all the modules.
 *
 * Settings are merged following the priority: `local < remote < programmatic`
 */
class SettingsManager {
    private var settingsData = BufferedSubject<DataObject>(bufferSize: 0)
    @StateSubject var settings: ObservableState<SDKSettings>
    let resourceRefresher: ResourceRefresher<DataObject>?
    private let automaticDisposer = AutomaticDisposer()
    let localSettings: DataObject?
    let programmaticSettings: DataObject
    private let logger: LoggerProtocol
    private var refreshing = false

    init(config: TealiumConfig, dataStore: DataStore, networkHelper: NetworkHelperProtocol, logger: LoggerProtocol) throws {
        self.logger = logger
        // MARK: Initialize Settings StateSubject
        var settingsToMerge = [DataObject]()
        localSettings = Self.loadLocalSettings(config: config)
        if let settings = localSettings {
            logger.trace(category: LogCategory.settingsManager, "Settings loaded from local file:\n\(settings)")
            settingsToMerge.append(settings)
        }
        let settingsCacher = ResourceCacher<DataObject>(dataStore: dataStore, fileName: "settings")
        if config.settingsUrl != nil {
            let cachedSettings = Self.loadCachedSettings(resourceCacher: settingsCacher)
            if let settings = cachedSettings {
                logger.trace(category: LogCategory.settingsManager, "Settings loaded from cache:\n\(settings)")
                settingsToMerge.append(settings)
            }
        }
        self.programmaticSettings = config.getEnforcedSDKSettings()
        logger.trace(category: LogCategory.settingsManager, "Settings loaded from config:\n\(self.programmaticSettings)")
        settingsToMerge.append(programmaticSettings)
        let mergedSettings = Self.merge(orderedSettings: settingsToMerge)
        logger.debug(category: LogCategory.settingsManager,
                     "Applying settings:\n\(mergedSettings)")
        _settings = StateSubject<SDKSettings>(SDKSettings(mergedSettings))
        // MARK: Initialize ResourceRefresher
        if let urlString = config.settingsUrl {
            let refreshParameters = RefreshParameters(id: "settings",
                                                      url: try urlString.asUrl(),
                                                      refreshInterval: _settings.value.core.refreshInterval.seconds(),
                                                      errorCooldownBaseInterval: 20)
            let settingsRefresher = ResourceRefresher<DataObject>(networkHelper: networkHelper,
                                                                  resourceCacher: settingsCacher,
                                                                  parameters: refreshParameters,
                                                                  logger: logger)
            self.resourceRefresher = settingsRefresher
        } else {
            self.resourceRefresher = nil
        }
        // MARK: Subscribe to Settings Data changes
        settingsData.asObservable()
            .map { [weak self] settings in
                self?.logger.debug(category: LogCategory.settingsManager,
                                   "Applying settings:\n\(settings)")
                return SDKSettings(settings)
            }
            .subscribe(_settings)
            .addTo(automaticDisposer)
    }

    func startRefreshing(onActivity: Observable<ApplicationStatus>) {
        guard let resourceRefresher, !refreshing else {
            return
        }
        refreshing = true
        onNewSettingsMerged(resourceRefresher: resourceRefresher)
            .subscribe(settingsData)
            .addTo(automaticDisposer)
        onNewRefreshInterval()
            .subscribe { interval in
                resourceRefresher.setRefreshInterval(interval)
            }.addTo(automaticDisposer)
        Self.onShouldRequestRefresh(onActivity)
            .subscribe { [weak self] in
                if resourceRefresher.shouldRefresh {
                    self?.logger.debug(category: LogCategory.settingsManager, "Refreshing remote settings")
                    resourceRefresher.requestRefresh()
                }
            }.addTo(automaticDisposer)
    }

    func onNewRefreshInterval() -> Observable<Double> {
        settings.asObservable()
            .map { $0.core.refreshInterval.seconds() }
            .distinct()
    }

    func onNewSettingsMerged(resourceRefresher: ResourceRefresher<DataObject>) -> Observable<DataObject> {
         resourceRefresher.onResourceLoaded
            .compactMap { [weak self] newSettingsLoaded in
                guard let self else { return nil }
                if self.logger.shouldLog(level: .debug) {
                    self.logger.debug(category: LogCategory.settingsManager, "New SDK settings downloaded")
                    self.logger.trace(category: LogCategory.settingsManager,
                                      "Downloaded settings:\n\(newSettingsLoaded)")
                }
                return Self.merge(orderedSettings: [self.localSettings, newSettingsLoaded, programmaticSettings].compactMap { $0 })
            }
    }

    static func onShouldRequestRefresh(_ onActivity: Observable<ApplicationStatus>) -> Observable<Void> {
        onActivity
            .filter { $0.type == .foregrounded }
            .map { _ in () }
            .startWith(())
    }

    static func loadLocalSettings(config: TealiumConfig) -> DataObject? {
        guard let configFile = config.settingsFile,
              let path = TealiumFileManager.fullJSONPath(from: config.bundle, relativePath: configFile),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
              let settings = try? Tealium.jsonDecoder.decode(DataObject.self, from: jsonData)
        else {
            return nil
        }
        return settings
    }

    static func loadCachedSettings(resourceCacher: ResourceCacher<DataObject>) -> DataObject? {
        return resourceCacher.readResource()
    }

    static func merge(orderedSettings: [DataObject]) -> DataObject {
        guard orderedSettings.count > 1 else {
            return orderedSettings.first ?? [:]
        }

        let mergedSettings = orderedSettings.reduce(into: DataObject()) { result, settings in
            result = result.deepMerge(with: settings, depth: 3)
        }

        return mergedSettings
    }
}
