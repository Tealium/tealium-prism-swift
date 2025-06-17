//
//  TealiumImpl.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumImpl {
    let settingsManager: SettingsManager
    let automaticDisposer = AutomaticDisposer()
    let context: TealiumContext
    let modulesManager = ModulesManager(queue: .worker)
    let tracker: TrackerImpl
    let visitorIdProvider: VisitorIdProvider
    let instanceName: String
    let loadRuleEngine: LoadRuleEngine
    private let appStatusListener = ApplicationStatusListener.shared

    // swiftlint:disable function_body_length
    init(_ config: TealiumConfig) throws {
        var config = config
        Self.addMandatoryAndRemoveDuplicateModules(from: &config)
        Self.addMandatoryAndRemoveDuplicateBarriers(from: &config)
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
                                                  logger: logger)
        settingsManager.startRefreshing(onActivity: appStatusListener.onApplicationStatus)
        self.settingsManager = settingsManager
        self.loadRuleEngine = LoadRuleEngine(sdkSettings: settingsManager.settings)
        let coreSettings = settingsManager.settings.mapState { $0.core }
        settingsManager.settings
            .mapState { $0.core.minLogLevel }
            .distinct()
            .subscribe(onLogLevel).addTo(automaticDisposer)
        logger.debug(category: LogCategory.tealium, "Purging expired data from the database")
        storeProvider.modulesRepository.deleteExpired(expiry: .restart)
        let queueManager = QueueManager(processors: Self.queueProcessors(from: modulesManager.modules, addingConsent: config.cmpAdapter != nil),
                                        queueRepository: SQLQueueRepository(dbProvider: storeProvider.databaseProvider,
                                                                            maxQueueSize: coreSettings.value.maxQueueSize,
                                                                            expiration: coreSettings.value.queueExpiration),
                                        coreSettings: coreSettings,
                                        logger: logger)
        let transformers = modulesManager.modules
            .mapState { $0.compactMap { $0 as? Transformer } }
        let transformerCoordinator = Self.transformerCoordinator(transformers: transformers,
                                                                 sdkSettings: settingsManager.settings,
                                                                 queue: modulesManager.queue)
        let barrierManager = BarrierManager(sdkBarrierSettings: settingsManager.settings.mapState { $0.barriers })
        let barrierCoordinator = BarrierCoordinator(onScopedBarriers: barrierManager.onScopedBarriers)
        let mappings = settingsManager.settings.mapState { $0.modules.compactMapValues { $0.mappings } }
        let mappingsEngine = MappingsEngine(mappings: mappings)

        let consentManager = ConsentIntegrationManager(queueManager: queueManager,
                                                       modules: modulesManager.modules,
                                                       consentSettings: settingsManager.settings.mapState { $0.consent },
                                                       cmpAdapter: config.cmpAdapter)

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
                                  logger: logger)
        self.tracker = tracker

        visitorIdProvider = VisitorIdProvider(config: config,
                                              visitorDataStore: try storeProvider.getModuleStore(name: "visitor"),
                                              logger: logger)
        let dataLayerStore = try storeProvider.getModuleStore(name: DataLayerModule.id)
        VisitorSwitcher.handleIdentitySwitches(visitorIdProvider: visitorIdProvider,
                                               onCoreSettings: coreSettings,
                                               dataLayerStore: dataLayerStore).addTo(automaticDisposer)

        self.context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: tracker,
                                      barrierRegistry: barrierManager,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: storeProvider.databaseProvider,
                                      moduleStoreProvider: storeProvider,
                                      logger: logger,
                                      networkHelper: networkHelper,
                                      activityListener: appStatusListener,
                                      queue: modulesManager.queue,
                                      visitorId: visitorIdProvider.visitorId)
        self.instanceName = "\(config.account)-\(config.profile)"
        barrierManager.initializeBarriers(factories: config.barriers, context: context)
        logger.info(category: LogCategory.tealium, "Instance \(self.instanceName) initialized.")
        self.handleSettingsUpdates()
    }
    // swiftlint:enable function_body_length

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

    static func mappings(from sdkSettings: ObservableState<SDKSettings>) -> ObservableState<[String: TransformationSettings]> {
        sdkSettings.mapState { settings in
            Dictionary(uniqueKeysWithValues: settings.modules.compactMap { dispatcherId, moduleSettings in
                guard let mappings = moduleSettings.mappings else { return nil }
                let configuration = JsonTransformationConfiguration(operationsType: .map,
                                                                    operations: mappings)
                return (dispatcherId, TransformationSettings(id: "\(dispatcherId)-mapping",
                                                             transformerId: Transformers.jsonTransformer,
                                                             scopes: [.dispatcher(dispatcherId)],
                                                             configuration: configuration.toDataObject()))
            })
        }
    }

    private static func transformerCoordinator(transformers: ObservableState<[Transformer]>,
                                               sdkSettings: ObservableState<SDKSettings>,
                                               queue: TealiumQueue) -> TransformerCoordinator {
        let transformations = sdkSettings.mapState { $0.transformations.map { $0.value } }
        return TransformerCoordinator(transformers: transformers,
                                      transformations: transformations,
                                      moduleMappings: mappings(from: sdkSettings),
                                      queue: queue)
    }

    static func queueProcessors(from modules: ObservableState<[TealiumModule]>, addingConsent: Bool) -> Observable<[String]> {
        modules.filter { !$0.isEmpty }
            .map { modules in modules
                    .filter { $0 is Dispatcher }
                    .map { $0.id } + (addingConsent ? [ConsentIntegrationManager.id] : [])
            }.distinct()
    }

    deinit {
        self.modulesManager.shutdown()
        let instanceName = self.instanceName
        context.logger?.info(category: LogCategory.tealium, "Instance \(instanceName) shutting down.")
    }
}
