//
//  TealiumImplementation.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumImplementation {

    let settingsProvider: SettingsProvider
    let automaticDisposer = TealiumAutomaticDisposer()
    let context: TealiumContext
    let modulesManager: ModulesManager

    public init(_ config: TealiumConfig, modulesManager: ModulesManager) throws {
        var config = config
        config.modules += [
            DataLayerModule.self,
            TraceModule.self,
            DeepLinkModule.self,
            TealiumCollector.self
        ] // TODO: make sure there is no duplicate if they already added some of our internal modules
        let databaseProvider = try DatabaseProvider(config: config)
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let settingsProvider = SettingsProvider(config: config, storeProvider: storeProvider)
        let coreSettings = settingsProvider.coreSettings
        let logger = TealiumLogger(logger: config.loggerType.getHandler(),
                                   minLogLevel: coreSettings.value.minLogLevel,
                                   onCoreSettings: coreSettings.updates())
        logger.trace?.log(category: TealiumLibraryCategories.startup, message: "Deleting restart and expired items from DB")
        storeProvider.modulesRepository.deleteExpired(expiry: .restart)
        let networkHelper = NetworkHelper(networkClient: HTTPClient.shared.newClient(withLogger: logger),
                                          logger: logger)
        self.context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: TealiumTracker(modulesManager: modulesManager, logger: logger),
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      networkHelper: networkHelper)
        self.settingsProvider = settingsProvider
        self.modulesManager = modulesManager
        self.handleSettingsUpdates()
    }

    public func track(_ trackable: TealiumDispatch) {
        context.tracker.track(trackable)
    }

    private func handleSettingsUpdates() {
        self.settingsProvider.settings.asObservable().subscribe { [context = self.context] settings in
            Self.updateSettings(context: context, settings: settings)
        }.addTo(self.automaticDisposer)
    }

    private static func updateSettings(context: TealiumContext, settings: [String: Any]) {
        context.logger.trace?.log(category: TealiumLibraryCategories.settings, message: "Received new settings")
        TealiumSignpostInterval(signposter: .settings, name: "Module Updates")
            .signpostedWork {
                context.modulesManager?.updateSettings(context: context, settings: settings)
            }
        context.logger.trace?.log(category: TealiumLibraryCategories.settings, message: "Updated settings on all modules")
    }
}
