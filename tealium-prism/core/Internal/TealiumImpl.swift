//
//  TealiumImpl.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumImpl {
    let settingsManager: SettingsManager
    let automaticDisposer = AutomaticDisposer()
    let context: TealiumContext
    let modulesManager: ModulesManager
    let tracker: TrackerImpl
    let visitorIdProvider: VisitorIdProvider
    let instanceName: String
    let loadRuleEngine: LoadRuleEngine
    let barrierCoordinator: BarrierCoordinator
    let sessionManager: SessionManager

    // swiftlint:disable:next function_body_length
    init(_ config: TealiumConfig, queue: TealiumQueue) throws {
        self.modulesManager = ModulesManager(queue: queue)
        var config = config
        Self.addMandatoryAndRemoveDuplicateModules(from: &config)
        Self.addMandatoryAndRemoveDuplicateBarriers(from: &config)
        let storeProvider = try Self.initModuleStoreProvider(config: config)
        let onLogLevel = ReplaySubject<LogLevel.Minimum>()
        let logger = TealiumLogger(logHandler: config.loggerType.getHandler(),
                                   onLogLevel: onLogLevel.asObservable(),
                                   forceLevel: config.coreSettings?
            .get(key: CoreSettings.Keys.minLogLevel, as: String.self)
            .flatMap { LogLevel.Minimum(from: $0) },
                                   queue: queue)
        let client = config.networkClient.newClient(withLogger: logger)
        let networkHelper = NetworkHelper(networkClient: client, logger: logger)
        let dataStore = try storeProvider.getModuleStore(name: CoreSettings.id)
        let settingsManager = try SettingsManager(config: config,
                                                  dataStore: dataStore,
                                                  networkHelper: networkHelper,
                                                  logger: logger)
        settingsManager.startRefreshing(onActivity: config.appStatusListener
            .onApplicationStatus
            .observeOn(queue)
            .subscribeOn(queue))
        self.settingsManager = settingsManager
        self.loadRuleEngine = LoadRuleEngine(sdkSettings: settingsManager.settings, logger: logger)
        let coreSettings = settingsManager.settings.mapState { $0.core }
        settingsManager.settings
            .mapState { $0.core.minLogLevel }
            .distinct()
            .subscribe(onLogLevel).addTo(automaticDisposer)
        logger.debug(category: LogCategory.tealium, "Purging expired data from the database")
        storeProvider.modulesRepository.deleteExpired(expiry: .restart)
        let sessionManager = SessionManager(debouncer: Debouncer(queue: queue),
                                            dataStore: dataStore,
                                            moduleRepository: storeProvider.modulesRepository,
                                            sessionTimeout: coreSettings.mapState { $0.sessionTimeout },
                                            logger: logger)
        self.sessionManager = sessionManager
        let queueManager = QueueManager(
            processors: Self.queueProcessors(from: modulesManager.modules,
                                             addingConsent: config.cmpAdapter != nil),
            queueRepository: SQLQueueRepository(dbProvider: storeProvider.databaseProvider,
                                                maxQueueSize: coreSettings.value.maxQueueSize,
                                                expiration: coreSettings.value.queueExpiration),
            coreSettings: coreSettings,
            logger: logger)
        let transformers = modulesManager.modules
            .mapState { $0.compactMap { $0 as? Transformer } }
        let transformerCoordinator = Self.transformerCoordinator(transformers: transformers,
                                                                 sdkSettings: settingsManager.settings,
                                                                 queue: modulesManager.queue,
                                                                 logger: logger)
        let barrierManager = BarrierManager(sdkBarrierSettings: settingsManager.settings.mapState { $0.barriers })
        barrierCoordinator = BarrierCoordinator(onScopedBarriers: barrierManager.onScopedBarriers,
                                                onApplicationStatus: config.appStatusListener.onApplicationStatus,
                                                queueMetrics: queueManager,
                                                debouncer: Debouncer(queue: queue),
                                                queue: queue)
        let mappings = settingsManager.settings.mapState { $0.modules.compactMapValues { $0.mappings } }
        let mappingsEngine = MappingsEngine(mappings: mappings)

        let consentManager = ConsentIntegrationManager(queueManager: queueManager,
                                                       modules: modulesManager.modules,
                                                       consentSettings: settingsManager.settings.mapState { $0.consent },
                                                       queue: queue,
                                                       cmpAdapter: config.cmpAdapter,
                                                       logger: logger)

        let dispatchManager = DispatchManager(loadRuleEngine: loadRuleEngine,
                                              modulesManager: modulesManager,
                                              consentManager: consentManager,
                                              queueManager: queueManager,
                                              barrierCoordinator: barrierCoordinator,
                                              transformerCoordinator: transformerCoordinator,
                                              mappingsEngine: mappingsEngine,
                                              logger: logger)
        let tracker = TrackerImpl(modules: modulesManager.modules,
                                  loadRuleEngine: loadRuleEngine,
                                  dispatchManager: dispatchManager,
                                  sessionManager: sessionManager,
                                  logger: logger)
        self.tracker = tracker

        visitorIdProvider = VisitorIdProvider(config: config,
                                              visitorDataStore: try storeProvider.getModuleStore(name: "visitor"),
                                              logger: logger)
        let dataLayerStore = try storeProvider.getModuleStore(name: Modules.Types.dataLayer)
        VisitorSwitcher.handleIdentitySwitches(visitorIdProvider: visitorIdProvider,
                                               onCoreSettings: coreSettings,
                                               dataLayerStore: dataLayerStore).addTo(automaticDisposer)

        self.context = TealiumContext(modulesManager: modulesManager,
                                      sessionRegistry: sessionManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: tracker,
                                      barrierRegistry: barrierManager,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: storeProvider.databaseProvider,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      networkHelper: networkHelper,
                                      activityListener: config.appStatusListener,
                                      queue: modulesManager.queue,
                                      visitorId: visitorIdProvider.visitorId,
                                      queueMetrics: queueManager)
        self.instanceName = "\(config.account)-\(config.profile)"
        barrierManager.initializeBarriers(factories: config.barriers, context: context)
        logger.info(category: LogCategory.tealium, "Instance \(self.instanceName) initialized.")
        self.handleSettingsUpdates()
    }

    func track(_ trackable: Dispatch, onTrackResult: TrackResultCompletion?) {
        tracker.track(trackable, source: .application, onTrackResult: onTrackResult)
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

    deinit {
        self.modulesManager.shutdown()
        let instanceName = self.instanceName
        context.logger?.info(category: LogCategory.tealium, "Instance \(instanceName) shutting down.")
    }
}
