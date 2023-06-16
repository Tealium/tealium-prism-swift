//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/22.
//

import Foundation

/**
 * A class that when instanciated reads the settings locally and then sets up a timer to refresh the settings via an API and inform who is registered on config updates.
 */
class SettingsProvider {
    
    init(config: TealiumConfig) {
        let trackingInterval = TealiumSignpostInterval(signposter: .settings,
                                                       name: "Settings Retrieval")
        trackingInterval.begin(config.configFile)
        guard let path = Bundle.main.path(forResource: config.configFile, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            trackingInterval.end("FAILED")
            return
        }
        trackingInterval.end("SUCCESS")
        _onConfigUpdate.publish(settings)
        tealiumQueue.asyncAfter(deadline: .now() + 2) {
            self._onConfigUpdate.publish(settings)
        }
    }
    var _onConfigUpdate = TealiumReplaySubject<[String:Any]>()
    lazy private(set) var onConfigUpdate: TealiumObservable<[String: Any]> = _onConfigUpdate.asObservable()
}

// TODO: Think about the event router

public class Tealium: TealiumProtocol {
    let settingsProvider: SettingsProvider
    var bag = TealiumDisposeBag()
    var context: TealiumContext?
    let modulesManager: ModulesManager
    required public init(_ config: TealiumConfig) {
        let startupInterval = TealiumSignpostInterval(signposter: .startup,
                                                      name: "Teal Init")
        startupInterval.begin()
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
        context = TealiumContext(self, modulesManager: modulesManager, config: config, coreSettings: CoreSettings(coreDictionary: [:]))
        tealiumQueue.async {
            self.settingsProvider.onConfigUpdate.subscribe { [weak self] settings in
                TealiumSignpostInterval(signposter: .settings,
                                        name: "Module Updates")
                .signpostedWork {
                    guard let self = self, let context = self.context else {
                        return
                    }
                    if let coreSettings = settings["core"] as? [String: Any] {
                        TealiumSignpostInterval(signposter: .settings,
                                                name: "Module Update")
                        .signpostedWork("core") {
                            context.coreSettings.updateSettings(coreSettings)
                        }
                    }
                    self.modulesManager.updateSettings(context: context, settings: settings)
                }
            }.toDisposeBag(self.bag)
            self.settingsProvider.onConfigUpdate.subscribeOnce { _ in
                startupInterval.end()
                self._onReady.publish()
            }
        }
    }
    
    public func track(_ trackable: TealiumDispatch) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking,
                                                       name: "TrackingCall")
        trackingInterval.begin(trackable.name ?? "unknown")
        tealiumQueue.async {
            var trackable = trackable
            let modules = self.modules
            modules.compactMap { $0 as? Collector }
                .forEach { collector in
                    TealiumSignpostInterval(signposter: .collecting,
                                            name: "Collecting")
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
                    TealiumSignpostInterval(signposter: .dispatching,
                                            name: "Dispatching")
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
