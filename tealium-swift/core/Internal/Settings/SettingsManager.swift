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
    @StateSubject var settings: ObservableState<SDKSettings>
    let resourceRefresher: ResourceRefresher<SDKSettings>?
    private let automaticDisposer = AutomaticDisposer()
    let localSettings: SDKSettings?
    let programmaticSettings: SDKSettings
    private let logger: LoggerProtocol

    init(config: TealiumConfig, dataStore: DataStore, networkHelper: NetworkHelperProtocol, logger: LoggerProtocol, onActivity: Observable<ApplicationStatus>) throws {
        self.logger = logger
        // MARK: Initialize Settings StateSubject
        var settingsToMerge = [SDKSettings]()
        localSettings = Self.loadLocalSettings(config: config)
        if let settings = localSettings {
            logger.trace(category: LogCategory.settingsManager, "Settings loaded from local file:\n\(settings)")
            settingsToMerge.append(settings)
        }
        let settingsCacher = ResourceCacher<SDKSettings>(dataStore: dataStore, fileName: "settings")
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
        _settings = StateSubject<SDKSettings>(Self.merge(orderedSettings: settingsToMerge))
        // MARK: Initialize ResourceRefresher
        if let urlString = config.settingsUrl {
            let refreshParameters = RefreshParameters(id: "settings",
                                                      url: try urlString.asUrl(),
                                                      refreshInterval: _settings.value.coreSettings.refreshInterval.seconds(),
                                                      errorCooldownBaseInterval: 20)
            let settingsRefresher = ResourceRefresher<SDKSettings>(networkHelper: networkHelper,
                                                                   resourceCacher: settingsCacher,
                                                                   parameters: refreshParameters,
                                                                   logger: logger)
            self.resourceRefresher = settingsRefresher
        } else {
            self.resourceRefresher = nil
        }
        settings.subscribe { [weak self] settings in
            self?.logger.debug(category: LogCategory.settingsManager,
                               "Applying settings:\n\(settings)")
        }.addTo(automaticDisposer)
        startRefreshing(onActivity: onActivity)
    }

    private func startRefreshing(onActivity: Observable<ApplicationStatus>) {
        guard let resourceRefresher else {
            return
        }
        onNewSettingsMerged(resourceRefresher: resourceRefresher)
            .subscribe { [weak self] mergedSettings in
                self?._settings.publish(mergedSettings)
            }.addTo(automaticDisposer)
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
        settings.map { $0.coreSettings.refreshInterval.seconds() }
            .distinct()
    }

    func onNewSettingsMerged(resourceRefresher: ResourceRefresher<SDKSettings>) -> Observable<SDKSettings> {
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
        onActivity.filter { status in
            switch status.type {
            case .initialized, .foregrounded:
                return true
            default:
                return false
            }
        }.map { _ in return () }
    }

    static func loadLocalSettings(config: TealiumConfig) -> SDKSettings? {
        guard let configFile = config.settingsFile,
              let path = TealiumFileManager.fullJSONPath(from: config.bundle, relativePath: configFile),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
              let settings = try? Tealium.jsonDecoder.decode(SDKSettings.self, from: jsonData)
        else {
            return nil
        }
        return settings
    }

    static func loadCachedSettings(resourceCacher: ResourceCacher<SDKSettings>) -> SDKSettings? {
        return resourceCacher.readResource()
    }

    static func merge(orderedSettings: [SDKSettings]) -> SDKSettings {
        guard orderedSettings.count > 1 else {
            return orderedSettings.first ?? SDKSettings(modulesSettings: [:])
        }
        let sdkSettingsResult = orderedSettings
            .reduce(into: [String: DataObject]()) { partialResult, higherPrioritySettings in
                partialResult.merge(higherPrioritySettings.modulesSettings) { oldModuleSettings, newModuleSettings in
                    oldModuleSettings + newModuleSettings
                }
            }
        return SDKSettings(modulesSettings: sdkSettingsResult)
    }
}
