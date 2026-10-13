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
    let moduleManager: ModuleManager
    let tracker: TrackerImpl
    let instanceName: String
    let loadRuleEngine: LoadRuleEngine
    let barrierCoordinator: BarrierCoordinator
    let sessionManager: SessionManager
    let queueManager: QueueManager
    private let databaseProvider: DatabaseProviderProtocol

    // swiftlint:disable:next function_body_length
    init(_ config: TealiumConfig, queue: TealiumQueue) throws {
        self.moduleManager = ModuleManager()
        var config = config
        Self.addMandatoryAndRemoveDuplicateModules(from: &config)
        Self.addMandatoryAndRemoveDuplicateBarriers(from: &config)
        let onLogLevel = ReplaySubject<LogLevel.Minimum>()
        let logger = TealiumLogger(logHandler: config.loggerType.getHandler(),
                                   onLogLevel: onLogLevel.asObservable(),
                                   forceLevel: config.coreSettings?
            .get(key: CoreSettings.Keys.minLogLevel, as: String.self)
            .flatMap { LogLevel.Minimum(from: $0) },
                                   queue: queue)
        let storeProvider = try Self.initModuleStoreProvider(config: config, logger: logger)
        self.databaseProvider = storeProvider.databaseProvider
        let client = config.networkClient.newClient(withLogger: logger)
        let networkHelper = NetworkHelper(networkClient: client)
        let sharedDataStore = try storeProvider.getSharedDataStore()
        let settingsManager = try SettingsManager(config: config,
                                                  dataStore: sharedDataStore,
                                                  networkHelper: networkHelper,
                                                  logger: logger)
        settingsManager.startRefreshing(onActivity: config.appStatusListener
            .onApplicationStatus
            .subscribeOn(queue)
            .observeOn(queue))
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
                                            dataStore: sharedDataStore,
                                            moduleRepository: storeProvider.modulesRepository,
                                            sessionTimeout: coreSettings.mapState { $0.sessionTimeout },
                                            logger: logger)
        self.sessionManager = sessionManager
        let queueManager = QueueManager(
            processors: Self.queueProcessors(from: moduleManager.observeModules { $0 as? Dispatcher },
                                             addingConsent: config.cmpAdapter != nil),
            queueRepository: SQLQueueRepository(dbProvider: storeProvider.databaseProvider,
                                                maxQueueSize: coreSettings.value.maxQueueSize,
                                                expiration: coreSettings.value.queueExpiration),
            coreSettings: coreSettings,
            logger: logger)
        self.queueManager = queueManager
        let transformerCoordinator = Self.transformerCoordinator(onTransformers: moduleManager.observeModules { $0 as? Transformer },
                                                                 sdkSettings: settingsManager.settings,
                                                                 queue: queue,
                                                                 logger: logger)
        let barrierManager = BarrierManager(sdkBarrierSettings: settingsManager.settings.mapState { $0.barriers })
        barrierCoordinator = BarrierCoordinator(onScopedBarriers: barrierManager.onScopedBarriers,
                                                onApplicationStatus: config.appStatusListener.onApplicationStatus,
                                                queueMetrics: queueManager,
                                                backgroundTaskStarter: config.backgroundTaskStarter,
                                                queue: queue)
        let mappings = settingsManager.settings.mapState { $0.modules.compactMapValues { $0.mappings } }
        let mappingsEngine = MappingsEngine(mappings: mappings)

        let consentManager = ConsentIntegrationManager(queueManager: queueManager,
                                                       modules: moduleManager.modules,
                                                       consentSettings: settingsManager.settings.mapState { $0.consent },
                                                       queue: queue,
                                                       cmpAdapter: config.cmpAdapter,
                                                       logger: logger)
        if consentManager == nil {
            ConsentIntegrationManager.logIgnoredConsentSettings(settingsManager.settings.mapState { $0.consent },
                                                                logger: logger)
                .addTo(automaticDisposer)
        }

        let dispatchManager = DispatchManager(loadRuleEngine: loadRuleEngine,
                                              onDispatchers: moduleManager.observeModules { $0 as? Dispatcher },
                                              consentManager: consentManager,
                                              queueManager: queueManager,
                                              barrierCoordinator: barrierCoordinator,
                                              transformerCoordinator: transformerCoordinator,
                                              mappingsEngine: mappingsEngine,
                                              logger: logger)
        let tracker = TrackerImpl(onCollectors: moduleManager.observeModules { $0 as? Collector },
                                  loadRuleEngine: loadRuleEngine,
                                  dispatchManager: dispatchManager,
                                  sessionManager: sessionManager,
                                  logger: logger)
        self.tracker = tracker

        let dataLayerStore = try storeProvider.getModuleStore(name: Modules.Types.dataLayer)
        let network = NetworkUtilities(networkHelper: networkHelper,
                                       networkClient: client,
                                       connectivityManager: ConnectivityManager.shared.emittingOn(queue: queue))
        self.context = TealiumContext(moduleManager: moduleManager,
                                      sessionRegistry: sessionManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: tracker,
                                      barrierRegistrar: barrierManager,
                                      transformerRegistrar: transformerCoordinator,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      network: network,
                                      applicationStatusListener: config.appStatusListener,
                                      queue: queue,
                                      queueMetrics: queueManager,
                                      dataLayer: dataLayerStore)
        // Checkpoint the write-ahead log whenever the app goes to the background.
        //
        // This is the hook that matters in practice: `shutdown()` is frequently never called
        // because iOS kills backgrounded apps outright, and SQLite.swift only closes the
        // connection in `deinit`. Without this the `-wal` grows and committed frames are never
        // folded back into the main database file — measured at 4 MB after a single 100-event
        // burst. Backgrounding is the last reliable moment to do it.
        //
        // Cheap and safe to repeat: `wal_checkpoint(RESTART)` has nothing to copy once every frame
        // is already in the database, and is a no-op entirely when the database is not in WAL mode.
        config.appStatusListener.onApplicationStatus
            .subscribeOn(queue)
            .observeOn(queue)
            .filter { $0.type == .backgrounded }
            .subscribe { [databaseProvider = storeProvider.databaseProvider, logger] _ in
                Self.checkpoint(databaseProvider, at: "backgrounding", logger: logger)
            }
            .addTo(automaticDisposer)

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
                moduleManager.updateSettings(context: context, settings: settings)
            }
    }

    /// Whether this instance has been shut down. Once `true`, all resources have been released.
    var isShutdown: Bool {
        automaticDisposer.isDisposed
    }

    /**
     * Releases all resources held by this instance: subscriptions, modules, the dispatch loop and the session manager.
     *
     * This method is idempotent — calling it more than once has no additional effect.
     */
    func shutdown() {
        guard !isShutdown else { return }
        automaticDisposer.dispose()
        // The consumers of the modules stop before the modules are cleared: an empty list is then a
        // teardown, and must not be mistaken for a configuration that leaves the queues unowned.
        tracker.dispatchManager.stopDispatchLoop()
        queueManager.shutdown()
        moduleManager.shutdown()
        sessionManager.shutdown()
        // Fold the write-ahead log back into the main database and reset it. Runs after the
        // dispatch loop has stopped so nothing is mid-write, and is a no-op when WAL is not in
        // use. Strictly durability-positive: committed frames move INTO the database file.
        Self.checkpoint(databaseProvider, at: "shutdown", logger: context.logger)
        let instanceName = self.instanceName // Avoid capturing self in @escaping autoclosure
        context.logger?.info(category: LogCategory.tealium, "Instance \(instanceName) shutting down.")
    }

    /// Checkpoints the write-ahead log and reports the result. A `busy` result means another
    /// connection still held the log, so it was not reset and the remaining frames wait for the next
    /// checkpoint: worth a line in a log, but nothing for either caller to act on.
    private static func checkpoint(_ databaseProvider: DatabaseProviderProtocol,
                                   at moment: String,
                                   logger: LoggerProtocol?) {
        let result: (busy: Bool, log: Int, checkpointed: Int)
        do {
            result = try databaseProvider.checkpoint()
        } catch {
            logger?.error(category: LogCategory.tealium,
                          "WAL checkpoint at \(moment) failed: \(error)")
            return
        }
        guard !result.busy else {
            logger?.warn(category: LogCategory.tealium,
                         "WAL checkpoint at \(moment) did not reset the log: another connection "
                         + "held it, \(result.checkpointed) of \(result.log) frames folded back")
            return
        }
        logger?.debug(category: LogCategory.tealium,
                      "WAL checkpoint at \(moment): \(result.checkpointed) of \(result.log) "
                      + "frames folded back, log reset")
    }

    deinit {
        // Defensive: the instance is normally shut down explicitly via the `TealiumInstanceManager`
        // before being deallocated. This guarantees teardown even if it wasn't.
        shutdown()
    }
}
