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
    let instanceName: String

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
        logger.debug?.log(category: LogCategory.tealium, message: "Purging expired data from the database")
        storeProvider.modulesRepository.deleteExpired(expiry: .restart)
        let networkHelper = NetworkHelper(networkClient: HTTPClient.shared.newClient(withLogger: logger),
                                          logger: logger)
        let queueManager = QueueManager(processors: Self.queueProcessors(from: modulesManager.modules),
                                        queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                            maxQueueSize: coreSettings.value.maxQueueSize,
                                                                            expiration: coreSettings.value.queueExpiration),
                                        coreSettings: coreSettings,
                                        logger: logger)
        let barrierCoordinator = Self.barrierCoordinator(config: config, coreSettings: coreSettings)
        let transformerCoordinator = Self.transformerCoordinator(config: config, coreSettings: coreSettings)
        let dispatchManager = DispatchManager(modulesManager: modulesManager,
                                              queueManager: queueManager,
                                              barrierCoordinator: barrierCoordinator,
                                              transformerCoordinator: transformerCoordinator,
                                              logger: logger)
        let tracker = TealiumTracker(modulesManager: modulesManager,
                                     dispatchManager: dispatchManager,
                                     logger: logger)

        self.context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: tracker,
                                      queueManager: queueManager,
                                      barrierRegistry: barrierCoordinator,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      networkHelper: networkHelper)
        self.settingsProvider = settingsProvider
        self.modulesManager = modulesManager
        self.instanceName = "\(config.account)-\(config.profile)"
        logger.info?.log(category: LogCategory.tealium, message: "Instance \(self.instanceName) initialized.")
        self.handleSettingsUpdates()
    }

    public func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        context.tracker.track(trackable, onTrackResult: onTrackResult)
    }

    private func handleSettingsUpdates() {
        self.settingsProvider.settings.asObservable().subscribe { [context = self.context] settings in
            Self.updateSettings(context: context, settings: settings)
        }.addTo(self.automaticDisposer)
    }

    private static func updateSettings(context: TealiumContext, settings: [String: Any]) {
        context.logger?.debug?.log(category: LogCategory.settingsManager, message: "New SDK settings downloaded")
        context.logger?.trace?.log(category: LogCategory.settingsManager, message: "Downloaded settings: \(settings)")
        TealiumSignpostInterval(signposter: .settings, name: "Module Updates")
            .signpostedWork {
                context.modulesManager.updateSettings(context: context, settings: settings)
            }
    }

    private static func barrierCoordinator(config: TealiumConfig, coreSettings: TealiumStatefulObservable<CoreSettings>) -> BarrierCoordinator {
        return BarrierCoordinator(registeredBarriers: config.barriers + [ConnectivityBarrier(onConnection: ConnectivityManager.shared.connectionAssumedAvailable)],
                                  onScopedBarriers: coreSettings.asObservable().map { $0.scopedBarriers })
    }

    private static func transformerCoordinator(config: TealiumConfig, coreSettings: TealiumStatefulObservable<CoreSettings>) -> TransformerCoordinator {
        let scopedTransformations = coreSettings.map { $0.scopedTransformations }
        return TransformerCoordinator(registeredTransformers: config.transformers,
                                      scopedTransformations: scopedTransformations,
                                      queue: tealiumQueue)
    }

    static func queueProcessors(from modules: TealiumStatefulObservable<[TealiumModule]>) -> TealiumObservable<[String]> {
        modules.filter { !$0.isEmpty }
            .map { modules in modules
                    .filter { $0 is Dispatcher || $0 is ConsentManager }
                    .map { $0.id }
            }.distinct()
    }

    deinit {
        context.logger?.info?.log(category: LogCategory.tealium, message: "Instance \(instanceName) shutting down.")
    }
}
