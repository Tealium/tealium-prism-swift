//
//  TealiumImplementation.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumImplementation {
    let settingsManager: SettingsManager
    let automaticDisposer = AutomaticDisposer()
    let context: TealiumContext
    let modulesManager: ModulesManager
    let tracker: TealiumTracker
    let instanceName: String
    private let onLogger = ReplaySubject<TealiumLoggerProvider>()

    init(_ config: TealiumConfig, modulesManager: ModulesManager) throws {
        var config = config
        Self.addMandatoryAndRemoveDuplicateModules(from: &config)
        let databaseProvider = try DatabaseProvider(config: config)
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        let onLoggerObservable = onLogger.asObservable()
        let networkHelper = NetworkHelper(networkClient: HTTPClient.shared.newClient(withLogger: onLoggerObservable), onLogger: onLoggerObservable)
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        // TODO: Add actual onActivity observable
        let settingsManager = try SettingsManager(config: config,
                                                  dataStore: dataStore,
                                                  networkHelper: networkHelper,
                                                  onLogger: onLoggerObservable,
                                                  onActivity: .Just(.launch(Date())))
        self.settingsManager = settingsManager
        let coreSettings = settingsManager.settings.map { $0.coreSettings }
        let logger = TealiumLogger(logger: config.loggerType.getHandler(),
                                   minLogLevel: coreSettings.map { $0.minLogLevel })
        onLogger.publish(logger)
        logger.debug?.log(category: LogCategory.tealium, message: "Purging expired data from the database")
        storeProvider.modulesRepository.deleteExpired(expiry: .restart)
        let queueManager = QueueManager(processors: Self.queueProcessors(from: modulesManager.modules),
                                        queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                            maxQueueSize: coreSettings.value.maxQueueSize,
                                                                            expiration: coreSettings.value.queueExpiration),
                                        coreSettings: coreSettings,
                                        logger: logger)
        Self.addQueueManager(queueManager, toConsentInConfig: &config)
        let barrierCoordinator = Self.barrierCoordinator(config: config, coreSettings: coreSettings)
        let transformerCoordinator = Self.transformerCoordinator(config: config, coreSettings: coreSettings)
        let dispatchManager = DispatchManager(modulesManager: modulesManager,
                                              queueManager: queueManager,
                                              barrierCoordinator: barrierCoordinator,
                                              transformerCoordinator: transformerCoordinator,
                                              logger: logger)
        let tracker = TealiumTracker(modulesManager: modulesManager, dispatchManager: dispatchManager, logger: logger)
        self.tracker = tracker
        self.context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: tracker,
                                      barrierRegistry: barrierCoordinator,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      networkHelper: networkHelper)
        self.modulesManager = modulesManager
        self.instanceName = "\(config.account)-\(config.profile)"
        logger.info?.log(category: LogCategory.tealium, message: "Instance \(self.instanceName) initialized.")
        self.handleSettingsUpdates()
    }

    public func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        tracker.track(trackable, onTrackResult: onTrackResult)
    }

    private func handleSettingsUpdates() {
        self.settingsManager.settings.asObservable().subscribe { [weak self] settings in
            guard let self else { return }
            self.updateSettings(context: context, settings: settings.modulesSettings)
        }.addTo(self.automaticDisposer)
    }

    private func updateSettings(context: TealiumContext, settings: [String: Any]) {
        TealiumSignpostInterval(signposter: .settings, name: "Module Updates")
            .signpostedWork {
                modulesManager.updateSettings(context: context, settings: settings)
            }
    }

    private static func barrierCoordinator(config: TealiumConfig, coreSettings: ObservableState<CoreSettings>) -> BarrierCoordinator {
        return BarrierCoordinator(registeredBarriers: config.barriers + [ConnectivityBarrier(onConnection: ConnectivityManager.shared.connectionAssumedAvailable)],
                                  onScopedBarriers: coreSettings.asObservable().map { $0.scopedBarriers })
    }

    private static func transformerCoordinator(config: TealiumConfig, coreSettings: ObservableState<CoreSettings>) -> TransformerCoordinator {
        let scopedTransformations = coreSettings.map { $0.scopedTransformations }
        return TransformerCoordinator(registeredTransformers: config.transformers,
                                      scopedTransformations: scopedTransformations,
                                      queue: tealiumQueue)
    }

    static func queueProcessors(from modules: ObservableState<[TealiumModule]>) -> Observable<[String]> {
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
