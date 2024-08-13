//
//  SettingsManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

enum LifecycleActivity {
    case launch(_ date: Date)
    case foreground(_ date: Date)
    case background(_ date: Date)
}

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
    private let onLogger: Observable<TealiumLoggerProvider>

    init(config: TealiumConfig, dataStore: DataStore, networkHelper: NetworkHelperProtocol, onLogger: Observable<TealiumLoggerProvider>, onActivity: Observable<LifecycleActivity>) throws {
        self.onLogger = onLogger
        // MARK: Initialize Settings StateSubject
        localSettings = Self.loadLocalSettings(config: config)
        if let settings = localSettings {
            onLogger.subscribeOnce { logger in
                logger.trace?.log(category: LogCategory.settingsManager, message: "Settings loaded from local file:\n\(settings)")
            }.addTo(automaticDisposer)
        }
        let settingsCacher = ResourceCacher<SDKSettings>(dataStore: dataStore, fileName: "settings")
        let cachedSettings = Self.loadCachedSettings(resourceCacher: settingsCacher)
        if let settings = cachedSettings {
            onLogger.subscribeOnce { logger in
                logger.trace?.log(category: LogCategory.settingsManager, message: "Settings loaded from cache:\n\(settings)")
            }.addTo(automaticDisposer)
        }
        self.programmaticSettings = config.getEnforcedSDKSettings()
        onLogger.subscribeOnce { [programmaticSettings = self.programmaticSettings] logger in
            logger.trace?.log(category: LogCategory.settingsManager, message: "Settings loaded from config:\n\(programmaticSettings)")
        }.addTo(automaticDisposer)
        _settings = StateSubject<SDKSettings>(Self.merge(orderedSettings: [localSettings, cachedSettings, programmaticSettings].compactMap { $0 }))
        // MARK: Initialize ResourceRefresher
        if let urlString = config.settingsUrl {
            let refreshParameters = RefreshParameters(id: "settings",
                                                      url: try urlString.asUrl(),
                                                      refreshInterval: _settings.value.coreSettings.refreshInterval.seconds(),
                                                      errorCooldownBaseInterval: 20)
            let settingsRefresher = ResourceRefresher<SDKSettings>(networkHelper: networkHelper,
                                                                   resourceCacher: settingsCacher,
                                                                   parameters: refreshParameters)
            self.resourceRefresher = settingsRefresher
        } else {
            self.resourceRefresher = nil
        }
        settings.combineLatest(onLogger.first())
            .subscribe { settings, logger in
                logger.debug?.log(category: LogCategory.settingsManager,
                                  message: "Applying settings:\n\(settings)")
            }.addTo(automaticDisposer)
        startRefreshing(onActivity: onActivity)
    }

    private func startRefreshing(onActivity: Observable<LifecycleActivity>) {
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
                    self?.onLogger.subscribeOnce { logger in
                        logger.debug?.log(category: LogCategory.settingsManager, message: "Refreshing remote settings")
                    }
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
                self.onLogger.subscribeOnce { logger in
                    if let debug = logger.debug {
                        debug.log(category: LogCategory.settingsManager, message: "New SDK settings downloaded")
                        logger.trace?.log(category: LogCategory.settingsManager, message: "Downloaded settings:\n\(newSettingsLoaded)")
                    }
                }
                return Self.merge(orderedSettings: [self.localSettings, newSettingsLoaded, programmaticSettings].compactMap { $0 })
            }
    }

    static func onShouldRequestRefresh(_ onActivity: Observable<LifecycleActivity>) -> Observable<Void> {
        onActivity.filter { activity in
            switch activity {
            case .launch, .foreground:
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
              let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Any]]
        else {
            return nil
        }
        return SDKSettings(modulesSettings: settings)
    }

    static func loadCachedSettings(resourceCacher: ResourceCacher<SDKSettings>) -> SDKSettings? {
        return resourceCacher.readResource()
    }

    static func merge(orderedSettings: [SDKSettings]) -> SDKSettings {
        guard orderedSettings.count > 1 else {
            return orderedSettings.first ?? SDKSettings(modulesSettings: [:])
        }
        let sdkSettingsResult = orderedSettings
            .reduce(into: [String: [String: Any]]()) { partialResult, higherPrioritySettings in
                partialResult.merge(higherPrioritySettings.modulesSettings) { oldModuleSettings, newModuleSettings in
                    oldModuleSettings.merging(newModuleSettings) { _, newValue in newValue }
                }
            }
        return SDKSettings(modulesSettings: sdkSettingsResult)
    }
}
