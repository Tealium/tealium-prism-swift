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
        // We will have a solution to this later - as of right now we dont have this information but are filling it so the DatabaseHelper can work
        let coreSettings = CoreSettings(coreDictionary: ["account": "test", "profile": "profile"])
        tealiumQueue.async {
            let completion = SelfDestructingCompletion<TealiumProtocol, Error> { result in
                startupInterval.end()
                completion(result)
                if case .success = result {
                    self._onReady.publish()
                }
            }
            do {
                let databaseProvider = try DatabaseProvider(settings: coreSettings)
                let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                        modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
                storeProvider.modulesRepository.deleteExpired(expiry: .restart)
                self.context = TealiumContext(self,
                                              modulesManager: modulesManager,
                                              config: config,
                                              coreSettings: coreSettings,
                                              databaseProvider: databaseProvider,
                                              moduleStoreProvider: storeProvider)
                self.handleSettingsUpdates {
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
            TealiumSignpostInterval(signposter: .settings, name: "Module Updates")
                .signpostedWork {
                    if let coreSettings = settings["core"] as? [String: Any] {
                        TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                            .signpostedWork("core") {
                                context.coreSettings.updateSettings(coreSettings)
                            }
                    }
                    self.modulesManager.updateSettings(context: context, settings: settings)
                }
            completion()
        }.addTo(self.automaticDisposer)
    }

    public func track(_ trackable: TealiumDispatch) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
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
