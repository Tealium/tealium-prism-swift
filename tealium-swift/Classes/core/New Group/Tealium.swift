//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/22.
//

import Foundation

let defaultConfig = """
{
    "core": {
        "account":"tealiummobile",
        "profile":"finance",
        "environment":"dev"
    },
    "collect": {
    }
}
"""

/**
 * A class that when instanciated reads the settings locally and then sets up a timer to refresh the settings via an API and inform who is registered on config updates.
 */
class SettingsProvider {
    
    init(config: TealiumConfig) {
        guard let path = (Bundle.main).path(forResource: config.configFile, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let settings = settings else {
            return
        }
        _onConfigUpdate.publish(settings)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self._onConfigUpdate.publish(settings)
        }
    }
    @ToAnyObservable(TealiumReplaySubject<[String:Any]>())
    var onConfigUpdate: TealiumObservable<[String: Any]>
}

// TODO: Think about the event router

public class Tealium: TealiumProtocol {
    let settingsProvider: SettingsProvider
    var bag = TealiumDisposeBag()
    var context: TealiumContext?
    let modulesManager: ModulesManager
    required public init(_ config: TealiumConfig) {
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
        settingsProvider.onConfigUpdate.subscribe { [weak self] settings in
            guard let self = self, let context = self.context else {
                return
            }
            if let coreSettings = settings["core"] as? [String: Any] {
                context.coreSettings.updateSettings(coreSettings)
            }
            self.modulesManager.updateSettings(context: context, settings: settings)
        }.toDisposeBag(bag)
        _onReady.publish() // TODO: this should happen after the modules manager has initialized everything probably
    }
    
    public func track(_ trackable: TealiumDispatch) {
        var trackable = trackable
        let modules = self.modules
        modules.compactMap { $0 as? Collector }
            .forEach { collector in
                trackable.enrich(data: collector.data) // collector.collect() maybe?
            }
        // dispatch barries
        // queueing
        // batching
        // transform the data
        modules.compactMap { $0 as? Dispatcher }
            .forEach { dispatcher in
                dispatcher.dispatch([trackable])
            }
    }
    
    @ToAnyObservable(TealiumReplaySubject<Void>())
    var onReady: TealiumObservable<Void>
    
    
    public func onReady(_ completion: @escaping () -> Void) {
        onReady.subscribeOnce(completion)
    }
    
    public let trace: TealiumTrace
    
    public let deepLink: TealiumDeepLink
    
    public var dataLayer: TealiumDataLayer
    
    public var timedEvents: TealiumTimedEvents
    
    public var consent: TealiumConsent
    
    public var modules: [TealiumModule] {
        modulesManager.modules
    }
    
    
    public func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void) {
        modulesManager.getModule(completion: completion)
    }
}
