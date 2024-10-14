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
    private let appStatusListener = ApplicationStatusListener.shared

    // swiftlint:disable function_body_length
    init(_ config: TealiumConfig, modulesManager: ModulesManager) throws {
        var config = config
        Self.addMandatoryAndRemoveDuplicateModules(from: &config)
        let storeProvider = try Self.initModuleStoreProvider(config: config)
        let onLogLevel = ReplaySubject<LogLevel.Minimum>()
        let logger = TealiumLogger(logHandler: config.loggerType.getHandler(),
                                   onLogLevel: onLogLevel.asObservable(),
                                   forceLevel: config.coreSettings?
            .get(key: CoreSettings.Keys.minLogLevel, as: String.self)
            .flatMap { LogLevel.Minimum(from: $0) })
        let networkHelper = NetworkHelper(networkClient: HTTPClient.shared.newClient(withLogger: logger), logger: logger)
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        let settingsManager = try SettingsManager(config: config,
                                                  dataStore: dataStore,
                                                  networkHelper: networkHelper,
                                                  logger: logger,
                                                  onActivity: appStatusListener.onApplicationStatus)
        self.settingsManager = settingsManager
        let coreSettings = settingsManager.settings.map { $0.coreSettings }
        settingsManager.settings
            .map { $0.coreSettings.minLogLevel }
            .distinct()
            .subscribe { logLevel in
                onLogLevel.publish(logLevel)
            }.addTo(automaticDisposer)
        logger.debug(category: LogCategory.tealium, "Purging expired data from the database")
        storeProvider.modulesRepository.deleteExpired(expiry: .restart)
        let queueManager = QueueManager(processors: Self.queueProcessors(from: modulesManager.modules),
                                        queueRepository: SQLQueueRepository(dbProvider: storeProvider.databaseProvider,
                                                                            maxQueueSize: coreSettings.value.maxQueueSize,
                                                                            expiration: coreSettings.value.queueExpiration),
                                        coreSettings: coreSettings,
                                        logger: logger)
        Self.addQueueManager(queueManager, toConsentInConfig: &config)
        let barrierCoordinator = Self.barrierCoordinator(config: config, coreSettings: coreSettings)
        let transformerCoordinator = Self.transformerCoordinator(config: config, coreSettings: coreSettings, queue: modulesManager.queue)
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
                                      databaseProvider: storeProvider.databaseProvider,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      networkHelper: networkHelper,
                                      activityListener: appStatusListener,
                                      queue: modulesManager.queue)
        self.modulesManager = modulesManager
        self.instanceName = "\(config.account)-\(config.profile)"
        logger.info(category: LogCategory.tealium, "Instance \(self.instanceName) initialized.")
        self.handleSettingsUpdates()
    }
    // swiftlint:enable function_body_length

    func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        tracker.track(trackable, onTrackResult: onTrackResult)
    }

    private func handleSettingsUpdates() {
        self.settingsManager.settings.asObservable().subscribe { [weak self] settings in
            guard let self else { return }
            self.updateSettings(context: context, settings: settings)
        }.addTo(self.automaticDisposer)
    }

    private func updateSettings(context: TealiumContext, settings: SDKSettings) {
        TealiumSignpostInterval(signposter: .settings, name: "Module Updates")
            .signpostedWork {
                modulesManager.updateSettings(context: context, settings: settings)
            }
    }

    private static func barrierCoordinator(config: TealiumConfig, coreSettings: ObservableState<CoreSettings>) -> BarrierCoordinator {
        return BarrierCoordinator(registeredBarriers: config.barriers + [ConnectivityBarrier(onConnection: ConnectivityManager.shared.connectionAssumedAvailable)],
                                  onScopedBarriers: coreSettings.asObservable().map { $0.scopedBarriers })
    }

    private static func transformerCoordinator(config: TealiumConfig, coreSettings: ObservableState<CoreSettings>, queue: TealiumQueue) -> TransformerCoordinator {
        let scopedTransformations = coreSettings.map { $0.scopedTransformations }
        return TransformerCoordinator(registeredTransformers: config.transformers,
                                      scopedTransformations: scopedTransformations,
                                      queue: queue)
    }

    static func queueProcessors(from modules: ObservableState<[TealiumModule]>) -> Observable<[String]> {
        modules.filter { !$0.isEmpty }
            .map { modules in modules
                    .filter { $0 is Dispatcher || $0 is ConsentManager }
                    .map { $0.id }
            }.distinct()
    }

    deinit {
        let instanceName = self.instanceName
        context.logger?.info(category: LogCategory.tealium, "Instance \(instanceName) shutting down.")
    }
}
