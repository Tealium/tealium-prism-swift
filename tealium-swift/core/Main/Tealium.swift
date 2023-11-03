//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class that when instanciated reads the settings locally and then sets up a timer to refresh the settings via an API and inform who is registered on config updates.
 */
class SettingsProvider {

    init(config: TealiumConfig) {
        let trackingInterval = TealiumSignpostInterval(signposter: .settings, name: "Settings Retrieval")
            .begin(config.configFile)
        guard let path = Bundle.main.path(forResource: config.configFile, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            trackingInterval.end("FAILED")
            return
        }
        trackingInterval.end("SUCCESS")
        _onSettingsUpdate.publish(settings)
        tealiumQueue.asyncAfter(deadline: .now() + 2) {
            self._onSettingsUpdate.publish(settings)
        }
    }
    var _onSettingsUpdate = TealiumReplaySubject<[String: Any]>()
    lazy private(set) var onSettingsUpdate: TealiumObservable<[String: Any]> = _onSettingsUpdate.asObservable()
}

public class Tealium: TealiumProtocol {
    let settingsProvider: SettingsProvider
    let automaticDisposer = TealiumAutomaticDisposer()
    var context: TealiumContext?
    let modulesManager: ModulesManager
    @ToAnyObservable<TealiumReplaySubject<CoreSettings>>(TealiumReplaySubject<CoreSettings>())
    var onSettingsUpdate: TealiumObservable<CoreSettings>

    public init(_ config: TealiumConfig, completion: @escaping (Result<TealiumProtocol, Error>) -> Void) {
        let startupInterval = TealiumSignpostInterval(signposter: .startup, name: "Teal Init")
            .begin()
        var config = config
        config.modules += [
            DataLayerModule.self,
            TraceModule.self,
            DeepLinkModule.self,
            TealiumCollector.self
        ] // TODO: make sure there is no duplicate if they already added some of our internal modules
        self.timedEvents = TealiumTimedEvents()
        self.consent = TealiumConsent()
        self.settingsProvider = SettingsProvider(config: config)
        let modulesManager = ModulesManager()
        self.modulesManager = modulesManager
        trace = TealiumTrace(modulesManager: modulesManager)
        deepLink = TealiumDeepLink(modulesManager: modulesManager)
        dataLayer = TealiumDataLayer(modulesManager: modulesManager)
        asyncBootstrap(config: config) { result in
            startupInterval.end()
            completion(result)
        }
    }

    private func asyncBootstrap(config: TealiumConfig, completion: @escaping (Result<TealiumProtocol, Error>) -> Void) {
        // We will have a solution to this later - as of right now we dont have this information but are filling it so the DatabaseHelper can work
        let coreSettings = CoreSettings(coreDictionary: ["account": "test", "profile": "profile"])
        let logger = TealiumLogger(logger: config.loggerType.getHandler(),
                                   minLogLevel: coreSettings.minLogLevel,
                                   onCoreSettings: onSettingsUpdate)
        tealiumQueue.async {
            let completion = SelfDestructingCompletion<TealiumProtocol, Error> { result in
                completion(result)
                switch result {
                case .success:
                    logger.debug?.log(category: TealiumLibraryCategories.startup, message: "Tealium startup completed with success")
                    self._onReady.publish()
                case .failure(let error):
                    logger.error?.log(category: TealiumLibraryCategories.startup, message: "Tealium startup failed with \(error)")
                }
            }
            do {
                logger.trace?.log(category: TealiumLibraryCategories.startup, message: "Creating DB")
                let databaseProvider = try DatabaseProvider(settings: coreSettings)
                let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                        modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
                logger.trace?.log(category: TealiumLibraryCategories.startup, message: "Deleting restart and expired items from DB")
                storeProvider.modulesRepository.deleteExpired(expiry: .restart)
                self.context = TealiumContext(self,
                                              modulesManager: self.modulesManager,
                                              config: config,
                                              coreSettings: coreSettings,
                                              onSettingsUpdate: self.onSettingsUpdate,
                                              databaseProvider: databaseProvider,
                                              moduleStoreProvider: storeProvider,
                                              logger: logger)
                self.handleSettingsUpdates {
                    logger.trace?.log(category: TealiumLibraryCategories.settings, message: "Settings Updated")
                    completion.success(response: self)
                }
            } catch {
                completion.fail(error: error)
            }
        }
    }

    private func handleSettingsUpdates(completion: @escaping () -> Void) {
        self.settingsProvider.onSettingsUpdate.subscribe { [weak self] settings in
            guard let self = self, let context = self.context else {
                return
            }
            context.logger.trace?.log(category: TealiumLibraryCategories.settings, message: "Received new settings")
            TealiumSignpostInterval(signposter: .settings, name: "Module Updates")
                .signpostedWork {
                    if let coreSettings = settings["core"] as? [String: Any] {
                        TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                            .signpostedWork("core") {
                                self._onSettingsUpdate.publish(CoreSettings(coreDictionary: coreSettings))
                            }
                    }
                    self.modulesManager.updateSettings(context: context, settings: settings)
                }
            context.logger.trace?.log(category: TealiumLibraryCategories.settings, message: "Updated settings on all modules")
            completion()
        }.addTo(self.automaticDisposer)
    }

    public func track(_ trackable: TealiumDispatch) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        context?.logger.debug?.log(category: TealiumLibraryCategories.tracking, message: "Received new track")
        context?.logger.trace?.log(category: TealiumLibraryCategories.tracking, message: "Tracked Event \(trackable.eventData)")
        tealiumQueue.async {
            var trackable = trackable
            let modules = self.modules
            modules.compactMap { $0 as? Collector }
                .forEach { collector in
                    TealiumSignpostInterval(signposter: .collecting, name: "Collecting")
                        .signpostedWork("Collector: \(type(of: collector as TealiumModule).id)") {
                            trackable.enrich(data: collector.data) // collector.collect() maybe?
                        }
                }
            self.context?.logger.debug?.log(category: TealiumLibraryCategories.tracking, message: "Enriched Event")
            self.context?.logger.trace?.log(category: TealiumLibraryCategories.tracking, message: "Updated Data \(trackable.eventData)")

            // dispatch barries
            // queueing
            // batching
            // transform the data
            modules.compactMap { $0 as? Dispatcher }
                .forEach { dispatcher in
                    TealiumSignpostInterval(signposter: .dispatching, name: "Dispatching")
                        .signpostedWork("Dispatcher: \(type(of: dispatcher as TealiumModule).id)") {
                            dispatcher.dispatch([trackable])
                        }
                }
            self.context?.logger.debug?.log(category: TealiumLibraryCategories.tracking, message: "Dispatched Event")
            trackingInterval.end()
        }
    }

    var _onReady = TealiumReplaySubject<Void>()
    lazy private(set) var onReady: TealiumObservable<Void> = _onReady.asObservable().subscribeOn(tealiumQueue)

    public func onReady(_ completion: @escaping () -> Void) {
        onReady.subscribeOnce(completion)
    }

    public let trace: TealiumTrace

    public let deepLink: TealiumDeepLink

    public let dataLayer: TealiumDataLayer

    public let timedEvents: TealiumTimedEvents

    public let consent: TealiumConsent

    public var modules: [TealiumModule] {
        modulesManager.modules
    }

    public func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void) {
        modulesManager.getModule(completion: completion)
    }
}
